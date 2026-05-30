# Exclusive Gallery + Additional Animations — Design

**Date:** 2026-05-16
**Project:** Personal-Landing-Page (keithlinks.netlify.app)
**Status:** Approved by user, ready for implementation planning

## Goals

1. Add an "Exclusive Content" teaser gallery below the social-links section. Tiles look like locked paid content; clicking sends visitors to OnlyFans to subscribe and view the real content there.
2. Enable the site owner to add, edit, and remove tiles without editing code, via Decap CMS at `/admin`.
3. Add four new animations to enrich the page feel: animated gradient on the wordmark, scroll-triggered reveals, cursor-following spotlight on the card, locked-tile micro-interactions on hover.

## Non-Goals (explicit)

- **No real paywall.** No payment processing, no per-user access control, no DRM on this site. All actual paid content lives on OnlyFans, which is already linked. The gallery is a visual upsell that funnels traffic to OF.
- No video players, no lightbox modals — tiles are click-out only.
- No new pages — everything stays single-page.

## Page layout (after change)

```
[ animated mesh background ]
   ┌──────────────────────────────┐
   │  avatar with LIVE pill       │
   │  Keith (animated gradient)   │
   │  tagline                     │
   │  ── social buttons ──        │ (Chaturbate / X / IG / OF — unchanged)
   │  ── EXCLUSIVE ──             │  new divider + section heading
   │  short tease copy line       │
   │  ┌──────┬──────┐             │  2×2 grid of teaser tiles
   │  │ 🔒   │ 🔒   │             │  (collapses to 1-col below 480px)
   │  ├──────┼──────┤             │
   │  │ 🔒   │ 🔒   │             │
   │  └──────┴──────┘             │
   │  footer                      │
   └──────────────────────────────┘
```

- `.card` `max-width` is increased globally from 400px → 520px to give the 2×2 grid room. The existing social buttons stretch to the new width (they look slightly more prominent but remain readable); the avatar and h1 stay centered, no layout regression.
- Below the 480px viewport breakpoint, the grid collapses to single column.

## Tile anatomy

```
┌──────────────────────────────┐
│ [blurred preview image]      │  filter: blur(18px) brightness(0.65)
│                              │
│         🔒 (lock SVG)        │  centered, with soft white glow
│                              │
│   [caption pill at bottom]   │  e.g. "20 photos · video"
└──────────────────────────────┘
```

Click target: whole tile is wrapped in `<a href="{unlock_url}" target="_blank" rel="noopener">`.

Hover behavior (composed):
- Blur eases 18px → 8px (0.4s)
- Tile lifts and tilts toward cursor (magnetic effect, reusing the existing button JS pattern)
- Lock icon bounces from `scale(0.9)` → `scale(1.1)` (0.3s ease-out)
- Overlay CTA "Unlock on OnlyFans →" fades in from `opacity: 0` → `1` (0.25s)

## Content model

Single JSON file at `/gallery.json`, edited by Decap, fetched at runtime:

```json
{
  "items": [
    {
      "image": "/images/gallery/teaser-01.jpg",
      "caption": "20 photos",
      "unlock_url": "https://onlyfans.com/keithbarron199"
    }
  ]
}
```

Fields:
- `image` (string, required) — path to preview image, uploaded via Decap to `/images/gallery/`
- `caption` (string, optional) — short label shown in the bottom pill; if omitted, no pill
- `unlock_url` (string, optional) — destination on click. Defaults to the main OF URL if omitted (Decap config sets the default).

Initial seed: 4 placeholder items so the grid renders on first load. Owner replaces them via Decap.

## Animations (four new, plus existing kept as-is)

| Animation | Implementation | Cost |
|---|---|---|
| Gradient text shift on `h1` | Existing gradient becomes 200% wide; `background-position` animated via 8s linear `@keyframes` loop. CSS only. | ~0 |
| Scroll-triggered reveals | New `.reveal` class: `opacity:0; transform: translateY(20px)`. One `IntersectionObserver` adds `.in-view` at 15% visibility; CSS transitions over 0.6s. Stagger of 80ms between tiles via inline `transition-delay`. Observer disconnects per-element after first reveal. | low |
| Cursor-following spotlight on `.card` | Pseudo-element on `.card` with `background: radial-gradient(circle 200px at var(--mx) var(--my), rgba(255,255,255,0.06), transparent 70%)`. `mousemove` handler updates the two CSS variables. | very low (no layout) |
| Locked-tile micro-interactions | Combined CSS hover transitions on `.tile` for blur, scale, lock-icon bounce, and CTA fade-in. Magnetic-tilt JS extended to also apply to `.tile` selector. | low |

