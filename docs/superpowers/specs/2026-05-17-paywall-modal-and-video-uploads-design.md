# Paywall Modal + Video Uploads — Design

**Date:** 2026-05-17
**Project:** Personal-Landing-Page (keithlinks.netlify.app)
**Status:** Approved by user, ready for implementation planning
**Supersedes:** Tile click behavior + data model from [2026-05-16-exclusive-gallery-and-animations-design.md](./2026-05-16-exclusive-gallery-and-animations-design.md). All other parts of that spec (layout, animations, CMS plumbing, accessibility approach) remain in effect.

## Goals

1. Convert the exclusive-gallery tiles from "click → opens OnlyFans" into "click → opens a 'Purchases coming soon' modal" with a per-tile price displayed.
2. Allow the CMS to accept both photos and short videos (≤25 MB each) as tile media, and render them appropriately.
3. Keep all infrastructure work (Stripe, Cloudinary, signed URLs, payment state) out of scope — this design ships the visual paywall surface so a real backend can be wired in later without further UI work.

## Non-Goals (explicit)

- **No real payment processing.** No Stripe, no checkout flow, no money handling.
- **No real access control.** The blurred preview is still a teaser — the *actual* uploaded media file is still publicly fetchable via its URL by anyone who knows the path. This is documented honestly in the modal copy and in code comments.
- **No video poster-frame generation.** Videos render via the native `<video>` element with `preload="metadata"`; the first frame is shown blurred. A nicer poster pipeline waits for Cloudinary integration.
- **No analytics on tile clicks or modal opens.**
- **No backend changes.** All work is in the single `index.html`, the JSON manifest, and the Decap config.

## What changes vs. the 2026-05-16 spec

| Area | Old behavior (2026-05-16) | New behavior (2026-05-17) |
|---|---|---|
| Tile element | `<a target="_blank">` → OnlyFans | `<button>` → opens modal |
| Tile data fields | `image`, `caption`, `unlock_url` | `media`, `caption`, `price` |
| Media type | Photo only (`.jpg/.png`) | Photo or short video (`.jpg/.jpeg/.png/.webp/.gif/.mp4/.webm`) |
| Hover CTA copy | "Unlock on OnlyFans →" | "🔒 $10" (price pill) |
| Click target | OnlyFans subscription page | In-page modal |
| `safeUrl()` helper | Used for `href` and `src` | Used only for `src` (no more outbound href from tiles) |
| `rel="noopener noreferrer"` | On tile anchors | N/A — tiles are buttons now |
| `aria-label` on tile | "Unlock {caption} on OnlyFans" | "Unlock {caption} — $10" |

## Tile rendering

Detect media type from the file extension of `media`:
- `.mp4`, `.webm` → render as `<video class="tile-image" preload="metadata" muted playsinline>{source}</video>` with the existing `.tile-image` CSS (blur + brightness + scale). Add a small `<span class="tile-video-indicator" aria-hidden="true">▶</span>` overlay in the top-right corner so users see it's video at a glance.
- Anything else → render as `<img class="tile-image" src="..." alt="" aria-hidden="true">` (current behavior).

The CSS `filter: blur(...)` works identically on `<img>` and `<video>` so no new tile styling is needed for the blur.

## Tile interaction

Each tile is a `<button type="button" class="tile reveal" data-index="N" aria-haspopup="dialog">…</button>` (no `<a>`, no `href`). The render IIFE attaches a single delegated `click` listener on `#gallery-grid` that:

1. Finds the closest `.tile`
2. Reads `data-index` to look up the tile from the in-memory `items` array
3. Opens the modal with that tile's media, caption, and price

Magnetic hover, scroll reveals, and tile hover micro-interactions all continue to work on the `<button>` element exactly the same way (selectors target `.tile`, not specifically `<a>`).

## Modal design

