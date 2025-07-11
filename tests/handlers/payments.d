module tests.handlers.payments_test;
@safe:

import std.stdio;
import std.datetime;
import vibe.http.server;
import vibe.data.json;
import handlers.payments;
import services.payment_processor;
import services.health_monitor;
import handlers.summary;

// Mock classes for testing
class MockPaymentProcessor : PaymentProcessor {
    PaymentRequest lastRequest;
    bool shouldThrow = false;

    this() {
        // Call super with dummy parameters
        super("http://mock:8080", "http://mock2:8080", new PaymentDataStore(), new MockHealthMonitor());
    }

    override void sendPaymentRequest(PaymentRequest request) {
        if (shouldThrow) {
            throw new Exception("Mock error");
        }
        lastRequest = request;
    }
}

class MockHealthMonitor : HealthMonitor {
    this() {
        super("http://mock:8080", "http://mock2:8080");
    }

    override string getBestProcessorUrl() {
        return "http://mock:8080";
    }
}

unittest {
    writeln("Testing PaymentHandler creation...");

    auto processor = new MockPaymentProcessor();
    auto handler = new PaymentHandler(processor);

    assert(handler !is null, "PaymentHandler should be created");
    writeln("✓ PaymentHandler creation test passed");
}

unittest {
    writeln("Testing PaymentRequest struct...");

    auto now = Clock.currTime();
    auto request = PaymentRequest("test-123", 100.50, now);

    assert(request.correlationId == "test-123", "Correlation ID should match");
    assert(request.amount == 100.50, "Amount should match");
    assert(request.requestedAt == now, "RequestedAt should match");

    writeln("✓ PaymentRequest struct test passed");
}

unittest {
    writeln("Testing PaymentProcessor mock functionality...");

    auto processor = new MockPaymentProcessor();
    auto request = PaymentRequest("test-456", 200.75, Clock.currTime());

    processor.sendPaymentRequest(request);

    assert(processor.lastRequest.correlationId == "test-456", "Should store last request");
    assert(processor.lastRequest.amount == 200.75, "Should store correct amount");

    writeln("✓ PaymentProcessor mock functionality test passed");
}
