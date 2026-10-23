## Focus: Android / mobile

Any stack (Kotlin/Java with Compose or Views, React Native/Expo, .NET MAUI). Apply checks fitting diff's stack. Each new/changed screen: trace navigation/deep link → screen → ViewModel/store → repository → network/local DB → rendered states.

Reference checklist, priority order. Apply only items relevant to diff:

1. **Architecture**
   - App's pattern (MVVM/MVI, unidirectional flow): UI → ViewModel → repository/use case → data source. No business logic or direct network/DB calls in Activities, Fragments, composables, RN screens.
   - Single source of truth: one owner per state (repo/local DB for data, ViewModel/store for screen state); no drifting copies.
   - UI state exposed immutable (`StateFlow`/sealed UI state), not mutable fields UI writes back.
   - Deps via project DI (Hilt/Koin/context providers), not singletons or `new` in classes; correct scopes.
   - Module boundaries respected; shared code in shared/core module, not copied between features.
   - Platform APIs (Context, sensors, storage, OS services) out of ViewModels/business logic → unit-testable.

2. **Auth & session**
   - Tokens in Keystore/EncryptedSharedPreferences/encrypted DataStore, `expo-secure-store`/Keychain, MAUI `SecureStorage`; never plain SharedPreferences, AsyncStorage, files, local DB.
   - Concurrent 401s → one synchronized refresh (OkHttp `Authenticator`/interceptor with lock or shared promise); failed refresh → clean logout; no infinite retry.
   - Logout clears tokens, Room/SQLite, caches, image caches, DataStore, WorkManager jobs, notifications, push token registration; next account sees nothing of previous.
   - Deep links/notifications to authenticated screens check session first.
   - OAuth via system browser/Custom Tabs (AppAuth) + PKCE, not embedded WebView; no client secrets.
   - 2FA/verification not bypassable by deep link or direct navigation; lockout/429 shown clearly, no auto-retry loop.
   - Biometrics bound to Keystore key (`CryptoObject`), not UI callback flipping boolean.
   - `android:allowBackup`/backup rules exclude tokens + sensitive data.

3. **Authorization**
   - Hidden button/screen ≠ security; restricted actions enforced by API too. Flag client-only role checks on sensitive actions.
   - Roles from server, not client-editable storage flag.
   - Cache keyed per account; switching accounts never shows other user's data.
   - Background work (WorkManager, sync, push handlers) runs as current account, cancelled on logout/account switch.
   - Actions offered only in valid states (no "settle" on settled expense); rejected transition (409/422) refreshes stale state; leave-group/remove-member with balances shows server's reason, not silent fail.

4. **Security**
   - No secrets/API keys in code, `BuildConfig`, `strings.xml`, `app.json`, JS bundle (all extractable from APK).
   - Network: no cleartext (`usesCleartextTraffic`, network security config), no trust-all `TrustManager`/`HostnameVerifier`, no ignored WebView SSL errors; keep cert pinning if used.
   - Components: no `exported="true"` without need + permission; no intent redirection (incoming `Intent` extra → `startActivity`); `PendingIntent` explicit `FLAG_IMMUTABLE`/`FLAG_MUTABLE`; no sensitive data in implicit intents.
   - WebView: `addJavascriptInterface` with untrusted content, `setAllowFileAccess`/universal file access, URLs from intents/deep links without allow-list.
   - Files: `FileProvider` paths not exposing whole app dir; sensitive files in internal storage; downloads via MediaStore/SAF, opened with validated MIME; incoming `ACTION_SEND` files size/type-checked.
   - Debug tools (Chucker, Flipper, Stetho, debug menus, `WebView.setWebContentsDebuggingEnabled(true)`, `android:debuggable`) debug builds only.
   - RN: prototype pollution from deep-merging deep link/push/API JSON.
   - Raw Room/SQLite queries (`rawQuery`, `@RawQuery`) use bound args, not string-built SQL.
   - Sensitive screens (payments, balances, OTP) `FLAG_SECURE` if app does that; no needless clipboard copies of sensitive data.
   - No tokens/PII/financial data in Logcat, crash reports, analytics; debug logging stripped in release.

5. **Input validation**: deep link params, intent extras, push payloads, QR/scanned data, clipboard = untrusted, validate before use; money parsed locale-safe, integer minor units or `BigDecimal`, never float/double for totals/splits; file size/type checked before upload (server still enforces).

