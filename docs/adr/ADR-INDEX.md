# Per Astra — ADR Index

All architecture decisions for Per Astra are documented here.
Status: Accepted | Proposed | Superseded | Deferred

---

Status values: **Accepted** (decision made, file written) | **Accepted — deferred to vN** (decided now, implemented in a later phase) | **Proposed** (drafted, not yet ratified) | **Planned** (placeholder; file not yet written — open when its phase begins). The individual ADR files are the source of truth; this column must match them.

## v1 — Foundation

| ADR | Title | Status |
|-----|-------|--------|
| ADR-001 | State Management (Riverpod) | Accepted |
| ADR-002 | Backend Architecture and Data Persistence | Accepted |
| ADR-003 | Authentication | Accepted |
| ADR-004 | Navigation and Routing (go_router) | Accepted |
| ADR-005 | Exercise Content Delivery Format (JSON assets) | Accepted |
| ADR-006 | Local Database Schema (Drift) | Accepted |
| ADR-007 | Gamification Logic (streak, XP, level, freeze) | Accepted |
| ADR-008 | Badge and Certificate Generation | Accepted |
| ADR-009 | Local Push Notification Strategy | Accepted |
| ADR-010 | App Design System and Theming | Accepted |
| ADR-011 | Content Pipeline Tooling | Accepted |
| ADR-012 | Testing Strategy | Accepted |
| ADR-013 | CI/CD Pipeline | Accepted |

---

## v2 — Community

| ADR | Title | Status |
|-----|-------|--------|
| ADR-014 | Backend Selection for v2 (accounts + sync) | Accepted — deferred to v2 |
| ADR-015 | Authentication for v2 (GitHub OAuth + OIDC) | Accepted — deferred to v2 |
| ADR-016 | Non-Technical Track Content Strategy | Proposed — deferred to v2 |
| ADR-017 | Community Exercise Submission Workflow | Accepted — deferred to v2 |
| ADR-018 | Local-to-Cloud Progress Migration | Planned |
| ADR-019 | Live Grader Architecture (v2 proxy / v4 BYOK) | Planned |

---

## v3 — Depth

| ADR | Title | Status |
|-----|-------|--------|
| ADR-020 | Web / PWA Strategy (Flutter Web vs companion) | Planned |
| ADR-021 | Monetization Implementation | Planned |
| ADR-022 | Content Update Mechanism (without app release) | Planned |
| ADR-023 | Group and Cohort Features Architecture | Planned |

---

## Notes

- ADRs marked Deferred are scoped to a future roadmap phase and should not be opened until that phase begins.
- When a Deferred ADR is opened, update its status to Proposed and write the file before implementing.
- If a decision from a prior ADR is reversed, mark the old ADR as Superseded and reference the new one.
