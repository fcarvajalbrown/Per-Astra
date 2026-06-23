# ADR-001: Flutter State Management

**Status:** Accepted
**Date:** 2026-06-23

---

## Context

Per Astra needs to manage several distinct state layers:

- **Lesson player state** — current question index, selected answer, grader result, XP earned this session. Ephemeral; lives only during a lesson.
- **Persistent global state** — streak count, total XP, level, completed lesson IDs, streak freeze inventory. Must survive app restarts.
- **Async state** — Claude API grader calls that can be in-flight, resolved, or failed. Needs clean loading/error/data representation in the UI.
- **Skill tree state** — derived from completed lessons; which modules are locked or unlocked. Computed, not stored directly.

The choice of state management approach affects how all features are built and how testable they are. A wrong choice early is expensive to reverse.

---

## Decision

**Use Riverpod (flutter_riverpod + riverpod_annotation) as the primary state management solution, paired with flutter_hooks for ephemeral local widget state.**

---

## Rationale

Riverpod is the clear choice for a new Flutter project of this complexity for the following reasons:

1. **Async state is a first-class citizen.** The `AsyncValue<T>` type handles loading, data, and error states without any boilerplate. Every Claude grader call maps directly to this pattern.
2. **No BuildContext dependency for reads.** Providers are read via `ref`, not via `context`. This makes business logic testable without widget trees.
3. **Type safety.** `@riverpod` annotation + code generation catches provider dependency mismatches at compile time, not runtime.
4. **Computed/derived state is easy.** The skill tree lock state is derived from completed lesson IDs. Riverpod's provider composition handles this without manual cache invalidation.
5. **Community standard.** As of 2025-2026, Riverpod is the dominant choice for new Flutter projects. Documentation, packages, and community answers assume it.

---

## Consequences

**Positive:**
- Async Claude API calls are handled with minimal boilerplate via `AsyncValue`.
- State is easily testable via `ProviderContainer` in unit tests without a widget.
- Derived state (skill tree locks) updates automatically when its dependencies change.
- `flutter_hooks` handles ephemeral widget state (animation controllers, focus nodes) without polluting global providers.

**Negative:**
- Requires code generation step (`dart run build_runner watch`) as part of the dev workflow.
- Slightly steeper learning curve than Provider for developers who are new to it.
- Adds `flutter_riverpod`, `riverpod_annotation`, `flutter_hooks`, `hooks_riverpod` as dependencies.

---

## Alternatives Considered

| Option | Reason not chosen |
|--------|------------------|
| Bloc/Cubit | Excessive boilerplate for a solo project. Events + states + blocs triple the file count for no benefit when there is one developer. |
| Provider | Replaced by Riverpod by the same author. Lacks type safety and async primitives. No reason to choose it for a new project. |
| GetX | Couples state, routing, and DI in one opinionated package. Harder to test. Community opinion on it is mixed and it is not recommended for projects that need to remain maintainable over time. |

---

## Packages

```yaml
dependencies:
  hooks_riverpod: ^3.3.2      # re-exports flutter_riverpod — do not also list flutter_riverpod
  riverpod_annotation: ^4.0.3
  flutter_hooks: ^0.21.3+1

dev_dependencies:
  riverpod_generator: ^4.0.4
  build_runner: ^2.15.0
```

Notes:
- `hooks_riverpod` re-exports `flutter_riverpod`, so listing both is redundant. Depend on `hooks_riverpod` only.
- **Riverpod major version (amended 2026-06-23):** v1 originally pinned `^2.x` for stability. At scaffold time this proved unworkable: Riverpod 2.x's `riverpod_generator` requires `source_gen ^2.0.0`, while the current `drift_dev` (ADR-006) requires `source_gen >=3.0.0`, and `drift_dev` has no release on `source_gen` 2.x (it jumps 1.x → 3.x). The two codegen toolchains therefore cannot coexist on the Flutter 3.44 / Dart 3.12 SDK. Because no Riverpod code had been written yet, the migration cost of choosing 3.x was zero, and 3.x is the line that is actually compatible with the rest of the modern stack — so the original stability rationale for 2.x no longer held. **Decision: adopt Riverpod 3.x.** We use the codegen `Notifier`/`AsyncNotifier` classes throughout — never the legacy `StateNotifier`, which 3.0 demotes to a `legacy.dart` import. `riverpod_lint`/`custom_lint` are deferred for now: their latest releases pull in an `analyzer`/`macros` version that does not resolve on this SDK. Re-add them once a compatible release lands.
