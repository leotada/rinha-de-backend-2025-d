module services.payment_processor;
@safe:

import vibe.http.client: requestHTTP;
import vibe.core.log: logError, logInfo;
import vibe.data.json;
import vibe.http.common: HTTPMethod;
import vibe.core.core: runTask, sleep;
import core.time: seconds;
import core.sync.mutex: Mutex;
import std.container: DList;

struct PaymentRequest {
    string correlationId;
    double amount;
    string to;
    string from;
}

struct FailedRequest {
    PaymentRequest request;
    int retryCount;
}

class PaymentProcessor {
    private string defaultProcessorUrl;
    private string fallbackProcessorUrl;
    private DList!(FailedRequest) retryQueue;
    private Mutex queueMutex;
    private const int maxRetries = 5;
    private bool isRunning = true;

    this(string defaultUrl, string fallbackUrl) {
        this.defaultProcessorUrl = defaultUrl;
        this.fallbackProcessorUrl = fallbackUrl;
        this.retryQueue = DList!(FailedRequest)();
        this.queueMutex = new Mutex();
        // Start retry worker as a vibe.d task instead of thread
        runTask(() nothrow {
            try {
                this.retryWorker();
            } catch (Exception e) {
                logError("Error in retry worker: %s", e.msg);
            }
        });
    }

    ~this() {
        isRunning = false;
    }

    void sendPaymentRequest(PaymentRequest request) {
        // Use vibe.d tasks instead of threads for better @safe compatibility
        runTask(() nothrow {
            try {
                trySendPayment(request, defaultProcessorUrl, 0);
            } catch (Exception e) {
                logError("Error sending payment request: %s", e.msg);
            }
        });
    }

    private void trySendPayment(PaymentRequest request, string url, int attempt) {
        try {
            auto payload = buildPayload(request);
            requestHTTP(url ~ "/payments", (req) {
                req.method = HTTPMethod.POST;
                req.writeJsonBody(payload);
            }, (res) {
                if (res.statusCode < 200 || res.statusCode >= 300) {
                    handleFailedRequest(request, attempt);
                }
            });
        } catch (Exception e) {
            logError("Error sending request: %s", e.msg);
            handleFailedRequest(request, attempt);
        }
    }

    private void handleFailedRequest(PaymentRequest request, int attempt) {
        if (attempt < maxRetries) {
            auto nextUrl = (attempt % 2 == 0) ? fallbackProcessorUrl : defaultProcessorUrl;
            runTask(() nothrow {
                try {
                    trySendPayment(request, nextUrl, attempt + 1);
                } catch (Exception e) {
                    logError("Error in retry attempt: %s", e.msg);
                }
            });
        } else {
            logInfo("Max retries reached for request, adding to persistent queue: %s", request.correlationId);
            synchronized (queueMutex) {
                retryQueue.insertBack(FailedRequest(request, attempt));
            }
        }
    }

    private void retryWorker() {
        while (isRunning) {
            FailedRequest failedRequest;
            bool hasItem = false;

            synchronized (queueMutex) {
                if (!retryQueue.empty) {
                    failedRequest = retryQueue.front;
                    retryQueue.removeFront();
                    hasItem = true;
                }
            }

            if (hasItem) {
                trySendPayment(failedRequest.request, defaultProcessorUrl, failedRequest.retryCount);
            } else {
                sleep(1.seconds);
            }
        }
    }

    private Json buildPayload(PaymentRequest request) {
        Json payload = Json.emptyObject;
        payload["correlationId"] = request.correlationId;
        payload["amount"] = request.amount;
        payload["to"] = request.to;
        payload["from"] = request.from;
        return payload;
    }
}