```
┌──────────────────────────────────────────────────────┐
│ ░░░░░░░░░░░░░░░  backdrop  ░░░░░░░░░░░░░░░░░░░░░░░░ │
│                                                      │
│    ┌────────────────────────────────────┐            │
│    │                              [ × ] │            │
│    │   [ blurred media preview ]        │            │
│    │   ────────────────────────────     │            │
│    │   20 photos                        │            │
│    │   $10 to unlock                    │            │
│    │                                    │            │
│    │   ╔═══════════════════════════╗    │            │
│    │   ║   Purchases coming soon   ║    │            │
│    │   ╚═══════════════════════════╝    │            │
│    │                                    │            │
│    │   Follow @Keithbarron3333 on X for │            │
│    │   launch updates →                 │            │
│    │                                    │            │
│    └────────────────────────────────────┘            │
└──────────────────────────────────────────────────────┘
```

**Structure:** A single `<dialog>` element at the end of `<body>`, used via the native HTML5 dialog API (`dialog.showModal()` / `dialog.close()`). Native dialogs give us focus trap, Esc-to-close, and backdrop styling for free in all modern browsers (≥2022).

**Markup template (one dialog, content injected per click):**
```html
<dialog id="tile-modal" class="modal" aria-labelledby="modal-title">
  <button class="modal-close" type="button" aria-label="Close">×</button>
  <div class="modal-media" id="modal-media"><!-- img or video injected --></div>
  <h2 class="modal-title" id="modal-title"><!-- caption --></h2>
  <p class="modal-price"><!-- $X to unlock --></p>
  <div class="modal-status">Purchases coming soon</div>
  <p class="modal-followup">Follow <a href="https://x.com/Keithbarron3333" target="_blank" rel="noopener noreferrer">@Keithbarron3333</a> on X for launch updates →</p>
</dialog>
```

**Styling:**
- Backdrop via `dialog::backdrop` with `background: rgba(0,0,0,0.78); backdrop-filter: blur(8px);`
- Card width: `max-width: 420px`, padded, dark surface (`#15151d`), rounded `16px`
- Same brand purple-pink gradient accent on the "coming soon" badge
- Close button is a 32×32 circle in the top-right, white text on `rgba(255,255,255,0.1)` background
- Modal entrance: `transform: translateY(20px); opacity: 0` → `translateY(0); opacity: 1` over 0.25s when opened; honors `prefers-reduced-motion`

**Interactions:**
- Esc → close (native `<dialog>` behavior — fires `cancel` event)
- Close button click → `dialog.close()`
- Click backdrop → close. Native `<dialog>` does NOT auto-close on backdrop click; we add a click handler on the dialog itself that checks `e.target === dialog` (true when the click hits the backdrop area, since the dialog element fills the viewport and the inner content blocks events from reaching it).
- When closed, modal content cleared (innerHTML reset on `<div id="modal-media">` so the `<video>` element is removed and stops loading metadata)
- Body scroll is blocked while open — native `<dialog>` puts the rest of the page in the inert tree, but does NOT block body scroll by default; we add `body.style.overflow = 'hidden'` on open and restore on close.

**A11y:**
- `aria-labelledby="modal-title"` (which is the caption)
- Close button has `aria-label="Close"`
- Focus moves to close button on open (browser default for `showModal()`)
- Focus returns to triggering tile on close (we handle this via stored `lastFocusedTile` reference)

## Content model

`gallery.json` shape after the change:

```json
{
  "items": [
    {
      "media": "/images/gallery/teaser-01.jpg",
      "caption": "20 photos",
      "price": 10
    },
    {
      "media": "/videos/gallery/demo-clip.mp4",
      "caption": "Backstage clip",
      "price": 15
    }
  ]
}
```

Field definitions:
- `media` (string, required) — path to the media file (image or video, type detected from extension)
- `caption` (string, optional) — short label
- `price` (integer, required, minimum 1) — dollar amount, displayed as `$N`

Removed: `image`, `unlock_url`.

## Decap CMS config changes

In `admin/config.yml`, the fields list inside the `items` widget becomes:

