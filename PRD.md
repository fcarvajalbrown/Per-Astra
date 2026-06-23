# Per Astra — Product Requirements Document
Version 0.1

---

## 1. Overview

Per Astra is a Duolingo-style mobile app that teaches developers how to use Claude and the Anthropic stack through interactive daily exercises, a gamified skill tree, and shareable certifications.

The name is drawn from "per aspera ad astra" — through hardship to the stars. Each lesson is a small challenge on the path to mastery.

---

## 2. Problem

Anthropic publishes free, high-quality course material on GitHub (anthropics/courses) and Anthropic Academy. The format is either static text/Jupyter notebooks or video. Neither format produces habit-forming daily practice. Prompt engineering and Claude-specific skills are best learned by doing repeatedly, not by watching or reading once. The existing free tools (Learn Prompting, Coddy) are not Claude-specific and have no gamification or retention loop.

---

## 3. Target Users

### v1 — Developer Track

Primary user: a developer who is new to Claude. They already code and may use other LLMs (GPT, Gemini). They want to go deeper on Claude-specific features: API patterns, prompt engineering, tool use, extended thinking, MCP. They are active on GitHub, X/Twitter, and LinkedIn. They value proof of skill they can share publicly.

### v2+ — Non-Technical Track

Business user who uses Claude for daily work: writing, document analysis, data processing. Broader audience but requires original content (no open-source source currently). Deferred to after v1 is validated.

---

## 4. Goals

1. Teach Claude and the Anthropic stack through 5-10 minute daily practice sessions.
2. Create a daily habit loop via streaks that brings learners back consistently.
3. Give learners a shareable credential (Per Astra certificate + LinkedIn badge) on module completion.
4. Build an open, community-extensible content library over time.

---

## 5. MVP Scope (v1)

### Content: Developer Track

Four module groups, gated by prerequisites in this order:

| Module | Topics |
|--------|--------|
| 1. Prompt Fundamentals | Prompt structure, clarity, XML tags for structure |
| 2. Role Prompting + Few-Shot | Role assignment, few-shot examples, format control |
| 3. Chain of Thought + Extended Thinking | Step-by-step reasoning, Claude's extended thinking feature |
| 4. API Integration + Tool Use | Calling the API, defining tools, handling tool use responses |

### Exercise Format

Each lesson unit has two parts:

**Micro-lesson (learn):** 2-4 multiple choice questions. Concept presented, then tested immediately. Wrong answers show an explanation. No penalty beyond one wrong attempt.

**Practice exercise (apply):** A prompt-writing challenge. The learner sees a task description and a target output specification. They write a prompt in a text input, then submit. The app reveals a vetted model-answer prompt and the learner self-evaluates against it (pass / try again). No live Claude grader in v1 — see ADR-002 for the rationale (fully local, no API key in a compiled open-source binary). A live grader (proxy in v2, BYOK in v4) is planned; see ADR-019.

### Gamification (v1)

- **Daily streak:** count of consecutive days the learner completed at least one lesson. Visible on the home screen header.
- **Streak freeze:** an item that prevents a streak from breaking on one missed day. Earned via achievements, never purchased.
- **XP points:** awarded per lesson completion. Accumulates to unlock levels.
- **Level progression:** numerical level shown on profile. No gameplay gate — purely a progress signal.
- **Module badges:** unlocked on completing every lesson in a module. Shareable image generated on unlock.
- **Per Astra Certificate:** unlocked on completing all four modules in the Developer Track. Includes learner name, date, and track name. Shareable as a PNG image in v1 (client-side render, ADR-008). PDF generation is deferred to the v4 Per Astra Academy phase.
- **LinkedIn integration:** on badge or certificate unlock, an OAuth-free "Add to Profile" deep link opens LinkedIn's add-certification flow prefilled with Per Astra's data (name, issue date, verify URL, cert id). Requires a Per Astra LinkedIn Company Page for the organization id (ADR-008). No LinkedIn API or OAuth needed in v1.

### Platform

Flutter app, iOS and Android simultaneously. No web version in v1.

### Business Model

Free and open source. No monetization in v1. Indirect value: personal brand, portfolio, community presence. Revisit monetization after user base exists and before v2 launch.

### Content Pipeline

1. Feed Anthropic's GitHub course chapters (anthropics/courses, Apache-licensed content) into Claude as source material.
2. Claude (Haiku or Sonnet) generates draft multiple choice questions and prompt-writing exercise specs.
3. Human review required before any exercise goes live. No unreviewed content ships.
4. Community submissions: deferred to v2.

