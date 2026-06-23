# ADR-010: App Design System and Theming

**Status:** Accepted
**Date:** 2026-06-23

---

## Decision

**Custom ThemeData over Flutter Material 3. No third-party component library.**

---

## Rationale

Per Astra needs animated elements (streak counter, XP bar fill, badge unlock) that third-party UI kits constrain. Material 3 provides the baseline; a custom theme overrides color, typography, and shape without fighting an external library.

---

## Theme Tokens (initial, to be refined in design phase)

```dart
// Palette — space / star aesthetic matching the "Per Astra" name
const colorPrimary    = Color(0xFF6C63FF); // indigo-violet
const colorSecondary  = Color(0xFFFFD166); // gold (XP, stars)
const colorBackground = Color(0xFF0D0D1A); // deep space dark
const colorSurface    = Color(0xFF1A1A2E); // card background
const colorSuccess    = Color(0xFF06D6A0); // correct answer, pass
const colorError      = Color(0xFFEF476F); // wrong answer
const colorText       = Color(0xFFF0F0F5); // primary text on dark

// Typography — system fonts only for v1, no custom font download
// Heading: MaterialTheme headline / display styles
// Body: MaterialTheme body styles
// Monospace: for prompt-writing exercise input

// Shape — rounded corners throughout, 12px default radius
```

Dark mode only in v1. Light mode deferred to v2 based on user feedback.

---

## Animation Standards

- XP bar fill: `AnimatedContainer` on lesson completion, 400ms ease-out.
- Streak counter increment: `AnimatedSwitcher` with slide-up transition.
- Badge unlock: full-screen overlay with scale + fade, dismissible.
- Correct answer flash: `ColorTween` on the option tile, 200ms.

All animations use Flutter's built-in animation system. No animation library added.

---

## Consequences

- Design updates require code changes (no token-file-driven theming system).
- Contributors must follow the token constants — defined in `lib/theme/app_theme.dart`.
- Light mode is an explicit non-goal for v1, documented here so it is not accidentally implemented.
