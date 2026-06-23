# ADR-004: Flutter Navigation and Routing

**Status:** Accepted
**Date:** 2026-06-23
**Depends on:** [[ADR-001-state-management]]

---

## Context

Per Astra has the following screen hierarchy:

```
Skill Tree (home)
  └── Module Detail
        └── Lesson Player
              └── Lesson Completion
                        └── Badge / Certificate Unlock
Settings
  └── Notification Time Picker
```

Requirements:
- Deep linking from the LinkedIn certification flow back into the app.
- Nested navigation (lesson player has its own internal step flow).
- Clear route definitions readable by contributors.

---

## Decision

**Use go_router for all navigation.**

---

## Rationale

- go_router is Google's official routing solution and the current community default for new Flutter apps.
- Its declarative URL-based model handles the skill tree → module → lesson → completion screen flow cleanly.
- Deep link support is built in, which is needed for the LinkedIn certification callback.
- Shell routes handle the persistent bottom navigation bar (if added in v2) without custom logic.
- ShellRoute allows the lesson player's internal step state (managed by Riverpod) to persist across micro-steps without rebuilding the entire route.

---

## Consequences

**Positive:**
- URL-based navigation makes the route tree explicit and readable.
- Deep links for certification flow require no additional package.
- Community documentation and examples are abundant.

**Negative:**
- Declarative router adds a small layer of indirection vs imperative `Navigator.push`. Team members unfamiliar with go_router need a short ramp-up.
- Nested navigation within the lesson player (MC step → write-a-prompt step) is handled by Riverpod state rather than router state, keeping the router simpler.

---

## Route Map (initial)

| Path | Screen |
|------|--------|
| `/` | Skill Tree (home) |
| `/module/:moduleId` | Module Detail |
| `/module/:moduleId/lesson/:lessonId` | Lesson Player |
| `/lesson-complete` | Lesson Completion |
| `/badge/:badgeId` | Badge Unlock |
| `/certificate` | Track Certificate |
| `/settings` | Settings |

---

## Packages

```yaml
dependencies:
  go_router: ^14.x
```
