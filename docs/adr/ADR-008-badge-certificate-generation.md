# ADR-008: Badge and Certificate Generation

**Status:** Accepted
**Date:** 2026-06-23
**Depends on:** [[ADR-002-backend-and-data]], [[ADR-006-local-database-schema]], [[ADR-007-gamification-logic]]

---

## Context

Per Astra awards two types of credentials:

- **Module badges:** unlocked on completing all lessons in a module.
- **Track certificate (Per Astra Developer Certificate):** unlocked on completing all four v1 modules.

The certificate must be:
1. Shareable as a PNG image.
2. Accompanied by a pre-written LinkedIn post caption.
3. Designed so that a future verification system can confirm its authenticity without a backend in v1.

---

## Decision

**v1: Certificate generated client-side as a PNG using Flutter's Canvas / screenshot-widget approach. A unique certificate ID (UUID + HMAC-style fingerprint) is embedded in the image and stored locally. LinkedIn share uses pre-written post text + image copied to clipboard + LinkedIn deep link. No OAuth.**

**v2+: A standalone Per Astra Academy verification webapp reads certificate IDs and confirms authenticity. A companion Python or Dart script generates print-quality PDFs from the same certificate data.**

---

## Certificate ID and Verification Design

Every certificate issued gets a `certificate_id` composed of:

```
cert_id = BASE58( SHA256( "v1" | user_uuid | badge_id | completed_at_ms | SALT ) )
// fields joined with a delimiter ("|") so the concatenation is unambiguous
```

Where `SALT` is a hardcoded constant in the app source (open source, so not secret — the verification in v1 is identification, not cryptographic proof). The fields are joined with an explicit delimiter so that, e.g., `badge_id="m1" + ts="0..."` cannot collide with a different field split.

### OPEN QUESTION — how do v1 certs become verifiable? (must resolve before v1 cert format is frozen)

This `cert_id` is **not independently verifiable by a third party for v1-issued certificates**, and the design must own that before the format ships:

- v1 is fully local with no backend and no account (ADR-002/003). The cert inputs (`user_uuid`, `badge_id`, `completed_at_ms`) never leave the device, so `perastra.app/verify/<cert_id>` has no record to look up. A user who earns a cert in v1 and never creates a v2 account can never have it verified.
- The `SALT` is public (open source) and the inputs are guessable (display name, a small set of badge IDs, a plausible timestamp), so anyone can compute a plausible `cert_id`. This is a **lookup identifier, not a tamper-proof credential.**

Genuine verification requires one of: (a) the app registering each issued `cert_id` to a server at issue time — needs network + backend, contradicting v1-local; (b) a server-held private signing key — cannot live in an open-source client. **Decision needed now:** does the v1 cert PNG need to embed any additional field (e.g. a self-contained payload the future verifier can re-derive from, or a slot for a later server signature) so that v1-era certs can be retroactively brought into the v2/v4 verification DB? If we freeze the format without deciding, retroactive verification of v1 certs (promised in ROADMAP v4) may be impossible. Track resolution in ADR-019 / the Academy ADR.

The certificate PNG embeds:
- Learner's display name (from `user_profile.display_name`)
- Badge name and date
- The `cert_id` as a short alphanumeric string
- A placeholder URL: `perastra.app/verify/<cert_id>` (resolves in v2)

The `certificates` table is added to the Drift schema (addendum to ADR-006):

| Column | Type | Notes |
|--------|------|-------|
| `cert_id` | TEXT PRIMARY KEY | Derived hash |
| `badge_id` | TEXT NOT NULL | References badges table |
| `display_name` | TEXT NOT NULL | Snapshot of name at time of issue |
| `issued_at` | INTEGER NOT NULL | Unix timestamp ms |
| `shared_linkedin` | INTEGER DEFAULT 0 | 1 = shared |

---

## v1 Generation Flow

1. `BadgeNotifier` detects track completion, writes badge row, triggers certificate generation.
2. `CertificateService` computes `cert_id`, writes `certificates` row, renders certificate widget off-screen.
3. Flutter `RepaintBoundary` + `RenderRepaintBoundary.toImage()` captures the widget as a PNG.
4. PNG saved to app documents directory.
5. Certificate unlock screen shown with Share button.

---

## LinkedIn Share (v1)

Two complementary paths are offered on the certificate screen. Both are OAuth-free.

**Path 1 — Add to LinkedIn profile (structured certification, no OAuth).**
LinkedIn's public "Add to Profile" deep link adds a structured certification entry without any API write or OAuth flow:

```
https://www.linkedin.com/profile/add?startTask=CERTIFICATION_NAME
  &name=Per%20Astra%20Developer%20Certificate
  &organizationId=<PER_ASTRA_LINKEDIN_ORG_ID>
  &issueYear=2026&issueMonth=6
  &certUrl=https://perastra.app/verify/<cert_id>
  &certId=<cert_id>
```

This is the mechanism the PRD originally intended ("Add Certification flow prefilled"). It requires **one prerequisite: a Per Astra LinkedIn Company/Organization Page**, whose numeric `organizationId` is hardcoded into the link. Without an org ID the entry shows as free text rather than a linked organization. Note: when the user completes the flow, LinkedIn also posts an update to their feed. There is no public LinkedIn API to write a certification programmatically — this deep link is the supported path, and it needs no OAuth or LinkedIn Developer App approval (that approval is a v2.5/v3 concern only, see ADR-015).

**Path 2 — Share image + caption (fallback / richer post).**
1. Pre-written caption copied to clipboard:
   ```
   I just earned the Per Astra Developer Certificate — a hands-on credential
   for building with the Claude API and the Anthropic stack.

   Completed modules: Prompt Engineering, Role Prompting, Chain of Thought,
   API + Tool Use.

   Verify: perastra.app/verify/<cert_id>

   #Claude #AI #PromptEngineering #PerAstra
   ```
2. Certificate PNG shared via `share_plus` (OS share sheet, user picks LinkedIn or saves image).

After either path, `certificates.shared_linkedin` is updated to 1 in DB.

---

## v2+ Roadmap Implications

This ADR implies a future **Per Astra Academy** platform:

- A webapp at `perastra.app` that:
  - Lists all available tracks and certificates.
  - Has a `/verify/<cert_id>` endpoint that looks up and confirms a certificate.
  - Eventually hosts the non-developer tracks as a free web course.
- A Python (or Dart) script that takes certificate DB data and generates a print-quality signed PDF:
  - Inputs: `cert_id`, `display_name`, `badge_id`, `issued_at`
  - Output: PDF with embedded QR code linking to the verify URL
  - Designed for v2 when the verification backend exists

These items are tracked in the roadmap under **v4 (Per Astra Academy)**.

---

## Packages

```yaml
dependencies:
  share_plus: ^9.x         # OS share sheet for image + text
  path_provider: ^2.x      # save PNG to app documents directory
  crypto: ^3.x             # SHA256 for cert_id derivation
```

Certificate rendering uses Flutter's built-in `Canvas` and `RepaintBoundary` — no additional package needed.
