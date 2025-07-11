module tests.services.payment_processor_test;
@safe:

import std.stdio;
import std.datetime;
import vibe.data.json;
import services.payment_processor;
import services.health_monitor;
import handlers.summary;

// Mock HealthMonitor for testing
class MockHealthMonitor : HealthMonitor {
    private bool _defaultFailing;
    private bool _fallbackFailing;
    private string _defaultUrl;
    private string _fallbackUrl;

    this(string defaultUrl, string fallbackUrl, bool defaultFailing = false, bool fallbackFailing = false) {
        super(defaultUrl, fallbackUrl);
        this._defaultUrl = defaultUrl;
        this._fallbackUrl = fallbackUrl;
        this._defaultFailing = defaultFailing;
        this._fallbackFailing = fallbackFailing;
    }

    override string getBestProcessorUrl() {
        if (!_defaultFailing) return _defaultUrl;
        if (!_fallbackFailing) return _fallbackUrl;
        return _defaultUrl; // Default fallback
    }

    override ProcessorHealth getDefaultHealth() {
        return ProcessorHealth(_defaultFailing, _defaultFailing ? 500 : 100);
    }

    override ProcessorHealth getFallbackHealth() {
        return ProcessorHealth(_fallbackFailing, _fallbackFailing ? 500 : 100);
    }
}

unittest {
    writeln("Testing PaymentProcessor creation...");

    auto dataStore = new PaymentDataStore();
    auto monitor = new MockHealthMonitor("http://default:8080", "http://fallback:8080");
    auto processor = new PaymentProcessor("http://default:8080", "http://fallback:8080", dataStore, monitor);

    assert(processor !is null, "PaymentProcessor should be created");
    writeln("✓ PaymentProcessor creation test passed");
}

unittest {
    writeln("Testing PaymentRequest structure...");

    auto request = PaymentRequest("test-123", 100.50, Clock.currTime());

    assert(request.correlationId == "test-123", "Correlation ID should match");
    assert(request.amount == 100.50, "Amount should match");
    assert(request.requestedAt > SysTime.min, "RequestedAt should be set");

    writeln("✓ PaymentRequest structure test passed");
}

unittest {
    writeln("Testing PaymentProcessor with mock monitor...");

    auto dataStore = new PaymentDataStore();
    auto monitor = new MockHealthMonitor("http://default:8080", "http://fallback:8080");
    auto processor = new PaymentProcessor("http://default:8080", "http://fallback:8080", dataStore, monitor);

    // Test that getBestProcessorUrl works
    auto bestUrl = monitor.getBestProcessorUrl();
    assert(bestUrl == "http://default:8080", "Should return default URL when healthy");

    // Test with failing default
    auto failingMonitor = new MockHealthMonitor("http://default:8080", "http://fallback:8080", true, false);
    auto failingBestUrl = failingMonitor.getBestProcessorUrl();
    assert(failingBestUrl == "http://fallback:8080", "Should return fallback URL when default is failing");

    writeln("✓ PaymentProcessor with mock monitor test passed");
}
