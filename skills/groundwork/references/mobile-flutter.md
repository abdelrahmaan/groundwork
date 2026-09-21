# Mobile Standard — Flutter (Arabic-first)

**Default: Flutter.** One codebase for iOS + Android, consistent rendering, best tooling for a solo engineer whose backend is a separate FastAPI service.
Alternatives: **React Native + Expo** if the team is React-first (largest talent pool, OTA via EAS); **Kotlin Multiplatform + Compose Multiplatform** when modernizing existing native apps incrementally (JetBrains' surveys show KMP usage roughly doubling year over year).

## Contents
1. Architecture & structure
2. State management
3. Networking & generated client
4. Models & serialization
5. Streaming LLM responses
6. Auth & secure storage
7. Local persistence & offline
8. Routing & DI
9. Arabic / RTL / localization
10. Performance
11. Testing
12. CI/CD & release
13. AI-specific mobile concerns

---

## 1. Architecture & structure

- **Feature-first** folders; inside each feature keep the three layers:
  `presentation/` (widgets + controllers) → `domain/` (entities + use cases, pure Dart) → `data/` (repositories, DTOs, data sources).
- `core/` holds config/env, theme, localization, networking, error types, DI.
- Rules: widgets never call a data source directly; repositories return domain entities, not DTOs; domain has zero Flutter imports (keeps it testable).
- Solo-scale pragmatism: skip use-case classes when a repository call is a one-liner — add them when logic appears.

## 2. State management

**Default: Riverpod (3.x with `@riverpod` codegen).** Compile-safe, no `BuildContext` needed, easy overrides in tests, auto-dispose, and `AsyncValue` models loading/data/error in one type — which matches API-driven UI exactly.
- **Bloc/Cubit** when you need an explicit event log/audit trail or a larger team wants rigid structure (fintech, health).
- **Provider** only in legacy code. Avoid GetX for new projects.
- Keep server state in async providers (with caching/invalidation), UI state in simple notifiers. Same principle as TanStack Query on web.

## 3. Networking & generated client

- **dio** as the HTTP client with interceptors: auth (attach bearer, refresh on 401 with a single in-flight refresh), retry with backoff, logging (redacted), timeouts.
- **Generate the Dart client from the same OpenAPI spec** (`openapi-generator` dart-dio, `swagger_dart_code_generator`, or retrofit for hand-declared typed calls). The contract stays single-sourced with web and backend.
- Map backend **RFC 9457 problem+json** into typed failures (`AppException(code, title, detail, traceId)`) once, in the network layer.
- Base URL and flavors from `--dart-define` / env config, never hardcoded.

## 4. Models & serialization

- **freezed + json_serializable** for immutable models, unions (`Result`/`Failure`), and `copyWith`; `build_runner` in watch mode during development.
- Keep DTOs (generated) separate from domain entities when the API shape and the UI shape diverge; map in the repository.

## 5. Streaming LLM responses

- The backend streams typed SSE events; consume them with a **streamed HTTP POST** (`dio` with `ResponseType.stream`, or `http.Client().send`) and a small line parser that reconstructs `event:`/`data:` frames.
- Expose it as a `Stream<ChatEvent>` from the repository → a Riverpod `StreamProvider`/notifier → the UI appends tokens.
- Handle: cancellation (`CancelToken` / cancel on dispose), reconnect with backoff, `Last-Event-ID` resume if the backend supports it, and app backgrounding (pause/resume or finish server-side).
- Note: LLM streaming on **Flutter web** has known gaps (see flutter/flutter#172030) — validate early if web is a target.
- WebSocket instead of SSE only when you need bidirectional traffic (voice, live interrupts).
- UI: typing indicator, token batching (don't `setState` per character), auto-scroll with a "jump to latest" affordance, stop button.

## 6. Auth & secure storage

- Tokens in **flutter_secure_storage** (Keychain / Android Keystore). Never `SharedPreferences`.
- OIDC + **PKCE** via the IdP's SDK or `flutter_appauth`; refresh handled inside the dio interceptor.
- Biometric unlock with `local_auth` for sensitive apps; re-auth on app resume after a timeout.
- Certificate pinning for high-security deployments; jailbreak/root detection only if the threat model asks for it.

## 7. Local persistence & offline

- **Drift** (typed SQL over SQLite) is the default when you need queries/relations; **Isar/Hive** for simple key-value or object caches; `sqflite` when you want raw control.
- Offline-first pattern: write to local store → optimistic UI → sync queue with retries → reconcile on conflict (last-write-wins or server-authoritative).
- Cache API responses with an explicit TTL and a "last synced" indicator; never pretend stale data is live.

## 8. Routing & DI

- **go_router** (declarative, deep links, redirect guards for auth). One router config with typed routes.
- DI: **Riverpod as the container** (preferred — one system), or `get_it` + `injectable` if the team prefers service-locator style.

## 9. Arabic / RTL / localization

- `flutter_localizations` + `intl` + **ARB files**; generate with `flutter gen-l10n`. Share key names with the web app where practical.
- Flutter mirrors layouts automatically from `Directionality`; use `EdgeInsetsDirectional`, `AlignmentDirectional`, `start/end` — never `left/right`.
- Arabic typography: pick a proper Arabic face (Cairo / Tajawal / Noto Naskh Arabic), check line height and diacritics, and bundle only the weights used.
- Bidi pitfalls: mixed Arabic + Latin + digits in one string (use `Bidi` helpers / `Directionality` wrappers), Arabic-Indic vs Latin digits (`NumberFormat` with the locale), date formatting (`DateFormat` with locale), and RTL-mirrored icons.
- Test with real Arabic content and a device set to Arabic — including the app switcher, notifications, and share sheets.

## 10. Performance

- `const` constructors everywhere they apply; split big widgets; avoid rebuilding whole subtrees (fine-grained providers/selectors).
- `ListView.builder` / `SliverList` for long lists; `cached_network_image` for remote images; resize images server-side.
- Profile with **DevTools** (timeline, rebuild counts, memory) on a **physical device in profile mode** — not on the simulator in debug.
- Release builds: `--obfuscate --split-debug-info`, shrink assets, defer heavy features.

## 11. Testing (solo-sustainable)

- Unit tests for domain + repositories (mock the dio client / override Riverpod providers).
- Widget tests for the few complex widgets (chat list, forms).
- A couple of integration tests for the critical flow (login → main action).
- Golden tests only where visual regressions actually hurt (design-system components) — and regenerate them deliberately.
- Skip the 100%-coverage mandate that starter templates ship with.

## 12. CI/CD & release

- **Codemagic** (Flutter-native, easiest signing) or **GitHub Actions** (+ **Fastlane**) if you want everything in one place.
- Flavors/environments: dev / staging / prod with separate bundle IDs, icons, and API base URLs.
- Signing: keys in the CI secret store; never in the repo.
- **Shorebird** for over-the-air Dart code push (respect store policies — no behavior changes that dodge review).
- Crash + analytics: **Sentry** and/or **Firebase Crashlytics**; upload debug symbols in CI.
- Store gotchas: privacy manifests / data-safety forms, ATT prompt if tracking, Arabic store listing + RTL screenshots, phased rollout, and a forced-upgrade check driven by an API version endpoint.

## 13. AI-specific mobile concerns

- **Streaming chat UI** as in §5; show tool-call status and citations the same way the web does (shared event contract).
- **Audio**: `record` / `flutter_sound` for capture, upload or stream to the backend ASR; show live waveform; handle mic permissions and interruptions (calls). Arabic ASR runs server-side — keep the model choice on the backend.
- **On-device inference** only when there's a privacy/offline requirement: ML Kit for standard tasks, `llama.cpp`/gemma bindings for small LLMs. Otherwise the server wins on quality and battery.
- **Background work**: `workmanager` for uploads/sync; long agent runs stay server-side with **push notification** on completion (FCM/APNs) + a status screen.
- Token budgets and cost caps live server-side; the app just handles `429` and quota errors gracefully.
