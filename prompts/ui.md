## Focus: Web UI / frontend

Any stack (React, Next.js, Vite, Angular, Vue). Apply checks fitting diff's stack. Each new/changed screen: trace route → guard/layout → component → fetch hook/API client → backend call → rendered states.

Reference checklist, priority order. Apply only items relevant to diff:

1. **Architecture**
   - Server data in fetch cache (React Query/SWR/RTK Query or repo equivalent); global state only for app-wide concerns; rest local. No server data copied into global stores.
   - Fetching/side effects separate from presentational components; no 500-line mixed components.
   - API calls via existing API client/service layer, not raw `fetch` in components.
   - Reuse design system + shared components/hooks; new shared pieces in shared location.
   - Feature boundaries respected; no deep imports into another feature's internals.
   - Prop drilling > 2–3 levels or context for fast-changing values → suggest composition/scoped store.
   - Routing/code-splitting follow existing structure; new routes lazy-loaded where app does that.

2. **Auth & session**
   - Prefer `HttpOnly` `Secure` `SameSite` cookies; tokens in `localStorage`/`sessionStorage` readable by any XSS. Never tokens in URLs, query strings, analytics.
   - Concurrent 401s → single refresh (no storm/race logging user out); failed refresh → clean logout; no infinite retry.
   - Logout clears tokens, query cache, stores, persisted state, service worker caches; next user sees nothing of previous.
   - Protected routes guarded consistently (layout/middleware) incl. deep links + back after logout; session expiry → redirect, not broken screen.
   - Post-login redirects (`?next=`, `returnUrl`) same-origin paths only.
   - OAuth in browser: PKCE + `state` validated; no client secrets.
   - 2FA/verification not skippable by navigating to next route; lockout/429 shown clearly, no auto-retry loop.

3. **Authorization**
   - Hidden button/route ≠ security; every restricted action enforced by API too. Flag UI-only role checks on sensitive actions.
   - Roles from server (claims or `/me`), not client-editable storage flag.
   - No fetching others' data then filtering client-side.
   - URL IDs (`/groups/:id`): handle 403/404 gracefully; never render partial/cached data from previous user.
   - Actions offered only in valid states (no "settle" on settled expense); rejected transition (409/422) refreshes stale state; leave-group/remove-member with balances shows server's reason, not silent fail.

4. **Security**
   - XSS: `dangerouslySetInnerHTML`/`v-html`/`[innerHTML]`, unsanitized HTML/markdown, `href`/`src` from user input (`javascript:`), `target="_blank"` without `rel="noopener"`, `eval`/`new Function`.
   - No secrets in bundle; browser-exposed env vars (`NEXT_PUBLIC_*`, `VITE_*`, `REACT_APP_*`) hold nothing secret.
   - PII/financial data/tokens not in `localStorage`, console, analytics/error trackers, or rendered-then-CSS-hidden.
   - `postMessage` checks `event.origin`; iframes sandboxed; new third-party scripts justified, SRI where possible.
   - CSRF protection on state-changing requests with cookie auth.
   - Server components/actions (if used): no secrets/server-only modules in client components; actions check auth + ownership; no sensitive fields passed as client props.
   - Prototype pollution: query strings/JSON/`postMessage` data deep-merged (`lodash.merge`, custom merge).
   - User-uploaded HTML/SVG never rendered inline from app origin; downloads via signed URLs or blob URLs revoked after use.
   - No prod source maps, devtools (React Query/Redux), MSW mocks, debug flags unless intended.
   - New tracking respects app's consent mechanism if any.

5. **Input & forms**: client validation mirrors server, never relied on; double-submit prevented (disable button, idempotency key); locale-safe number/date/currency parsing; money as integer minor units or decimal strings, never float math for totals/splits; form state kept on failed submit; file size/type checked before upload (server still enforces).

6. **Correctness**
   - React: stale closures, wrong/missing `useEffect` deps, effects without cleanup, setState after unmount, derived state duplicated, missing/index `key` on dynamic lists.
   - Async races: out-of-order responses overwrite newer data; requests not aborted on unmount/input change.
   - TS: `any`, unsafe `as`, `!` hiding real nulls, unexplained `@ts-ignore`.
   - Dates: API UTC shown in user timezone; no `new Date(string)` on ambiguous formats.
   - Pagination/infinite scroll: dedupe by ID across pages; use cursors where API offers (no dupes/gaps on insert).
   - Numbers: IDs/amounts > 2^53 as strings; converted currency from server values/rates, not client-side rate.

7. **Fetch performance**
   - **N+1 requests**: one call per list item (row fetches own details/user/avatar). Fix: batch endpoint, include data in list response, shared query.
   - Waterfalls: sequential `await`s / parent→child fetch chains that could be parallel (`Promise.all`, parallel queries, route loaders, prefetch).
   - Duplicate requests not deduped via cache; refetch every render/mount/focus without need; missing `staleTime`.
   - Unbounded lists fetched whole instead of paginated; over-fetching big payloads.
   - Polling without backoff or not stopping on hidden tab/unmount; search without debounce.
   - Cache not invalidated after mutations, or over-invalidated.
   - Requests have timeout (`AbortSignal.timeout` or client setting).
   - Websockets/SSE (if used): backoff reconnect, resubscribe after token refresh, dedupe events, close on unmount.

8. **Render performance**: re-renders from new objects/fns as props to memoized children or recreated context values; heavy compute in render without memo; big lists without virtualization; heavy imports (whole lodash/moment/icon sets); big routes/modals not lazy; layout shift from unsized images; unoptimized images.

9. **UX states**: every fetch handles loading, error, empty; optimistic updates roll back on failure; errors shown in plain language, not swallowed or raw API text; no infinite spinners.

10. **Accessibility**: real buttons/links, labeled inputs, `alt` text, keyboard nav + focus management (modals trap/restore focus), contrast, not color-only info, live regions for async updates/toasts.

11. **Responsive & i18n**: works at mobile width; no overflowing fixed widths; long text/translations don't break layout; strings via i18n system if repo has one.

12. **API contract**: types match backend (generated types/schemas updated); new/removed fields + enum values handled safely; no hard-coded API URLs/env values. Users on previous bundle keep working after deploy: `ChunkLoadError` → reload; API changes compatible with previous frontend.

13. **Errors & observability**: error boundaries around risky subtrees; errors reported with context, no PII/tokens; leftover `console.log`/debug code removed.

14. **Dependencies**: maintained, no known vulns, reasonable size, license-compatible, not duplicating existing/platform. Lockfile matches manifest change: no unexpected major/transitive upgrades, no new install scripts.

15. **Tests**: logic components tested; changed user flows covered incl. error states + permission-restricted views.
