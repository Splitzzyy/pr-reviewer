## Focus: Backend / API

Any stack (.NET/EF Core, Node/Prisma/TypeORM/Sequelize, Python/Django/SQLAlchemy, Java/Hibernate, Go). Apply checks fitting diff's stack. Each new/changed endpoint: trace route → middleware/filters → handler → service → data access → response.

Reference checklist, priority order. Apply only items relevant to diff:

1. **Architecture**
   - Thin controllers (parse, authorize, delegate); business rules in services/domain; data access in repositories.
   - No persistence entities in API contracts; DTOs mapped at boundary.
   - DI lifetimes: no scoped/transient captured by singleton (e.g. `DbContext` in singleton).
   - Transaction/consistency boundaries explicit; cross-service/aggregate work uses repo's pattern (outbox, events, jobs), not ad-hoc calls.
   - Stateless services: no in-memory cache/lock/session assuming single instance.
   - API consistent with existing endpoints: naming, verbs, pagination, filtering, one error format.
   - New schema: sane normalization, ownership, FKs; fits future queries without rewrite.

2. **Authentication**
   - Every new endpoint authenticated unless intentionally public: watch `[AllowAnonymous]`, missing auth middleware/decorators, routes outside protected group.
   - JWT: signature, issuer, audience, expiry validated; no `alg: none`/algorithm confusion; short-lived access tokens; refresh tokens rotated, revocable, stored hashed; logout/password change invalidates sessions.
   - Email/username uniqueness case-insensitive + Unicode-normalized, unique index on normalized value (`Bob@x.com` and `bob@x.com` = same account).
   - Brute force: lockout/backoff after failed logins; 2FA not skippable by calling post-2FA step directly.
   - Passwords: bcrypt/scrypt/Argon2/PBKDF2; never plain/MD5/SHA-*; never in logs, URLs, responses.
   - Reset/verify/invite/OTP codes: CSPRNG, single-use, short expiry, rate-limited, constant-time compare.
   - No account enumeration: login/signup/reset same response + similar timing whether user exists or not.
   - Cookie auth: `HttpOnly`, `Secure`, `SameSite`, CSRF protection on state-changing requests.
   - OAuth: `state`/PKCE validated, redirect URIs allow-listed, provider token verified server-side.

3. **Authorization**
   - IDOR: every read/update/delete by ID checks caller owns it or belongs to its group/tenant. Scope query itself (`WHERE id = @id AND owner_id = @userId`).
   - Role-restricted actions enforced server-side.
   - Identity from authenticated principal (claims), never user/role/tenant ID in body, query, header.
   - Mass assignment: DTOs can't set `role`, `isAdmin`, `ownerId`, `balance`, `status`, other server-controlled fields.
   - List/bulk endpoints filter by access; nested resources (`/groups/{g}/expenses/{e}`) verify `e` belongs to `g`.
   - Same scoping in background jobs, scheduled tasks, admin tools, exports.
   - State transitions validated server-side; can't skip steps or replay (settle expense twice, edit settled one).
   - Privilege changes (invite, role change, ownership transfer) can't exceed caller's own rights.

4. **Injection & input**
   - No concatenated/interpolated SQL (`FromSqlRaw`, `raw()`, `$queryRawUnsafe`, `execute(f"...")`); dynamic `ORDER BY`/columns allow-listed.
   - Command injection, path traversal, SSRF (block internal/metadata addresses), XXE, unsafe deserialization, template injection, open redirect, NoSQL/LDAP injection, header/log injection.
   - ReDoS (user input as regex or catastrophic-backtracking regex), zip/decompression bombs, Node prototype pollution (deep-merge/`Object.assign` of request bodies).
   - Boundary validation: types, ranges, lengths, formats, enums, max collection size, max body size; reject negative/zero amounts where invalid.
   - Uploads: size limit, content-type + extension check, stored outside web root/object storage with random names, never executed, scanned if repo does. Downloads: short-lived signed URLs, correct `Content-Type`/`Content-Disposition`.
   - Output: user content in HTML emails/server-rendered pages encoded; errors don't leak stack traces, SQL, paths, framework versions.

