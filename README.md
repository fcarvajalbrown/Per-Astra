# Per Astra

A Duolingo-style mobile app that teaches developers how to use Claude and the Anthropic stack through interactive daily exercises, a gamified skill tree, and shareable certifications.

The name is drawn from *per aspera ad astra* — through hardship to the stars. Each lesson is a small challenge on the path to mastery.

## Status

v1 (Foundation) is in active development. See [`ROADMAP.md`](ROADMAP.md) and [`PRD.md`](PRD.md).

## Tech stack

- **Framework:** Flutter (iOS + Android)
- **State management:** Riverpod + flutter_hooks (ADR-001)
- **Persistence:** Drift / SQLite on-device, no backend in v1 (ADR-002)
- **Navigation:** go_router (ADR-004)
- **Content:** JSON assets bundled under `assets/content/` (ADR-005)

Architecture decisions live in [`docs/adr/`](docs/adr/); those files are the source of truth.

## Development

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generate Drift + Riverpod code
flutter test
flutter run
```

## License

TBD. A license has not yet been chosen for this project. Note that some lesson content is derived from Anthropic's Apache-2.0-licensed [courses](https://github.com/anthropics/courses); license selection should account for that.
