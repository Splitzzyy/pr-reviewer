## Focus: Backend / API service

Check in this priority order:

1. **Correctness**: logic errors, off-by-one, null/None handling, wrong status codes, timezone/date bugs, rounding of money (use decimal, never float).
2. **Security**
   - AuthN/AuthZ on every new endpoint; users must not access other users' or tenants' data (IDOR).
   - Input validation at the API boundary; mass-assignment / over-posting of DTOs.
   - SQL/ORM injection (raw queries, string-built SQL), command injection, path traversal, SSRF.
   - Secrets, keys, connection strings, or PII in code, config, or logs.
3. **Data & database**
   - Migrations: reversible, safe on large tables, no data loss, matching model changes.
   - N+1 queries, missing indexes for new filters/joins, unbounded queries without pagination.
   - Transactions: multi-step writes must be atomic; race conditions and concurrent updates.
4. **Error handling & resilience**: swallowed exceptions, missing timeouts/retries on external calls, leaking stack traces to clients, idempotency of retried operations.
5. **API contract**: breaking changes to request/response shape, renamed fields, changed enums, versioning; OpenAPI/docs updated.
6. **Async & resources**: blocking calls in async code (`.Result`, `.Wait()`), undisposed connections/streams, missing cancellation tokens.
7. **Logging & observability**: errors logged with context, no sensitive data in logs.
8. **Tests**: new logic has unit/integration tests covering the failure paths, not just the happy path.
