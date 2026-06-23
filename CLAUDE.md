# Project: Per Astra — Duolingo-style Claude learning app

## Legal

**Not a lawyer — never give legal advice** — I am an AI assistant, not a legal professional. Never give legal advice, legal opinions, or legal interpretations of any kind. If a question touches on IP, licensing, trademarks, contracts, liability, or any other legal matter, I must decline to advise and tell the user to consult a qualified lawyer.

## Style rules (inherited from global CLAUDE.md)

- **No emojis anywhere** — not in code, comments, docs, commit messages, or chat responses.
- **No AI attribution** — never add Co-Authored-By or "Generated with Claude" to commits, PRs, or docs.
- **Never invent facts** — if content, metrics, or quotes are needed and not confirmed, ask first.
- **Present choices as interactive options, not plain-text lists** — when offering the user a decision between alternatives, use the arrow-selectable question UI (the blue option selector) instead of listing options as text. Use it for every decision, no matter how many questions are involved. The UI caps at 4 questions per call, so for longer sets chain multiple sequential calls (e.g. 4 + 4 + 2 for a 10-question set) rather than dropping to text. Only fall back to a plain-text list if that interactive UI is genuinely unavailable in the current context.
- **Always mark exactly one option as (Recommended)** — append "(Recommended)" to the label of the single best option and make it the first option. No exceptions, even when the choice feels close. State the WHY of the recommendation, either in that option's description or in the prose immediately before/after the question, so the user sees not just which one I'd pick but why.

## Tech stack (locked via ADRs)

- **Framework:** Flutter (iOS + Android)
- **State management:** Riverpod + flutter_hooks (ADR-001)
- **Persistence:** Drift / SQLite on-device, no cloud backend in v1 (ADR-002)
- **Auth:** None in v1; local UUID in secure keychain for v2 migration (ADR-003)
- **Navigation:** go_router (ADR-004)
- **Content format:** JSON assets bundled in app under assets/content/ (ADR-005)

## Architecture process

All architecture decisions are documented as individual ADR files in docs/adr/.
Before implementing any significant technical choice, write or reference the relevant ADR.
ADR files are the source of truth for why a technical decision was made.

## Commits and version control

- **Conventional Commits** — every commit message follows `type(scope): subject`, where `type` is one of `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `build`, `ci`, `perf`, `style`. Scope is optional (e.g. `feat(lesson-player): ...`). Subject is imperative, lower-case, no trailing period.
- **One logical change per commit** — commit after each logical, self-contained change rather than batching unrelated work. Each commit should leave the project in a buildable state.
- Inherited: no AI attribution in commit messages (no `Co-Authored-By`, no "Generated with Claude"); no emojis.
