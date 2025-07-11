module app;
@safe:

import vibe.vibe;
import vibe.http.server: HTTPServerSettings, listenHTTP;
import vibe.http.router: URLRouter;
import vibe.core.log: logInfo;
import std.stdio: writeln;
import services.payment_processor: PaymentProcessor;
import handlers.payments: PaymentHandler;
import handlers.summary: SummaryHandler;
import handlers.health: healthHandler;

void main()
{
    // Initialize the application
    writeln("Starting Rinha de Backend 2025 D application...");

    auto settings = new HTTPServerSettings;
    settings.port = 9999;
    settings.bindAddresses = ["0.0.0.0"];

    auto router = new URLRouter;

    // Initialize data store
    import handlers.summary: PaymentDataStore;
    auto dataStore = new PaymentDataStore();

    // Initialize health monitor
    import services.health_monitor: HealthMonitor;
    auto healthMonitor = new HealthMonitor(
        "http://payment-processor-default:8080",
        "http://payment-processor-fallback:8080"
    );

    // Set up the payment processor with default and fallback URLs
    auto paymentProcessor = new PaymentProcessor(
        "http://payment-processor-default:8080",
        "http://payment-processor-fallback:8080",
        dataStore,
        healthMonitor
    );

    // Initialize handlers
    auto paymentHandler = new PaymentHandler(paymentProcessor);
    auto summaryHandler = new SummaryHandler(dataStore);

    // Configure routes
    router.get("/", &healthHandler);
    router.post("/payments", &paymentHandler.processPayment);
    router.get("/payments-summary", &summaryHandler.getSummary);

    // Start the server
    listenHTTP(settings, router);
    logInfo("Server is running on http://localhost:9999");
    runApplication();
}