5. **Secrets, crypto, data protection**
   - No secrets/keys/connection strings/tokens in code, committed config, fixtures, logs; load from env/secret store.
   - No home-grown crypto, ECB, static IVs, `Math.random`/`Random` for security; TLS verification never disabled.
   - PII/financial data: collect only when needed, never logged, not returned where unneeded (no full user objects with hashes or others' emails), masked on display.
   - Debug endpoints, Swagger UI, actuator/health-detail, detailed error pages off or protected in prod.
   - Audit trail for financial/permission changes (who, what, when, old/new) where repo has one; new personal-data tables covered by account deletion + export.
   - CORS not `*` with credentials; security headers kept; webhooks verify signature.
   - Rate limits on login, signup, OTP, reset, invites, other abusable/expensive endpoints.

6. **Correctness**: logic errors, off-by-one, null handling, wrong status codes, timezone bugs (store UTC); money as decimal/integer minor units, never float; splits sum exactly to total with defined rounding rule; currency explicit, conversions store rate + timestamp used; decimal precision/scale match DB column; integer overflow on counters/amounts; pagination stable sort with unique tie-breaker (`created_at, id`), cursor-based for changing feeds.

7. **DB performance**
   - **N+1**: query or lazy-loaded navigation inside loop/`map`/`foreach`/serializer/per-item resolver (e.g. `order.Items` per row, repo call per ID). Fix: eager load (`Include`/`select_related`/`prefetch_related`/`joinedload`/`include:`), one `WHERE id IN (...)`, projection, DataLoader.
   - Over-fetching: full entities/`SELECT *` for few columns; unused related graphs; missing `AsNoTracking` (or equivalent) on read-only queries.
   - Unbounded: lists without pagination/max page size; `ToList()`/`.all()` before filtering (in-memory filter); `.ToList().Count` instead of `COUNT`.
   - Missing indexes on new `WHERE`/`JOIN`/`ORDER BY`/FK columns; index-defeating queries (fn on column, leading-wildcard `LIKE`).
   - Cartesian explosion from multiple collection `Include`s (split queries).
   - Chatty: multiple round trips that could be one; writes in loop instead of batch/bulk.

8. **Data integrity & concurrency**
   - Migrations: reversible, safe on big tables (no long locks; nullable → backfill → constrain), no data loss, match model. Rolling deploy: old + new code run together against same schema and queue messages; both must work.
   - Multi-step writes in one transaction; no HTTP/email/queue calls inside DB transaction unless outbox.
   - Races: check-then-act (exists-then-insert, read-balance-then-update) without unique constraint, row lock, or concurrency token; double-submit duplicates.
   - Invariants in DB (unique, FK, check, NOT NULL), not only code.
   - Removing user/member with outstanding balances or owned resources handled explicitly (block, settle, reassign).
   - Soft-deleted rows excluded; cascades don't delete too much.

9. **Errors & resilience**
   - Swallowed exceptions, catch-alls hiding failures, missing timeouts/backoff retries on external calls, retries on non-idempotent ops, idempotency keys for payments/webhooks/retried requests, jobs safe to run twice, partial failure leaving inconsistent state.
   - Timeouts on DB queries too; respect pool limits (no connection held across slow external calls).
   - Health/readiness reflect real dependencies; graceful shutdown drains requests + jobs.
   - Queues/events (if used): idempotent consumers (at-least-once), backoff retries + DLQ for poison messages, versioned schemas tolerating unknown fields, explicit ordering assumptions.

10. **API contract**: breaking shape changes, renamed/removed fields, changed enums/defaults/nullability/status codes; versioning; OpenAPI/docs updated; existing web + mobile clients (incl. old app versions) keep working.

11. **Async & resources**: blocking in async (`.Result`, `.Wait()`, sync I/O), `async void`, unhandled fire-and-forget, undisposed connections/streams, `HttpClient` per request, missing cancellation tokens, unbounded parallelism/in-memory queues, big payloads buffered instead of streamed.

12. **Caching & config**: stale cache after writes; cache keys missing user/tenant; sensitive data cached; new config/flags with safe defaults; env-specific values hard-coded.

13. **Dependencies**: maintained, no known vulns, license-compatible, not duplicating existing. Lockfile matches manifest change: no unexpected major/transitive upgrades, no new install scripts.

14. **Logging**: errors logged with context + correlation ID; security events (failed logins, permission denials) logged; no passwords/tokens/PII; no noisy logs in hot paths.

15. **Tests**: new logic tested incl. failure + authz paths (other user's ID → 403/404, unauthenticated → 401); data-access changes tested against real/realistic DB, not only mocks.
