module handlers.payments;

@safe:

import vibe.http.server: HTTPServerRequest, HTTPServerResponse;
import vibe.data.json;
import std.conv: to;
import services.payment_processor: PaymentProcessor, PaymentRequest;

class PaymentHandler {
    private PaymentProcessor paymentProcessor;

    this(PaymentProcessor processor) {
        this.paymentProcessor = processor;
    }

    void processPayment(HTTPServerRequest req, HTTPServerResponse res) {
        try {
            auto json = req.json;
            auto request = PaymentRequest(
                json["correlationId"].get!string,
                json["amount"].get!double,
                json["to"].get!string,
                json["from"].get!string
            );

            paymentProcessor.sendPaymentRequest(request);

            res.statusCode = 202; // Accepted
            res.writeBody("Payment request accepted.", "text/plain");
        } catch (Exception e) {
            res.statusCode = 400; // Bad Request
            res.writeBody("Invalid payment request: " ~ e.msg, "text/plain");
        }
    }
}