6. **Correctness & crashes**
   - Null handling, `!!`/`lateinit` on maybe-absent values, unhandled promise rejections/exceptions crashing app.
   - Nav params/intent extras missing or wrong type; back-stack behavior; double navigation on fast taps.
   - API-level/platform paths without check (`Build.VERSION.SDK_INT`, `Platform.OS`).
   - Pagination: dedupe by ID across pages; use cursors where API offers (no dupes/gaps on insert).
   - Numbers: `Int` overflow on minor-unit amounts/counters (use `Long`); RN: IDs/amounts > 2^53 as strings; converted currency from server values/rates, not recomputed on device.
   - Dates: API UTC shown in device timezone; `java.time` over `Date`/`SimpleDateFormat` where minSdk allows.

7. **Lifecycle & memory**
   - Leaks: listeners, subscriptions, timers, handlers not removed on unmount/destroy; Activity/Context/View held by ViewModel, singleton, static.
   - State lost on rotation, backgrounding, process death (`rememberSaveable`, `SavedStateHandle`).
   - Flows collected without lifecycle awareness (`collectAsStateWithLifecycle`/`repeatOnLifecycle`).

8. **Threading & concurrency**
   - Heavy work, disk/DB/network I/O on main/UI/JS thread.
   - Coroutines: `GlobalScope`, `runBlocking` on main, wrong dispatcher, swallowed `CancellationException`, missing structured scope (`viewModelScope`/`lifecycleScope`).
   - Races between async results and UI state; one-off events (nav, toasts) via state that replays on rotation.

9. **Data & network performance**
   - **N+1 requests/queries**: one API call or DB query per list item (in `onBindViewHolder`, per-item composable, per-row `useEffect`). Fix: batch endpoint, include data in list response, one joined query.
   - Room: query per parent instead of `@Relation` + `@Transaction`; missing indexes on queried/FK columns; whole tables instead of Paging 3/`LIMIT`.
   - Sequential calls that could be parallel (`async`/`awaitAll`, `Promise.all`); refetch on every recomposition/resume/rotation instead of caching in ViewModel/repo.
   - Full lists instead of paginated; over-fetching; images without caching loader (Coil/Glide/expo-image) or at full resolution.
   - Battery/data: polling vs push, wakelocks, exact alarms, WorkManager without constraints/backoff; big downloads on metered networks.

10. **Render performance**
    - Compose: unstable params → recomposition, missing `remember`/`key`, work in composition instead of `LaunchedEffect`, state read too high in tree.
    - RN: needless re-renders, inline fns/objects to memoized children, heavy JS work during animations.
    - Big lists without virtualization (`LazyColumn`/`RecyclerView`/`FlatList` with `keyExtractor`), deep view hierarchies, overdraw.

11. **Local data, offline, network**
    - Room/SQLite migration for every schema change; no `fallbackToDestructiveMigration` wiping user data in prod; schema exported.
    - Offline writes queued + synced idempotently (no dupes on retry); local/server conflicts resolved deliberately.
    - Timeouts, backoff retry, no-connectivity handling, user-facing errors, no infinite spinners.
    - Old app versions live for months: parsing tolerates unknown fields/enums (`ignoreUnknownKeys`, unknown-enum fallback); breaking API changes gated by min-version/force-update.
    - Push (FCM): refreshed tokens re-registered; duplicate/out-of-order notifications handled idempotently; payloads carry IDs, not sensitive data.

12. **Permissions**: only needed ones, requested at runtime with rationale at point of use; denial + "don't ask again" handled; new manifest permissions justified (Play policy: location, SMS, contacts, background).

13. **UX & a11y**: content descriptions/labels, touch targets ≥ 48dp, safe areas/edge-to-edge insets, keyboard covering inputs, dark mode, font scaling, hard-coded strings → resources.

14. **Release & config**
    - Version code/name bumps; `targetSdk`/`minSdk` changes + behavior impact; `app.json`/`AndroidManifest.xml`/`build.gradle` changes; R8 rules for new reflection/serialization; native deps needing rebuild.
    - New deps maintained, no known vulns; lockfile/version catalog limited to intended upgrade (no unexpected major/transitive); debug-only code/endpoints not in release.
    - Play policy: in-app account deletion if accounts creatable; Data safety form updated for new personal data; analytics respects consent.

15. **Tests**: new logic (ViewModels, reducers, use cases, repos) tested incl. error + logged-out states; DB migrations tested; risky flows covered.
