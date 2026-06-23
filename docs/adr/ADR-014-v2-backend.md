# ADR-014: v2 Backend (Accounts and Progress Sync)

**Status:** Accepted (Deferred — implement at v2 start)
**Date:** 2026-06-23
**Depends on:** [[ADR-002-backend-and-data]], [[ADR-006-local-database-schema]]

---

## Decision

**Supabase as the v2 backend: PostgreSQL for data, Supabase Auth for authentication, Edge Functions for any server-side logic (live grader proxy in v2+).**

---

## Rationale

- PostgreSQL matches the Drift schema from ADR-006 column-for-column. Migration is a direct INSERT from local rows to remote rows.
- Supabase is open-source and self-hostable, aligning with Per Astra's open-source identity.
- Supabase Auth supports GitHub OAuth and email/magic link out of the box (relevant to ADR-015).
- The free tier (500MB DB, 50k monthly active users) covers Per Astra through v2 launch comfortably.
- Flutter has a first-class `supabase_flutter` SDK.

---

## Data Architecture in v2

Same table schema as ADR-006, lifted to Supabase PostgreSQL. Foreign key: `user_id` (Supabase Auth UUID) on all tables.

Local Drift DB remains the primary read/write path. Supabase is a sync layer:
- On lesson completion: write to Drift, then async upsert to Supabase (fire and forget).
- On login on a new device: pull Supabase rows, write to Drift.
- Conflict resolution: `completed_at` timestamp wins (most recent completion kept).

---

## Consequences

**Positive:**
- v1 Drift schema requires no changes — just add a `user_id` foreign key column during migration.
- Open-source contributors can self-host the backend for their own deployments.
- Edge Functions handle the live grader proxy in v2 without a separate server (grader architecture specified in ADR-019; v2 = proxy, v4 = BYOK).

**Negative:**
- Supabase free tier has row limits; exceeding them requires a paid plan.
- Requires Supabase project setup before v2 development begins.
