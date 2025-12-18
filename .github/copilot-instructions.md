# Copilot Instructions — OutcomePredictor (StatShark)

Purpose: short, actionable guidance to help AI coding agents be productive immediately in this repository.

1. Big picture (where to look first)
   - This is a client/server Swift project: server = `Sources/NFLServer` (Vapor), client = `NFLOutcomePredictor` SwiftUI app, shared models = `Sources/OutcomePredictorAPI` and core logic = `Sources/OutcomePredictor`.
   - Key docs: `docs/guides/QUICK_START_SERVER.md`, `docs/guides/QUICK_START_iOS.md`, `docs/README.md`, `README.md` and `docs/api/openapi.yaml`.

2. Typical dev workflows (commands to run)
   - Resolve deps: `swift package resolve`
   - Build server: `swift build --product nfl-server`
   - Run server locally: `swift run nfl-server serve --hostname 0.0.0.0 --port 8080`
   - Run tests: `swift test --no-parallel`
   - Quick production endpoint check: `swift test_ios_production.swift` (script at project root)
   - iOS dev: open `NFLOutcomePredictor.xcodeproj` in Xcode and run tests/simulators there.

3. Project-specific conventions & patterns
   - Shared DTOs live in `Sources/OutcomePredictorAPI/DTOs.swift` and are used by both server and iOS. If you change an API shape, update OpenAPI and DTOs.
   - Networking: `NFLOutcomePredictor/APIClient.swift` uses `URLSession` and a custom `JSONDecoder` (.convertFromSnakeCase, .iso8601). Override the base URL via env var `SERVER_BASE_URL` for testing.
   - Concurrency: `DataManager` uses `Task`-based caching and cancels previous tasks to avoid duplicate requests. Respect cancellation via `guard !Task.isCancelled` and avoid treating cancellations as unexpected errors.
     - Example: when catching network errors, do not call `ErrorHandler` for cancellations:
       ```swift
       if let urlErr = error as? URLError, urlErr.code == .cancelled { throw error }
       if error is CancellationError { throw error }
       ```
   - UI/Actor model: many types are `@MainActor` (e.g., `APIClient`, `DataManager`, `ErrorHandler`). Follow actor boundaries when moving code between threads.
   - Error reporting: unexpected errors are reported via `ErrorHandler.shared.handle(error, context: "...")` and surfaced in `ErrorOverlay`.

4. Integration & important files
   - `docs/api/openapi.yaml` — source of truth for REST schema. Update it when adding/changing endpoints.
   - `Sources/NFLServer/` — Vapor endpoints and server logic. See `main.swift` and `Controllers` for routes.
   - `Sources/OutcomePredictor/` — prediction engine, baseline predictor, model code and protocol definitions.
   - `test_ios_production.swift`, `test_mobile_production.sh`, `test_production.sh` — small scripts to validate endpoints in production; useful for network-related PRs.

5. Testing & CI hints
   - CI runs `swift build` + `swift test`, builds Docker image, then runs deployment workflows in `.github/workflows`.
   - For network/endpoint changes: run local server, then run `test_ios_production.swift`; for iOS UI/network changes use the simulator via Xcode.

6. When changing API surface
   - Update `docs/api/openapi.yaml` and `Sources/OutcomePredictorAPI/DTOs.swift`. Add server endpoint tests and an iOS test where appropriate.
   - Ensure the OpenAPI examples match actual response shapes used by the client.

7. Quick troubleshooting tips
   - Frequent cause of `NSURLErrorDomain Code=-999 "cancelled"`: concurrent `Task` cancel() calls in `DataManager` when a second request supersedes a first. Inspect `DataManager`'s task lifecycle and add logging around `gamesTask?.cancel()` if needed.
   - Use `SERVER_BASE_URL` env var to point iOS client at a local server during debugging.

8. What the AI should *not* do automatically
   - Don't modify API shapes without updating OpenAPI and shared DTOs.
   - Don't treat `URLError(.cancelled)` / `CancellationError` as bugs to report in `ErrorHandler` (they are expected behavior in some flows).

9. Where to add docs & tests
   - Add short docs under `docs/guides/` for bigger features. Small changes can live in `README.md` or `docs/README.md`.
   - Add unit tests under `Tests/` corresponding to module names and follow the existing `swift test` patterns.

If any part of this summary is unclear or you want more examples (sample PR checklist, commands for iOS UI tests, or a CI debugging checklist), tell me which area to expand. ✅
