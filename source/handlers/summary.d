module handlers.summary;
@safe:


import vibe.http.server: HTTPServerRequest, HTTPServerResponse;
import vibe.data.json;
import std.datetime: SysTime;
import core.sync.mutex: Mutex;
import std.container: DList;

enum ProcessorType {
    Default,
    Fallback
}

struct PaymentData {
    double amount;
    SysTime timestamp;
    ProcessorType processor;
}

class PaymentDataStore {
    private DList!PaymentData payments;
    private Mutex mutex;

    this() {
        payments = DList!PaymentData();
        mutex = new Mutex();
    }

    void addPayment(PaymentData data) {
        synchronized (mutex) {
            payments.insertBack(data);
        }
    }

    PaymentData[] query(SysTime from, SysTime to) {
        synchronized (mutex) {
            PaymentData[] results;
            foreach (payment; payments) {
                if (payment.timestamp >= from && payment.timestamp <= to) {
                    results ~= payment;
                }
            }
            return results;
        }
    }
}

class SummaryHandler {
    private PaymentDataStore dataStore;

    this(PaymentDataStore store) {
        this.dataStore = store;
    }

    void getSummary(HTTPServerRequest req, HTTPServerResponse res) {
        import std.datetime: SysTime;
        auto fromStr = req.query.get("from", "");
        auto toStr = req.query.get("to", "");

        SysTime fromTime;
        SysTime toTime;
        try {
            fromTime = fromStr.length ? SysTime.fromISOString(fromStr) : SysTime.min;
        } catch (Exception) {
            fromTime = SysTime.min;
        }
        try {
            toTime = toStr.length ? SysTime.fromISOString(toStr) : SysTime.max;
        } catch (Exception) {
            toTime = SysTime.max;
        }

        auto payments = dataStore.query(fromTime, toTime);

        long defaultRequests = 0;
        double defaultAmount = 0.0;
        long fallbackRequests = 0;
        double fallbackAmount = 0.0;

        foreach (p; payments) {
            if (p.processor == ProcessorType.Default) {
                defaultRequests++;
                defaultAmount += p.amount;
            } else {
                fallbackRequests++;
                fallbackAmount += p.amount;
            }
        }

        Json summary = Json.emptyObject;
        summary["default"] = Json.emptyObject;
        summary["default"]["totalRequests"] = defaultRequests;
        summary["default"]["totalAmount"] = defaultAmount;
        summary["fallback"] = Json.emptyObject;
        summary["fallback"]["totalRequests"] = fallbackRequests;
        summary["fallback"]["totalAmount"] = fallbackAmount;

        res.writeJsonBody(summary);
    }
}