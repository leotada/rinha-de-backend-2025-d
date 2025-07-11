module handlers.health;
@safe:

import vibe.http.server: HTTPServerRequest, HTTPServerResponse;
import vibe.data.json: serializeToJson;

/// Health check handler for GET /
void healthHandler(HTTPServerRequest req, HTTPServerResponse res)
{
    res.statusCode = 200;
    res.headers["Content-Type"] = "application/json";
    res.writeBody(serializeToJson(["status": "ok"]).toString());
}