```yaml
fields:
  - { name: media, label: "Media (photo or short video, max 25MB)", widget: file, allow_multiple: false, media_library: { config: { multiple: false } } }
  - { name: caption, label: "Caption (optional)", widget: string, required: false }
  - { name: price, label: "Price (USD, whole dollars)", widget: number, value_type: int, min: 1, default: 10 }
```

Hint: Decap's `file` widget accepts any file type by default. The 25 MB limit is not enforced by Decap itself — it's a soft guideline in the field label so the user knows not to upload large videos. Git Gateway will reject pushes that exceed Netlify's per-file cap (~25 MB) anyway, which is a fail-loud safety net.

Media folder stays as `images/gallery`. (Despite the name, it'll hold videos too — keeping the name avoids breaking existing tiles. If video count grows large later, a Cloudinary migration is the right next step.)

## File changes

```
Personal-Landing-Page/
├── index.html         ← modal markup at end of <body>, new modal CSS, updated render IIFE, click delegation
├── gallery.json       ← items reshaped to { media, caption, price }
├── admin/
│   └── config.yml     ← fields list updated (media replaces image, price added, unlock_url removed)
└── docs/superpowers/
    ├── specs/2026-05-17-paywall-modal-and-video-uploads-design.md    ← this file
    └── plans/2026-05-17-paywall-modal-and-video-uploads.md           ← implementation plan (next step)
```

No new directories. No new external dependencies. No new files in `images/gallery/` (existing four placeholders keep working — they're images).

## Accessibility

- `<button>` tiles are keyboard-focusable by default and trigger on Enter/Space.
- The `aria-haspopup="dialog"` on the tile tells screen readers what will happen.
- Native `<dialog>` provides focus trap, Esc-close, and inert-background behavior across all modern browsers.
- Modal title comes from the tile's caption via `aria-labelledby`.
- The price pill on the tile and the price in the modal use real text (not background images), so it's read aloud.
- Close button has both an `×` glyph and `aria-label="Close"`.
- Reduced-motion: modal entrance animation falls back to instant via the existing global reduced-motion CSS override.

## Risks and mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Owner uploads a 100 MB video, Git Gateway rejects the push silently in the Decap UI | Medium | Document the 25 MB cap in the field label. Decap will surface the Git Gateway error in its toast on save. If this becomes painful, Cloudinary migration is the documented next step. |
| User confuses "purchases coming soon" with "site is broken" | Low | Modal explicitly says "coming soon" + redirects to X for updates. Honest UX. |
| `<dialog>` element behavior differs in older browsers | Low | Native `<dialog>` shipped in Safari 15.4 (Mar 2022), all other evergreen browsers earlier. Acceptable baseline for a personal landing page. Polyfill not needed. |
| Video tiles auto-play their first frame loading bandwidth on page load | Low | `preload="metadata"` only loads ~headers + first frame; total cost is small even with several video tiles. If perf becomes an issue, switch to `preload="none"` and add a static poster image later. |
| Existing seed tiles in `gallery.json` use the old shape with `image`/`unlock_url` | Certain | Migration is part of the plan: rewrite the 4 seed items to the new shape with placeholder prices. |
| The `media` field in gallery.json points to a non-existent file path because Decap is misconfigured | Medium | Render IIFE keeps the existing try/catch around the render; broken `<img>`/`<video>` element gracefully degrades to the tile background color. |

## Open questions

None at design time. Implementation will surface concrete decisions about:
- Exact modal entrance timing
- Whether the video indicator (▶) should also appear on hover when the blur lifts, or stay static
- Optional: Should the modal show estimated launch date? (Out of scope for now — defer until user knows.)

## What's deferred to a future spec ("real paywall")

Documented here so it's clear what's not in this round:

- Stripe Checkout integration (Netlify Functions for session creation + webhook handler)
- Stripe customer ID storage (cookie or JWT)
- Cloudinary integration (private uploads, signed delivery URLs)
- Refund flow, payment failure handling
- Tax / compliance / terms-of-service work
- Per-tile sold-out / sold-N-times indicators
- Bundle pricing (e.g., "all 4 for $30")
- Email receipts
- Customer support flow
