module services.health_monitor;
@safe:

import vibe.http.client: HTTPClientRequest, HTTPClientResponse, requestHTTP;
import vibe.http.common: HTTPMethod;
import vibe.data.json: parseJson;
import vibe.data.json;
import vibe.core.core: runTask, sleep;
import core.time: seconds;
import core.sync.mutex: Mutex;

struct ProcessorHealth {
    bool failing;
    int minResponseTime;
}

class HealthMonitor {
    private string defaultUrl;
    private string fallbackUrl;
    private ProcessorHealth defaultHealth;
    private ProcessorHealth fallbackHealth;
    private Mutex mutex;

    this(string defaultUrl, string fallbackUrl) {
        this.defaultUrl = defaultUrl;
        this.fallbackUrl = fallbackUrl;
        this.defaultHealth = ProcessorHealth(false, 0);
        this.fallbackHealth = ProcessorHealth(false, 0);
        this.mutex = new Mutex();
        runTask(&monitorLoop);
    }

    private void monitorLoop() nothrow {
        while (true) {
            try {
                checkHealth(defaultUrl, true);
                checkHealth(fallbackUrl, false);
                sleep(5.seconds); // 5 segundos entre checks
            } catch (Exception) {
                // Ignora erros no loop de monitoramento
            }
        }
    }

    private void checkHealth(string url, bool isDefault) {
        try {
            requestHTTP(url ~ "/payments/service-health",
                (scope HTTPClientRequest req) nothrow {
                    req.method = HTTPMethod.GET;
                },
                (scope HTTPClientResponse res) {
                    import vibe.stream.operations: readAllUTF8;
                    auto responseBody = res.bodyReader.readAllUTF8();
                    auto json = parseJson(responseBody);
                    auto health = ProcessorHealth(
                        json["failing"].get!bool,
                        json["minResponseTime"].get!int
                    );
                    synchronized (mutex) {
                        if (isDefault)
                            defaultHealth = health;
                        else
                            fallbackHealth = health;
                    }
                }
            );
        } catch (Exception) {
            synchronized (mutex) {
                if (isDefault)
                    defaultHealth = ProcessorHealth(true, int.max);
                else
                    fallbackHealth = ProcessorHealth(true, int.max);
            }
        }
    }

    ProcessorHealth getDefaultHealth() {
        synchronized (mutex) return defaultHealth;
    }
    ProcessorHealth getFallbackHealth() {
        synchronized (mutex) return fallbackHealth;
    }

    string getBestProcessorUrl() {
        synchronized (mutex) {
            bool defaultIsViable = !defaultHealth.failing;
            bool fallbackIsViable = !fallbackHealth.failing;

            if (defaultIsViable && fallbackIsViable) {
                // Ambos estão saudáveis, escolher o com menor tempo de resposta
                if (defaultHealth.minResponseTime <= fallbackHealth.minResponseTime) {
                    return defaultUrl;
                } else {
                    return fallbackUrl;
                }
            } else if (defaultIsViable) {
                return defaultUrl;
            } else if (fallbackIsViable) {
                return fallbackUrl;
            } else {
                // Ambos estão falhando, retorna default como última opção
                return defaultUrl;
            }
        }
    }
}