---

## 6. Key User Stories

| As a developer | I want to | So that |
|---------------|-----------|---------|
| New to Claude | Complete one lesson in under 10 minutes on my phone | I can practice during commute or a short break |
| Learning to prompt | Write a real prompt, then compare it to a vetted model answer and self-rate | I learn by doing, not just reading |
| Building a habit | See my streak every day I open the app | I feel motivated to keep the chain going |
| Finished a module | Earn a badge I can share on LinkedIn | My progress is visible to my network |
| Starting out | See the full skill tree up front | I know what I am working toward |
| Missing a day | Use a streak freeze | I do not lose momentum from one missed day |
| Finished the track | Receive a Per Astra Certificate | I have a credential to attach to my portfolio |

---

## 7. Core Features

### Skill Tree (Home Screen)
- Full visual map of all four modules visible on first open.
- Module 1 unlocked by default. Modules 2-4 locked until the prior module is complete.
- Each module node shows: title, XP value, completion percentage.
- Tapping a locked module shows what must be completed first.

### Lesson Player
- Header: current streak count, XP total.
- Multiple choice screen: question text, four answer options, immediate visual feedback on tap. Correct = green + XP. Wrong = red + explanation.
- Write-a-prompt screen: task description, target output spec (visible to learner as a plain language description, not the exact string), text input area, Submit button.
- Self-evaluation (v1): on submit, the app reveals a vetted model-answer prompt and any hints. The learner compares their attempt and self-rates pass / try again. No network call. (A live Claude grader is planned for v2+ per ADR-019.)
- Lesson completion: XP awarded, streak updated, prompt to continue to next lesson or return to tree.

### Streak System
- Streak increments once per calendar day on lesson completion.
- Push notification at user-chosen time (default: 8:00 PM local) if streak is at risk.
- Streak freeze: consuming one prevents the streak from breaking for that day. Earned by specific achievements.

### Certification Flow
- Module badge: triggered automatically on final lesson in module. Badge image generated client-side with learner name + module title. Share sheet opens.
- Track certificate: triggered on final lesson in Module 4. PNG image generated client-side (PDF deferred to v4). LinkedIn "Add to Profile" deep link offered (OAuth-free, pre-fills a structured certification; requires a Per Astra LinkedIn Company Page — see ADR-008), plus an image+caption share fallback.

### Content Admin (internal)
- Script: takes a course chapter (markdown text), sends to Claude, receives draft exercises in structured JSON.
- Human review interface: simple local tool to approve, edit, or reject draft exercises before they enter the exercise database.

---

## 8. Out of Scope for v1

- Non-technical / business user track
- Community exercise submission
- Web or PWA version
- Leaderboards or social competition features
- Paid tier or any monetization
- Native Swift (iOS) or Kotlin (Android) — Flutter only
- Any backend at all in v1: no exercise grading service, no remote progress sync (fully local — ADR-002)
- Live AI grading of write-a-prompt (v1 uses offline self-evaluation against a model answer; a live grader is a v2+ item — ADR-019)

---

## 9. Success Metrics

| Metric | Target at 90 days post-launch |
|--------|-------------------------------|
| Total downloads | 1,000+ |
| Day 7 retention | 30%+ |
| Day 30 retention | 15%+ |
| Average streak length | 5+ days |
| Module completions | 200+ |
| LinkedIn shares | 50+ |

---

## 10. Open Questions

Most of the questions originally listed here have since been resolved in ADRs (the source of truth). Status:

- ~~Authentication: anonymous or account-required?~~ **Resolved:** anonymous + local UUID in v1; accounts in v2 (ADR-003, ADR-015).
- ~~Backend: Firebase vs Supabase vs serverless?~~ **Resolved:** no backend in v1; Supabase in v2 (ADR-002, ADR-014).
- ~~Grader reliability across model updates?~~ **Resolved for v1:** no live grader; self-evaluation against a vetted model answer (ADR-002). Reopens with the live grader in v2+ (ADR-019).
- ~~Certificate generation: client-side vs server-side?~~ **Resolved:** client-side PNG in v1; server-side PDF at v4 (ADR-008).
- Content versioning: process for updating exercises when Claude behavior changes between versions? **Still open** — v1 ships content via app release (ADR-005); a content-update mechanism is ADR-022 (v3).
- **Still open (new, raised by ADR-008):** how do offline, account-less v1 certificates become independently verifiable? Must be settled before the v1 certificate format is frozen.
