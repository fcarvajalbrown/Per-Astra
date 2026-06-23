# ADR-009: Push Notification Strategy

**Status:** Accepted
**Date:** 2026-06-23
**Depends on:** [[ADR-002-backend-and-data]]

---

## Decision

**Local notifications only, scheduled on-device. No push server in v1.**

---

## Implementation

`flutter_local_notifications` schedules a daily notification at the user's chosen time (default 20:00 local).

**"Only if the streak is at risk" (per PRD §5).** A local notification cannot evaluate app state at fire time, so the at-risk condition is enforced by scheduling, not by logic in the notification:
- A repeating daily notification is scheduled at the chosen time.
- On every lesson completion, the notifier **cancels today's pending notification** (the streak is already safe for today) and ensures tomorrow's is scheduled.
- On app open, if a lesson has already been completed today, today's notification is cancelled.
- Net effect: the reminder only fires on days where no lesson has been completed by the chosen time — i.e. when the streak is actually at risk.

Notification content:
- Title: "Your streak is waiting"
- Body: "You have a {N}-day streak. Keep it going — one lesson takes 5 minutes."

The notification time is stored in `user_profile.notification_hour` and `user_profile.notification_minute` (ADR-006).

iOS requires explicit permission request on first launch. Android 13+ requires `POST_NOTIFICATIONS` permission. Both handled via `permission_handler`.

---

## v2 Migration

When a backend exists in v2, migrate to FCM for reliability on Android battery-saver modes. Local notifications remain as a fallback.

---

## Packages

```yaml
dependencies:
  flutter_local_notifications: ^17.x
  permission_handler: ^11.x
  timezone: ^0.9.x  # required by flutter_local_notifications for local time scheduling
```
