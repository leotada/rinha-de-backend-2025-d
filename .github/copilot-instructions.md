# Copilot Instructions for Rinha de Backend 2025 D

## Project Overview
- This is a backend service for the Rinha de Backend 2025 challenge, written in D using the Vibe.d framework.
- The app processes payments and provides payment summaries, integrating with external payment processor APIs.

## Current using in this Project
- **DMD version:** 2.111.0
- **Vibe.d version:** 0.10.2

## Architecture & Key Components
- **Entry Point:** `source/app.d` initializes the HTTP server, configures routes, and wires up handlers and services.
- **Handlers:**
  - `handlers/payments.d`: Handles POST `/payments` requests, delegates to `PaymentProcessor`.
  - `handlers/summary.d`: Handles GET `/payments-summary` requests, aggregates payment data.
- **Services:**
  - `services/payment_processor.d`: Encapsulates logic for communicating with external payment processor APIs. Supports default and fallback URLs for reliability.
- **External Integration:**
  - Payment processor endpoints are configured in `app.d` and used by `PaymentProcessor`.
  - Health checks for processors are implemented (see service code for details).

## Developer Workflows
- **Activate DMD:**
  - Ensure you have the DMD compiler installed and activated in your environment. Use `source ~/dlang/dmd-2.111.0/activate` before running commands.
- **Build:**
  - Use `dub build` to compile the project.
- **Run Locally:**
  - Use `dub run` to start the server on port 9999 (see `app.d`).
- **Docker:**
  - Use `docker-compose up --build` to run the app and dependencies in containers.
- **Endpoints:**
  - `POST /payments` — process a payment
  - `GET /payments-summary` — get payment summary

## Patterns & Conventions
- **Dependency Injection:** Handlers receive service instances via constructor injection (see `app.d`).
- **Routing:** All routes are registered in `app.d` using Vibe.d's `URLRouter`.
- **Error Handling:** Follow patterns in handlers/services for error propagation and logging.
- **Async Processing:** Payment requests are handled asynchronously for performance (see service implementation).
- **Configuration:** Service URLs and ports are hardcoded in `app.d` for simplicity; update as needed for different environments.
- **Imports:** When using `import` statements to include modules try to follow the existing import structure, in a explicit manner, to maintain clarity and organization.
- **Safety:** Use `@safe` for all new code to ensure memory safety and prevent common pitfalls in D.

## Key Files & Directories
- `source/app.d` — main entry, routing, DI
- `source/handlers/` — request handlers
- `source/services/` — business logic and integrations
- `Dockerfile`, `docker-compose.yml` — containerization
- `dub.json` — DUB package config

## Example: Adding a New Endpoint
1. Create a handler in `source/handlers/`.
2. Register the route in `source/app.d` using `router.get/post/...`.
3. Inject required services via the handler's constructor.

---
For questions about conventions or unclear patterns, review the handler/service implementations or ask for clarification.
