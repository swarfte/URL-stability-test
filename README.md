# URL 穩定性測試 (URL Stability Test)

A cross-platform **URL stability test** tool built with Flutter. Enter an
HTTP/HTTPS URL, fire a configurable number of sequential `GET` requests, and
inspect the responsiveness and reliability of the target endpoint — latency
distribution, success rate, timeouts, and per-attempt detail.

> ⚠️ **What this measures.** Each "delay" is the full HTTP round-trip time —
> from just before the `GET` is sent until the response body has been fully
> received (or the request fails). This is **not** ICMP ping, traceroute, or a
> speed test. See [What it is (and isn't)](#what-it-is-and-isnt).

The UI is written in Traditional Chinese (繁體中文) with an Apple-inspired
Cupertino look.

---

## Table of contents

- [Features](#features)
- [What it is (and isn't)](#what-it-is-and-isnt)
- [Supported platforms](#supported-platforms)
- [How a test works](#how-a-test-works)
- [Statistics definitions](#statistics-definitions)
- [Result classifications](#result-classifications)
- [Project structure](#project-structure)
- [Development environment requirements](#development-environment-requirements)
- [Getting the code & installing dependencies](#getting-the-code--installing-dependencies)
- [Running the app](#running-the-app)
- [Building a release](#building-a-release)
- [Platform setup](#platform-setup)
- [Running the tests](#running-the-tests)
- [Configuration & local persistence](#configuration--local-persistence)
- [Privacy & security](#privacy--security)
- [Known limitations](#known-limitations)
- [Tech stack](#tech-stack)
- [License](#license)

---

## Features

- **HTTP/HTTPS URL input** with validation and automatic `https://`
  prepend when no scheme is given (e.g. `example.com` → `https://example.com`).
  An existing `http://` is left untouched and only earns a non-blocking warning.
- **Two connection modes**
  - **正常連線 (reuse client)** — all requests in a run share one HTTP client,
    so connections can be reused. Closest to everyday app/API behaviour.
  - **每次新連線 (new client per request)** — a fresh HTTP client is created
    and closed for every request, forcing reconnection.
- **Selectable test count** — 5 / 10 / 20 / 50 sequential requests (default 10).
- **Selectable interval** — none / 0.5 s / 1 s / 2 s / 5 s between requests
  (default 1 s). The interval starts *after* one request finishes and *before*
  the next begins.
- **Selectable per-request timeout** — 3 s / 5 s / 10 s / 30 s (default 10 s).
- **Sequential execution** — never more than one in-flight request at a time.
- **Safe cancellation** — leaving the screen or pressing *取消測試* shows a
  confirmation dialog; completed results are preserved.
- **Live progress** — current attempt, progress bar, interim statistics, and
  the most recent results update in real time.
- **Full statistics** — average, median, min, max, **P95**, **jitter**, and
  success rate, plus timeout / HTTP-error / other-error counts.
- **Latency trend chart** — line chart (`fl_chart`) with status-coded points
  (success / HTTP error / timeout / other network error); cancelled attempts
  are not drawn.
- **Per-attempt detail** — every row expands to show timing, HTTP status,
  response bytes, redirect count, final URL, and a safe error summary.
- **Recent-settings persistence** — the last-used URL, connection mode, count,
  interval, and timeout are restored on next launch.
- **Responsive layout** — single column on narrow windows / Android; two-column
  results view on wide desktop windows.

## What it is (and isn't)

**It is**

- a general-purpose network diagnostic that measures the *full HTTP response
  time* and connection stability from this device to a URL you choose.

**It is _not_**

- an ICMP ping or traceroute tool
- a carrier-grade speed test (no upload/download throughput testing)
- an SLA certification tool
- a load / stress-testing tool (requests are strictly sequential)
- a security scanner

> The first request in a run is often slower than later ones because it may
> include DNS, TCP, and TLS setup. In *reuse client* mode subsequent requests
> may reuse that established connection.

## Supported platforms

Stage 1 officially targets, in priority order:

| Platform | Status |
| --- | --- |
| **Android** | ✅ Supported (Internet permission configured) |
| **Windows** | ✅ Supported |
| **macOS** | ✅ Supported (network client entitlement configured, App Sandbox on) |

Web, iOS, and Linux are **not** part of this stage. (The Flutter scaffolds for
those platforms still exist in the repo but are untested and unsupported.)

## How a test works

```text
啟動 App
   ↓
測試設定頁  →  enter URL, pick connection mode / count / interval / timeout
   ↓
按「開始測試」  →  validate → save settings → create session → navigate
   ↓
測試進行中頁  →  run requests sequentially, show live progress + interim stats
   ↓
完成 / 取消 / 不可恢復錯誤
   ↓
測試結果頁  →  summary, statistics, latency chart, per-attempt detail
   ↓
再次測試 (same settings)   或   修改設定 (back to setup)
```

Per-request behaviour:

- **Method:** `GET` only.
- **Request headers sent:** `Accept: */*`, `Cache-Control: no-cache`,
  `Pragma: no-cache`.
- **Redirects:** followed automatically, up to **5** hops; beyond that the
  attempt is classified `tooManyRedirects`. Redirect time counts toward the
  attempt's delay; the final URL is recorded.
- **Response body:** streamed and byte-counted — **never buffered whole**. A
  single response is capped at **10 MiB**; exceed it and the attempt is
  classified `responseTooLarge`.
- **Timing:** measured with a monotonic `Stopwatch`, started just before the
  request is sent and stopped once the body is fully read (or the request
  fails / times out / is cancelled). Internal precision is microseconds.
- **On timeout:** the attempt is recorded as `timeout`, its client is closed,
  and the run continues with the next attempt after the configured interval.
- **On any failure:** a single attempt failing never aborts the run; the next
  attempt still runs.

## Statistics definitions

All latency statistics use **only** `success` results (HTTP `2xx`/`3xx` with a
fully received body under the size cap). HTTP errors, timeouts, and network
errors are excluded from latency math but still counted in the success-rate
denominator; cancelled attempts are excluded entirely.

Latencies are shown in **milliseconds** (rounded to the nearest integer). When
there are no successes, every latency metric shows `N/A` rather than `0 ms`.

| Metric | Definition |
| --- | --- |
| **Average** | sum of success latencies ÷ success count |
| **Minimum / Maximum** | smallest / largest success latency |
| **Median** | middle value (odd count) or mean of the two middle values (even count) |
| **P95** | nearest-rank percentile: `rank = ceil(0.95 × N)` on the sorted successes |
| **Jitter** | mean of `abs(success[i] − success[i−1])` over adjacent successes in run order (needs ≥ 2 successes, else `N/A`) |
| **Success rate** | `success count ÷ completed attempts × 100%` (cancelled attempts not in denominator; `N/A` if none completed) |

## Result classifications

Every attempt is classified into exactly one category:

| Status | Meaning |
| --- | --- |
| `success` | Completed in time, HTTP `200–399`, body within the size cap |
| `httpError` | Full response received but HTTP `400–599` |
| `timeout` | Exceeded the configured per-request timeout |
| `dnsError` | Host lookup failed |
| `connectionError` | Refused / unreachable / reset / closed / no network |
| `tlsError` | TLS handshake or certificate failure (never bypassable) |
| `tooManyRedirects` | More than 5 redirects |
| `responseTooLarge` | Response body exceeded 10 MiB |
| `cancelled` | The in-flight request was cancelled by the user |
| `unknownError` | An exception that could not be otherwise classified |

## Project structure

The app follows a layered feature-based layout (see `project-spec.md` §18):

```text
lib/
├── app/
│   ├── app.dart                 # CupertinoApp root, routing, theme
│   ├── routes.dart              # named routes: / , /progress, /result
│   └── theme.dart               # Cupertino theme
├── features/stability_test/
│   ├── models/                  # plain data classes (no Flutter deps)
│   │   ├── connection_mode.dart
│   │   ├── test_configuration.dart
│   │   ├── test_interval.dart
│   │   ├── test_timeout.dart
│   │   ├── test_result.dart     # TestResult + ResultStatus
│   │   └── test_session.dart
│   ├── services/                # pure, unit-testable logic
│   │   ├── url_validation_service.dart
│   │   ├── statistics_service.dart
│   │   └── stability_test_service.dart   # the sequential HTTP runner
│   ├── controllers/
│   │   └── stability_test_controller.dart  # ChangeNotifier state machine
│   ├── screens/
│   │   ├── test_setup_screen.dart
│   │   ├── test_progress_screen.dart
│   │   └── test_result_screen.dart
│   └── widgets/                 # Cupertino UI building blocks
└── shared/
    ├── storage/settings_storage.dart  # recent-settings persistence
    ├── formatting/
    ├── accessibility/
    └── widgets/
```

Layering rules enforced in the code:

- **UI never performs HTTP directly** — all requests go through
  `StabilityTestService`.
- **Statistics are computed in `StatisticsService`**, not inside widgets.
- **URL validation is isolated** and has no Flutter dependency.
- **Models do not depend on widgets.**
- The HTTP runner takes an injectable `clientFactory`, so it is fully testable
  with `package:http`'s `MockClient`.

State management uses Flutter's built-in **`ChangeNotifier`**
(`StabilityTestController`), which owns the single live `TestSession`, prevents
two concurrent runs, streams each result to the UI, supports cancellation, and
never notifies after `dispose`.

---

## Development environment requirements

- **Flutter SDK** with **Dart `^3.12.2`** or newer. Check with:

  ```bash
  flutter --version          # ensure Dart ≥ 3.12.2
  flutter doctor             # make sure Android / desktop toolchains are ✓
  ```

- **Per-platform toolchains** (install only what you intend to build for):
  - **Android** — Android Studio (or command-line tools) + a supported Android
    SDK / NDK; an Android device or emulator.
  - **Windows** — Windows 10/11 with Visual Studio 2022 including the
    *"Desktop development with C++"* workload.
  - **macOS** — Xcode 15+ (run `sudo xcodebuild -license` and open Xcode once
    to install components).

## Getting the code & installing dependencies

```bash
git clone <this-repo-url>
cd URL-stability-test
flutter pub get
```

## Running the app

Pick the device with `flutter devices`, then run on your chosen platform:

```bash
flutter run -d chrome        # example device id; replace with yours
flutter run -d <android-device-id>
flutter run -d windows
flutter run -d macos
```

> The first desktop/macOS run may take longer while native build artifacts are
> produced.

## Building a release

```bash
flutter build apk --release       # Android
flutter build appbundle --release # Android (AAB for Play Store)
flutter build windows --release   # Windows
flutter build macos --release     # macOS
```

Release artifacts are written under `build/`.

## Platform setup

The required platform permissions are **already configured** in this repo; this
section documents what they are and where.

- **Android** — `android/app/src/main/AndroidManifest.xml` declares:

  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  ```

  Plain `http://` URLs may be blocked by Android's network security policy.
  Prefer HTTPS; the app does **not** disable TLS verification or globally allow
  cleartext traffic.

- **macOS** — `macos/Runner/DebugProfile.entitlements` and
  `Release.entitlements` enable outgoing network with the App Sandbox on:

  ```xml
  <key>com.apple.security.network.client</key>
  <true/>
  ```

  The sandbox is **not** disabled and TLS verification is **not** bypassed.

- **Windows** — standard outbound HTTPS/HTTP works without extra setup; an
  ordinary outbound request should not trigger a Windows Firewall prompt.

## Running the tests

Unit + widget tests live under `test/`:

```bash
flutter test                                # run everything
flutter test test/services                  # service-layer unit tests only
flutter test test/services/statistics_service_test.dart
```

Also recommended during development:

```bash
flutter analyze                             # static analysis (flutter_lints)
```

The service tests cover:

- **URL validation** — auto-HTTPS prepend, empty/invalid input, unsupported
  scheme, missing host, URLs containing userinfo.
- **Statistics** — average, median (odd + even), min/max, P95 (incl. single
  result), jitter, success rate, zero-success and single-success cases.
- **HTTP runner (via `MockClient`)** — client reuse vs. new-client-per-request,
  sequential execution, configurable interval, continue-after-timeout,
  continue-after-error, no-new-requests-after-cancel, redirect cap, streamed
  body reading, >10 MiB response, and that clients are ultimately closed.

---

## Configuration & local persistence

Only the **most recent test settings** are stored locally
(`shared_preferences`):

- URL, connection mode, test count, interval, timeout.

**Never** stored: response bodies, cookies, authentication data, full test
history, or error stack traces. There is no analytics, no account, no cloud
sync — everything stays on-device.

## Privacy & security

- URL and results are processed **on this device only** — nothing is sent to
  any developer-controlled server.
- TLS errors are **never** ignored; invalid certificates are never trusted.
- Response bodies are never executed, rendered as HTML, opened, downloaded, or
  written to disk — and they are capped at 10 MiB per response.
- Local schemes such as `file://` are rejected. Sensitive response headers
  (cookies, authorization) and stack traces are never displayed.

## Known limitations

- **Light Mode only.** Although the original spec targeted system-following
  Light *and* Dark themes, the current build **forces Light Mode** (see
  `lib/app/app.dart` and `lib/main.dart`). Dark Mode is not currently
  available.
- **No upload/download throughput testing**, no ICMP ping, no traceroute, no
  DNS/TCP/TLS/TTFB phase timing, and no concurrent/multi-URL or background
  scheduled tests (intentionally out of scope for stage 1).
- **No result export** (CSV/JSON/PDF), no test history beyond the current run,
  and no in-app sharing.
- **No custom HTTP headers, authentication, cookie management, or proxy
  settings** — and TLS verification cannot be disabled.
- **No subjective quality ratings** ("優秀 / 良好 / 差"). Reasonable latency
  depends on the target server's location and purpose, so the app reports
  numbers only and lets you judge.
- **"每次新連線" is app-level only.** A new HTTP client is created per request,
  but this does **not** guarantee that the OS DNS cache or lower-level
  connection state is fully cleared.
- **Plain `http://` URLs** may be blocked by the platform's network security
  policy; the app surfaces an understandable error rather than weakening TLS.
- **Some servers** may reject non-browser requests; results from such endpoints
  reflect that server's behaviour toward this client, not necessarily a network
  fault.
- The bundled `ios/`, `linux/`, and `web/` platform folders are leftover
  Flutter scaffolding and are **unsupported** in this stage.

## Tech stack

- **Flutter / Dart** (`Dart ^3.12.2`)
- **Cupertino** widgets (`CupertinoApp`, `CupertinoFormSection.insetGrouped`,
  `CupertinoSlidingSegmentedControl`, `CupertinoPicker`, …) for an
  Apple-inspired UI across all platforms
- [`package:http`](https://pub.dev/packages/http) — cross-platform HTTP client
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) — recent
  settings persistence
- [`fl_chart`](https://pub.dev/packages/fl_chart) — latency trend chart
- **`ChangeNotifier`** for state management (no extra state library required)

## License

Licensed under the **Apache License, Version 2.0** — see [LICENSE](./LICENSE).
