# ADR-005: Exercise Content Delivery Format

**Status:** Accepted
**Date:** 2026-06-23
**Depends on:** [[ADR-002-backend-and-data]]

---

## Context

Per Astra needs to store and deliver ~40 lessons (v1), each containing multiple choice questions and write-a-prompt exercises. Content must be:

- Available offline (ADR-002 mandates no network dependency at runtime).
- Human-readable in the GitHub repo so contributors can read, audit, and submit exercises via pull request.
- Parseable by the content pipeline script that generates draft exercises from Anthropic's course chapters.
- Easily loadable by the Flutter app at startup.

---

## Decision

**Exercise content is stored as JSON files in the Flutter app's assets directory, bundled at build time.**

Structure:

```
assets/
  content/
    modules.json          # module metadata: id, title, description, prerequisites
    lessons/
      m1-l1.json          # one file per lesson
      m1-l2.json
      ...
```

Each lesson file schema:

```json
{
  "id": "m1-l1",
  "moduleId": "m1",
  "title": "Prompt Structure Basics",
  "xpValue": 20,
  "steps": [
    {
      "type": "multiple_choice",
      "question": "Which of these prompts is more likely to get a structured response?",
      "options": ["...", "...", "...", "..."],
      "correctIndex": 2,
      "explanation": "..."
    },
    {
      "type": "write_prompt",
      "task": "Write a prompt that asks Claude to summarize a document in exactly three bullet points.",
      "modelAnswer": "Please summarize the following document in exactly three bullet points, each starting with a dash:\n\n[document]",
      "hints": ["Think about format constraints", "Be explicit about the number"]
    }
  ]
}
```

---

## Rationale

- **Human-readable:** JSON files are diffable in GitHub. Contributors can submit exercises as PRs. Content reviewers can read and edit without tooling.
- **Offline:** Bundled assets need no network. Available on first launch, before any network request.
- **Content pipeline compatibility:** The script that generates draft exercises from Anthropic course chapters outputs JSON naturally. Review step edits JSON directly.
- **Flutter-native:** `rootBundle.loadString('assets/content/lessons/m1-l1.json')` is standard Flutter.
- **Simple:** ~40 files of a few KB each. No need for a local DB for this data volume.

---

## Consequences

**Positive:**
- Full offline operation from first launch.
- Exercise content visible and auditable in the open-source repo.
- Zero infrastructure to maintain content delivery.
- Content pipeline outputs directly match the bundle format.

**Negative:**
- Content updates require an app release (iOS App Store review + Google Play review). For typo fixes, this is slow. Acceptable for v1.
- As content grows past a few hundred lessons (v3+), loading all JSON at startup may need lazy loading by module. Not a v1 concern.

---

## Content Update Strategy (v2 consideration)

In v2, consider adding a lightweight content manifest check: on app launch, compare a remote `manifest.json` version number against the bundled version. If newer, download only changed lesson JSON files to a local cache directory. This allows content-only updates without a full app release.

---

## Packages

No new packages required. Uses Flutter's built-in `rootBundle` and `dart:convert`.

```dart
final raw = await rootBundle.loadString('assets/content/lessons/m1-l1.json');
final lesson = Lesson.fromJson(jsonDecode(raw));
```
