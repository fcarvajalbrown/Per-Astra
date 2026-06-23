# Per Astra — Roadmap
Version 0.1

Phases are sequential. Each builds on the validated output of the prior phase.

---

## v1 — Foundation
Target: 2-3 months of build

**Goal:** Ship a working Flutter app with the full Developer Track (4 modules, ~40 lessons), streak system, and LinkedIn-shareable certification. Open source from day one.

### Build
- [ ] Flutter project scaffold (iOS + Android targets)
- [ ] Skill tree home screen (4 modules, locked/unlocked states, XP display)
- [ ] Lesson player: multiple choice flow with immediate feedback
- [ ] Lesson player: write-a-prompt flow with model-answer self-evaluation (no live grader in v1)
- [ ] Streak counter (local, daily reset)
- [ ] Push notification for streak reminder
- [ ] XP + level system (local state)
- [ ] Streak freeze item (earned via achievement)
- [ ] Module badge generation + share sheet
- [ ] Per Astra Certificate generation (client-side PNG with embedded cert_id hash)
- [ ] LinkedIn share: pre-written post caption + image via OS share sheet (no OAuth)
- [ ] Content pipeline script: Anthropic course chapter -> Claude -> draft exercises (JSON)
- [ ] Human review tool (local CLI or simple UI) for approving exercise drafts

### Content
- [ ] Module 1: Prompt Fundamentals (~10 lessons, mix of MC + write-a-prompt)
- [ ] Module 2: Role Prompting + Few-Shot (~10 lessons)
- [ ] Module 3: Chain of Thought + Extended Thinking (~10 lessons)
- [ ] Module 4: API Integration + Tool Use (~10 lessons)
- [ ] All exercises human-reviewed before shipping

### Launch
- [ ] App Store Connect submission (iOS)
- [ ] Google Play submission (Android)
- [ ] GitHub repo published (open source)
- [ ] Launch post on X/Twitter, LinkedIn, Hacker News, Reddit r/ClaudeAI

---

## v2 — Community
Target: 3-6 months after v1 ships

**Goal:** Add cross-device accounts, the non-technical track, and the foundation for community content.

### Features
- [ ] User accounts (email or GitHub OAuth) for cross-device progress sync
- [ ] Non-technical / Business User Track (new skill tree, original content)
- [ ] Community exercise submission flow (submit -> review queue -> publish)
- [ ] Public GitHub content repo: anyone can open a PR to add or fix an exercise
- [ ] Leaderboard (weekly XP ranking, opt-in)
- [ ] Social: share current streak as an image

### Content
- [ ] Non-technical track: 4 modules, ~40 lessons (original content, not derived from developer-focused courses)
- [ ] First community-contributed exercises (curated from GitHub PRs)

---

## v3 — Depth
Target: 6-12 months after v1 ships

**Goal:** Expand to advanced topics and a web presence. Evaluate monetization.

### Features
- [ ] Advanced Developer Track: MCP deep dive, Claude Code skills, Prompt Evaluations
- [ ] Web version (Flutter Web or companion PWA)
- [ ] Group challenges / cohort mode (shared goal, team streak)
- [ ] Monetization decision point: premium track, remove ads if added, supporter tier

### Content
- [ ] MCP module (~10 lessons)
- [ ] Claude Code module (~10 lessons)
- [ ] Evaluations module (~10 lessons)

---

## v4 — Per Astra Academy
Target: after v3 is stable

**Goal:** Per Astra becomes a standalone free credentialing platform — a web academy where any track can be completed and its certificate independently verified.

### Features
- [ ] Webapp at perastra.app with full course browser and free track enrollment
- [ ] Certificate verification endpoint: perastra.app/verify/<cert_id>
- [ ] PDF certificate generator (Python or Dart script): inputs cert_id + display_name + badge_id + issued_at, outputs signed PDF with embedded QR code linking to verify URL
- [ ] Retroactive verification for v1 certificates **that have been synced to an account** (cert_ids are stored locally in the ADR-006/008 schema; they only become server-verifiable once uploaded via the v2 migration). Offline-only v1 certs that are never synced cannot be server-verified — see ADR-008 open question.
- [ ] LinkedIn "Add Certification" profile integration (structured credential, not just a post)
- [ ] Live Claude grader for write-a-prompt exercises — **BYOK variant** (user provides their own Anthropic API key). Note: a server-side **proxy** grader becomes possible earlier, once the v2 backend exists (Supabase Edge Functions, ADR-014); both variants are specified in ADR-019. v1 stays on self-evaluation (ADR-002).

### Why this matters
The `cert_id` designed in ADR-008 is the **stable lookup identifier** for this layer — it lets a certificate be looked up and displayed, and (where the underlying record exists) re-derived and matched. It is **not, on its own, tamper-proof**: the salt is public and the inputs are guessable, so the id identifies a certificate rather than cryptographically proving it. Genuine anti-forgery requires server-side registration of issued ids or a server-held signing key — see the open question in ADR-008. **Caveat for retroactive v1 verification:** v1 certs are issued fully offline with no account, so their records never reach a server unless the user later signs up in v2 and uploads. Whether v1-era certs can be brought into the verification DB depends on resolving the ADR-008 open question *before the v1 cert format is frozen*. Do not promise "all v1 certificates independently verifiable" until that is settled.

---

## Decisions to Revisit Before v2

| Decision | When to revisit |
|----------|----------------|
| Monetization model | After 90-day v1 metrics are in |
| Backend (Firebase vs Supabase) | Before building user accounts |
| Non-technical track content source | Before v2 content sprint starts |
| Community moderation process | Before opening community submissions |
