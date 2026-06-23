# ADR-003: Authentication

**Status:** Accepted
**Date:** 2026-06-23
**Depends on:** [[ADR-002-backend-and-data]]

---

## Context

Per Astra v1 is fully local with no backend (see ADR-002). Authentication requires a server to issue and validate credentials. With no server, no authentication system is possible or needed.

The only identity-related question is whether to generate a stable local device ID for future use.

---

## Decision

**No authentication in v1.**

A random UUID is generated on first app launch and stored in the device's secure keychain (flutter_secure_storage). This UUID is never sent anywhere in v1 but serves as a stable local identifier for future account migration.

---

## Consequences

**Positive:**
- Zero auth complexity. No sign-in screen, no token refresh, no session expiry.
- No friction for first-time users — the app opens directly to the skill tree.

**Negative:**
- Progress is tied to the device. Uninstall = lost progress.
- No way to identify a returning user across devices or reinstalls in v1.

---

## v2 Plan

When user accounts are introduced in v2, the local UUID becomes the migration key: the user's first login links their account to the UUID and uploads local progress.

---

## Packages

```yaml
dependencies:
  flutter_secure_storage: ^9.x  # keychain storage for the local UUID
```
