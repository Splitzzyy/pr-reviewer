## Focus: Android / mobile app

The app may be native (Kotlin/Java), React Native/Expo, or .NET MAUI. Apply the checks that fit the stack in the diff.

Check in this priority order:

1. **Correctness & crashes**: null handling, unhandled promise rejections/exceptions that crash the app, navigation params that may be missing, platform-specific code paths.
2. **Lifecycle & memory**
   - Leaks: listeners, subscriptions, timers, or event handlers not removed on unmount/destroy; Activity/Context held by long-lived objects.
   - State lost on configuration change (rotation), backgrounding, or process death.
3. **Threading & performance**: heavy work or I/O on the main/UI/JS thread, unnecessary re-renders, large lists without virtualization (`FlatList`/`RecyclerView`), oversized images.
4. **Security**
   - Tokens/credentials in plain storage (AsyncStorage, SharedPreferences); use SecureStore/Keystore/EncryptedSharedPreferences.
   - Secrets or API keys hard-coded in the bundle.
   - Deep links and intents: validate incoming parameters; no exported components without need.
   - Cleartext HTTP, disabled certificate validation, verbose logging of sensitive data.
5. **Network & offline**: timeouts, retry, no-connectivity handling, error messages shown to the user, no infinite spinners.
6. **Permissions**: only the permissions needed, requested at runtime with rationale, graceful handling when denied.
7. **UX & accessibility**: content descriptions/accessibility labels, touch target sizes, safe areas/notches, keyboard covering inputs, dark mode.
8. **Release & config**: version code/name bumps, app config (`app.json`/`AndroidManifest.xml`/`build.gradle`) changes, ProGuard/R8 rules, new native dependencies requiring a rebuild.
9. **Tests**: new logic has tests; risky flows are covered.
