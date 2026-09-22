# Validation — 2026-09-22

- PASS: synthetic.json parsed with Python json; syntax only, not Apple parsing/runtime validation.
- NOT RUN: sh test-macos.sh emitted Linux guard and status 77, Apple SDK unavailable.
- NOT RUN: macOS Objective-C production/test compilation and Foundation assertions.
- NOT RUN: actual Security Keychain CRUD/accessibility/entitlements.
- NOT RUN: live weather API, live redirect/TLS handling, iOS 16.6/SpringBoard integration.
- No real Token, API request, CI, upload or primary project modification performed.
- Fixtures and all mocked HTTP responses are synthetic. Test-only credential strings are conspicuous dummy values; neither full URLs nor dummy credentials are logged.
