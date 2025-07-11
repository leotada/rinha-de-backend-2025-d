module tests.handlers.summary_test;
@safe:

import std.stdio;
import std.datetime;
import vibe.http.server;
import vibe.data.json;
import handlers.summary;

unittest {
    writeln("Testing SummaryHandler creation...");

    auto dataStore = new PaymentDataStore();
    auto handler = new SummaryHandler(dataStore);

    assert(handler !is null, "SummaryHandler should be created");
    writeln("✓ SummaryHandler creation test passed");
}

unittest {
    writeln("Testing PaymentDataStore functionality...");

    auto dataStore = new PaymentDataStore();

    auto now = Clock.currTime();
    auto payment1 = PaymentData(100.0, now, ProcessorType.Default);
    auto payment2 = PaymentData(200.0, now + 1.hours, ProcessorType.Fallback);

    dataStore.addPayment(payment1);
    dataStore.addPayment(payment2);

    // Query all payments
    auto allPayments = dataStore.query(SysTime.min, SysTime.max);
    assert(allPayments.length == 2, "Should return 2 payments");

    // Query with time range
    auto rangePayments = dataStore.query(now - 1.hours, now + 30.minutes);
    assert(rangePayments.length == 1, "Should return 1 payment in range");
    assert(rangePayments[0].amount == 100.0, "Should return the first payment");

    writeln("✓ PaymentDataStore functionality test passed");
}

unittest {
    writeln("Testing PaymentData struct...");

    auto now = Clock.currTime();
    auto payment = PaymentData(150.75, now, ProcessorType.Fallback);

    assert(payment.amount == 150.75, "Amount should match");
    assert(payment.timestamp == now, "Timestamp should match");
    assert(payment.processor == ProcessorType.Fallback, "Processor type should match");

    writeln("✓ PaymentData struct test passed");
}

unittest {
    writeln("Testing PaymentDataStore with multiple processor types...");

    auto dataStore = new PaymentDataStore();
    auto now = Clock.currTime();

    // Add payments to both processors
    dataStore.addPayment(PaymentData(100.0, now, ProcessorType.Default));
    dataStore.addPayment(PaymentData(200.0, now, ProcessorType.Fallback));
    dataStore.addPayment(PaymentData(50.0, now, ProcessorType.Default));

    auto allPayments = dataStore.query(SysTime.min, SysTime.max);
    assert(allPayments.length == 3, "Should return 3 payments");

    // Count by processor type
    int defaultCount = 0, fallbackCount = 0;
    double defaultTotal = 0.0, fallbackTotal = 0.0;

    foreach (payment; allPayments) {
        if (payment.processor == ProcessorType.Default) {
            defaultCount++;
            defaultTotal += payment.amount;
        } else {
            fallbackCount++;
            fallbackTotal += payment.amount;
        }
    }

    assert(defaultCount == 2, "Should have 2 default payments");
    assert(fallbackCount == 1, "Should have 1 fallback payment");
    assert(defaultTotal == 150.0, "Default total should be 150.0");
    assert(fallbackTotal == 200.0, "Fallback total should be 200.0");

    writeln("✓ PaymentDataStore multiple processor types test passed");
}
