# ADR-015: v2 Authentication

**Status:** Accepted (Deferred — implement at v2 start)
**Date:** 2026-06-23
**Depends on:** [[ADR-003-authentication]], [[ADR-014-v2-backend]]

---

## Decision

**v2: GitHub OAuth as the sole login provider. Email/magic link as fallback. LinkedIn OAuth (OIDC sign-in only) added in v2.5 or v3 (separate LinkedIn Developer App approval required). Certification-to-profile is handled by the OAuth-free deep link in ADR-008, not by a LinkedIn API write.**

---

## GitHub OAuth (v2 launch)

Supabase Auth handles the GitHub OAuth flow natively. In Flutter:

```dart
await supabase.auth.signInWithOAuth(
  OAuthProvider.github,
  redirectTo: 'perastra://auth/callback',
);
```

On first login:
1. Supabase creates a user with `auth.users.id` (UUID).
2. App detects existing local UUID (ADR-003) and uploads local Drift data to Supabase with `user_id = auth.users.id` (ADR-018 migration flow).
3. Local Drift DB remains the primary data path; Supabase syncs in the background.

GitHub identity gives Per Astra access to the user's GitHub username and avatar, shown on their in-app profile. No GitHub repo access requested — `read:user` scope only.

---

## Email / Magic Link (v2 fallback)

For users without GitHub accounts (v2 non-technical track users). Supabase magic link:

```dart
await supabase.auth.signInWithOtp(email: userEmail);
```

No password storage. One-time link sent to email, valid for 1 hour.

---

## LinkedIn OAuth (v2.5 / v3) — sign-in only

**Correction (was factually wrong in the original draft):** `r_liteprofile` and `r_emailaddress` are **deprecated** — LinkedIn stopped issuing them to new apps as of 1 August 2023. New apps use the "Sign In with LinkedIn using OpenID Connect" product with OIDC scopes:

- `openid` — required for OIDC
- `profile` — read name, headline, profile picture
- `email` — read email for account matching

There is **no public LinkedIn API to write a certification to a member's profile.** `w_member_social` posts *shares to the feed*, not certification entries — it cannot add a structured certification. The original draft's "call LinkedIn Certifications API to add the certificate directly" step is not possible; remove it from scope.

What LinkedIn OAuth actually buys Per Astra: optional sign-in / account-matching for users who don't use GitHub, and pulling profile name/avatar. The structured **certification entry is added via the OAuth-free "Add to Profile" deep link** documented in ADR-008 (Path 1) — that path needs no Developer App approval at all.

LinkedIn OAuth login flow (optional, not required for sign-in):
1. OAuth with scopes `openid profile email`.
2. Match or create the Per Astra account by email.
3. Show name/avatar on the in-app profile. No feed post, no ongoing access stored.

**Action item before v2.5/v3:** register a LinkedIn Developer App and request the "Sign In with LinkedIn using OpenID Connect" product (review can take 2-4 weeks). This is only needed for OIDC *login* — the certificate-to-profile feature already works in v1 via the deep link.

---

## Consequences

**Positive:**
- GitHub OAuth is zero friction for the developer audience.
- Magic link email covers non-GitHub users without password management.
- Deferring LinkedIn OAuth avoids blocking v2 on a slow third-party approval process.

**Negative:**
- LinkedIn OIDC login for non-GitHub users waits until v2.5/v3 (Developer App approval).
- There is no automated certification-to-profile API; the ADR-008 "Add to Profile" deep link (one tap, pre-filled, no OAuth) is the v1+ touchpoint. Good enough and actually simpler than an API write — it just requires a Per Astra LinkedIn Company Page for the `organizationId`.
