## Focus: Web UI / frontend

Check in this priority order:

1. **Correctness**
   - React state bugs: stale closures, missing/wrong `useEffect` dependencies, effects without cleanup, state updates after unmount, derived state duplicated in state.
   - TypeScript: `any`, unsafe casts (`as`), non-null assertions (`!`) hiding real nulls.
   - Form handling: validation, double-submit, disabled states.
2. **Security**
   - XSS: `dangerouslySetInnerHTML`, unsanitized HTML/markdown, `href`/`src` built from user input (`javascript:` URLs).
   - Tokens or secrets stored in `localStorage` or bundled into client code; secrets in env vars exposed to the browser.
   - Client-only authorization checks with no server enforcement.
3. **UX states**: every data fetch handles loading, error, and empty states; optimistic updates roll back on failure.
4. **Accessibility**: interactive elements are real buttons/links, inputs have labels, images have `alt`, keyboard navigation and focus management work, sufficient color contrast.
5. **Performance**: unnecessary re-renders (new objects/functions passed as props to memoized children), large lists without virtualization, heavy imports that bloat the bundle, missing lazy loading for big routes.
6. **Responsive layout**: works at mobile widths; no fixed widths that overflow.
7. **API integration**: request/response types match the backend; errors from the API surface to the user.
8. **Tests**: components with logic have tests; user flows changed by the PR are covered.
