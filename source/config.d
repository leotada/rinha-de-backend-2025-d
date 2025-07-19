module config;
@safe:

import utils.env: getEnv;

struct AppConfig {
    string defaultUrl;
    string fallbackUrl;
}

AppConfig loadConfig() {
    return AppConfig(
        getEnv("PAYMENT_PROCESSOR_URL_DEFAULT", "http://payment-processor-default:8080"),
        getEnv("PAYMENT_PROCESSOR_URL_FALLBACK", "http://payment-processor-fallback:8080")
    );
}