Existing animations kept unchanged: orb drift, avatar ring spin, live-pill pulse, button shimmer, button fade-up stagger, button magnetic tilt.

All animations respect `prefers-reduced-motion: reduce`:
- CSS animations duration → 0.001ms (existing global override already in place)
- Reveals appear instantly with no translate
- Spotlight, magnetic tilt: JS bails out early
- Shimmer overlay on CTA already hidden under reduced motion

## File changes

```
Personal-Landing-Page/
├── index.html                ← gallery section markup, new CSS, expanded JS
├── gallery.json              ← NEW — content manifest, seeded with placeholders
├── admin/
│   ├── index.html            ← NEW — Decap CMS shell (~5 lines)
│   └── config.yml            ← NEW — content model + auth backend
├── images/
│   └── gallery/              ← NEW folder — Decap uploads land here
│       ├── .gitkeep
│       └── (placeholder images for initial seed, ~4 files)
└── docs/superpowers/specs/2026-05-16-exclusive-gallery-and-animations-design.md
```

## Decap CMS configuration

- Backend: `git-gateway` with Netlify Identity (primary). Fallback: `github` backend via a small Netlify Function OAuth proxy if Identity isn't available on the site (see Risks).
- Media folder: `images/gallery`
- Public folder: `/images/gallery`
- Single "file" collection pointing at `gallery.json` with a list widget for `items`, fields per item: `image` (image widget), `caption` (string, optional), `unlock_url` (string, optional, with default).

`/admin/index.html` is a five-line shell that loads Decap from a CDN script tag.

## One-time manual setup steps (owner)

1. Netlify dashboard → site → Identity → **Enable Identity**
2. Identity → Registration → set to **Invite only**
3. Identity → Services → Git Gateway → **Enable**
4. Identity → **Invite users** → invite owner's email
5. Click email link, set password
6. Visit `/admin` and log in

If step 1 is unavailable (Netlify Identity deprecation — see Risks), pivot to the GitHub OAuth fallback path; owner creates a GitHub OAuth app (~2 min), I add a Netlify Function.

## Accessibility

- Tiles are real anchor tags, fully keyboard-focusable with visible focus ring.
- Lock icon + caption have `aria-hidden`; the anchor has an `aria-label` like "Unlock 20 photos on OnlyFans".
- Section uses `<section aria-labelledby="exclusive-heading">` with a real `<h2>`.
- All hover-only choreography also fires on `:focus-visible` so keyboard users see the tease effect.
- Color contrast: CTA overlay text must hit at least 4.5:1 against the partially-unblurred preview. Use white text with semi-opaque dark scrim behind it.

## Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Netlify Identity can't be enabled on this site (deprecation) | Medium — uncertain until owner tries | Fallback to GitHub OAuth + Netlify Function; documented as plan B |
| Decap CMS UI changes break the `/admin` config | Low | Pin Decap to a specific version in the CDN URL |
| Spotlight + magnetic tilt + tile blur transitions feel chaotic together | Medium | Keep timing values modest (0.18s–0.4s), test on a slow throttled CPU, dial down if stacked feel is too busy |
| Card width change at the section break causes layout jump on render | Low | Define `max-width` on the parent card unconditionally so layout is stable from first paint |
| Owner forgets `unlock_url` and the default URL changes someday | Low | Default lives in `admin/config.yml`; spec calls out keeping it in sync with the main OF link in `index.html` |

## Out of scope (for explicitness)

- A real paywall, payment processor integration, or per-user access control
- Video playback on this site
- A lightbox/modal for previews
- Analytics on tile clicks
- A separate dedicated gallery page
- Image optimization pipeline (Netlify handles basic delivery)

## Open questions

None at design time. Implementation will surface concrete decisions about:
- Exact CSS values for blur depth, tile gap, etc. (will iterate visually)
- Whether to add a small "NEW" badge for the most recent tile (defer — out of scope unless owner asks)
