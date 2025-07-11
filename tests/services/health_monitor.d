module tests.services.health_monitor_test;
@safe:

import std.stdio;
import std.conv;
import vibe.core.core;
import vibe.http.server;
import vibe.inet.url;
import core.time;
import services.health_monitor;

unittest {
    writeln("Testing HealthMonitor creation...");

    // Test that the health monitor can be created successfully
    auto monitor = new HealthMonitor("http://default:8080", "http://fallback:8080");
    assert(monitor !is null, "HealthMonitor should be created");

    // Test getBestProcessorUrl returns a valid URL
    auto bestUrl = monitor.getBestProcessorUrl();
    assert(bestUrl.length > 0, "Best processor URL should not be empty");

    writeln("✓ HealthMonitor creation test passed");
}

unittest {
    writeln("Testing HealthMonitor URL selection...");

    auto monitor = new HealthMonitor("http://default:8080", "http://fallback:8080");

    // Test that monitor can handle URL selection
    auto defaultHealth = monitor.getDefaultHealth();
    auto fallbackHealth = monitor.getFallbackHealth();

    // These should be valid ProcessorHealth structs
    assert(defaultHealth.minResponseTime >= 0, "Default response time should be non-negative");
    assert(fallbackHealth.minResponseTime >= 0, "Fallback response time should be non-negative");

    writeln("✓ HealthMonitor URL selection test passed");
}

unittest {
    writeln("Testing HealthMonitor with invalid URLs...");

    // Test that monitor handles invalid URLs gracefully
    auto monitor = new HealthMonitor("http://invalid:8080", "http://invalid2:8080");
    assert(monitor !is null, "HealthMonitor should handle invalid URLs");

    // Should still return a URL (fallback behavior)
    auto bestUrl = monitor.getBestProcessorUrl();
    assert(bestUrl.length > 0, "Should return a fallback URL");

    writeln("✓ HealthMonitor invalid URLs test passed");
}
