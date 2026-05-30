# Personal Landing Page — Dual-Path Conversion & Premium Pass — Design

**Date:** 2026-05-26
**Project:** Personal-Landing-Page (https://keith-links-995.pages.dev/)
**Status:** Approved by user in brainstorming, ready for implementation planning
**Builds on:** [2026-05-16-exclusive-gallery-and-animations-design.md](./2026-05-16-exclusive-gallery-and-animations-design.md), [2026-05-17-paywall-modal-and-video-uploads-design.md](./2026-05-17-paywall-modal-and-video-uploads-design.md). Both remain in effect; this round changes the hero, adds two new sections, swaps in real assets, and adds a sticky mobile CTA.

## Goals

1. **Convert more visitors to paying fans** by giving OnlyFans and Chaturbate equal visual weight in the hero, surfacing live/next-stream status, and adding social proof.
2. **Raise the page's perceived quality** through real teaser content, compressed media, tighter copy, and a sticky mobile CTA.

Equal-lane treatment for OnlyFans + Chaturbate is the design's organizing constraint. The current page treats Chaturbate as the dominant CTA (top-nav button + bright primary tile) and funnels gallery clicks to OnlyFans — the resulting split attention is the core conversion problem this design fixes.

## Non-Goals (explicit)

- **No real payment processing.** The "Unlock" modal continues to send visitors to OnlyFans. Stripe / Cloudinary / signed URLs remain deferred to a future round.
- **No theme or palette overhaul.** Dark `#060608` background, violet `#7a4dff`/`#a06bff` accents, and Inter + Archivo Black fonts stay.
- **No custom domain.** `keith-links-995.pages.dev` is the canonical URL.
- **No Netlify Identity setup.** That remains the user's manual action. CMS scaffolding for the new content collections ships now and starts working once Identity is enabled.
- **No real-time Chaturbate API integration.** Live/offline state is inferred from the schedule, not probed live.
- **No JavaScript framework or build step.** Single-file vanilla HTML with three IIFEs, DOM-method rendering (no `innerHTML` on dynamic data) — the existing conventions hold.
- **No analytics in this round.** GA4/Plausible can land later; out of scope here to keep the round focused.

## What changes at a glance

| Area | Today | After this round |
|---|---|---|
| Hero CTAs | 1 bright (Chaturbate) + 3 grey (OF/X/IG) | 2 equal lane cards (Chaturbate / OnlyFans) + slim social row (X/IG/DM) |
| Top-nav CTA | "Watch live →" (Chaturbate-biased) | "Follow ↓" (neutral, scrolls to social row) |
| LIVE badge | Always on (hardcoded) | Driven by `schedule.json` + visitor's local time |
| Schedule section | — | New: "Next stream" + weekly grid |
| Testimonials section | — | New: "What fans are saying" 3-col grid |
| Sticky mobile CTA | — | New: split bar (Watch live / Unlock OF) |
| Gallery teasers | 4× 3.2 MB JPGs (all copies of profile.png) | 4 real WebP teasers, target <120 KB each |
| `profile.png` | 3.2 MB PNG | `profile.webp` ~80 KB at 480×480 (+ 2x) |
| Page weight | ≈16 MB | <1 MB target |
| OG share image | Reuses `profile.png` | Purpose-built 1200×630 WebP/PNG share card |
| SEO/structured data | Basic OG/Twitter only | + JSON-LD `Person`, canonical, `sitemap.xml`, `robots.txt` |
| Decap collections | `gallery` only | + `schedule`, `testimonials`, `bio` (single-file) |
| FAQ | 5 items | 6 items (+2 new, -1 outdated) |

## Architecture

Still a single `index.html` with inline `<style>` and `<script>`. New JSON data files sit alongside `gallery.json` at the repo root.

**Files added:**
- `schedule.json` — weekly stream schedule (recurring slots)
- `testimonials.json` — fan quotes
- `bio.json` — single-file bio (hero subtitle + bio line), so CMS can edit hero copy
- `images/og.png` (or `.webp`) — purpose-built 1200×630 share card
- `sitemap.xml`, `robots.txt`
- `tools/optimize-images.js` — sharp-based WebP pipeline, same pattern as Business LP

**Files modified:**
- `index.html` — hero restructure, two new sections, sticky mobile bar, copy refresh, `<head>` (preload + JSON-LD), three new render IIFEs
- `gallery.json` — point `media` paths at the new WebP teasers
- `admin/config.yml` — three new Decap collections
- `images/profile.png` → replaced by `images/profile.webp` (+ `profile@2x.webp`); old PNG removed
- `images/gallery/teaser-0{1..4}.jpg` → replaced by real `.webp` teasers

**JS architecture — four new IIFEs** added to the existing three (render gallery, modal, scroll-reveal):

1. **Schedule IIFE** — fetches `schedule.json`, computes next stream (and current LIVE state) using `Intl.DateTimeFormat` for the visitor's local time, renders the next-stream callout + weekly grid, and **publishes a `schedule:state` event** carrying `{ isLive: boolean, nextSlot: {...} }`.
2. **Hero LIVE-state listener** — listens for `schedule:state`, toggles the hero's LIVE pulse + lane-card eyebrow ("LIVE NOW" vs "NEXT: Wed 9 PM CT"). Also toggles the sticky mobile bar's live-button accent (red when live, neutral when offline).
3. **Testimonials IIFE** — fetches `testimonials.json`, renders quote cards via DOM methods (no `innerHTML` on dynamic data; quote text and handle go through `textContent`).
4. **Bio IIFE** — fetches `bio.json`, writes `subtitle` and `tagline` into dedicated `id`-targeted DOM nodes in the hero (via `textContent`). Falls back to the hardcoded copy in `index.html` if the fetch fails.

The existing render-gallery and modal IIFEs are untouched in logic — they only get new image paths.

**Why the event bus pattern (`schedule:state`):** decouples schedule fetch from the hero + sticky-bar listeners, mirrors the existing `gallery:ready` pattern, and keeps the rendering surfaces honest about their data dependencies.

## Section-by-section design

### Hero (rebuilt)

```
NAV ─ [● KEITH] ──────────────────────── [Follow ↓]
HERO
        (avatar — 180px, with conditional LIVE pulse)
                     KEITH
              one tightened bio line
  ┌───────────────────┐  ┌───────────────────┐
  │ ● LIVE NOW        │  │ 🔒 FULL LIBRARY   │
  │ Watch on          │  │ Unlock on         │
  │ Chaturbate     →  │  │ OnlyFans       →  │
  └───────────────────┘  └───────────────────┘
            [ X ]  [ IG ]  [ DM ]
```

**Lane card structure** (both cards same dimensions, hover treatment, focus ring; only the accent color/icon differs):

- Eyebrow line (12px uppercase, letter-spaced): `LIVE NOW` (red pulse) / `NEXT: Wed 9 PM CT` for left, `FULL LIBRARY` for right
- Title (24px, Archivo Black-light): "Watch on Chaturbate" / "Unlock on OnlyFans"
- Subline (14px, muted): blank for left when offline / "<N> photos · <M> videos" for right
- Trailing arrow `→` that translates 4px on hover

**Visual treatment differentiation:**
- Left (Chaturbate): subtle red accent on eyebrow when LIVE, defaults to violet when offline; small pulsing dot only when LIVE.
- Right (OnlyFans): violet gradient background (the current `.link-tile.primary` style), lock icon prefix.

**Mobile:** Stacked vertical, full-width, live card on top. Same vertical rhythm as desktop.

**Social row:** 3 icon-only round buttons (40×40), no labels visible (labels via `aria-label`). Icons: X, Instagram, mailto/DM. Tab order: Chaturbate → OnlyFans → social row → next section. (A 4th slot can be added later if/when the user picks up TikTok, Threads, or another platform — not in scope this round.)

**Nav CTA:** "Follow ↓" — a smooth-scroll link to the social row anchor (`#follow`). Neutral styling (outlined, not gradient-filled) so the nav doesn't pre-bias one platform.

**Bio line:** drafted as one of these (final pick in implementation; user reviews drafts):
- a) "Live on cam most nights · Full library on OnlyFans · Daddy energy, real moments."
- b) "Most nights I'm live. The rest of the time I'm on OnlyFans. Either way, you're getting the real me."
- c) "Real moments, daddy energy — catch me live on Chaturbate or unlock the full library on OnlyFans."

### Schedule (new) — placed immediately after hero, before gallery

Two views in one section, side-by-side on desktop, stacked on mobile.

**Left: Next stream callout**
- Eyebrow: `NEXT STREAM` (or `LIVE NOW →` link to Chaturbate, when current time falls inside a slot)
- Big day + time, in the visitor's local timezone: "Wednesday, 9:00 PM CT" (display the *original* tz of the slot — feels authentic — and append a "(in 2 days, your time)" line computed in the visitor's locale)
- Small "Times shown in your local timezone where noted" microcopy

**Right: Weekly grid**
- 7 chips Mon→Sun (or starting on today, configurable later)
- Lit chip: day abbreviation + time
- Dim chip: day abbreviation + "Off"
- Today's chip gets a subtle accent

**Data model — `schedule.json`:**
```json
{
  "tz": "America/Chicago",
  "slots": [
    { "day": "Mon", "start": "21:00", "end": "23:00" },
    { "day": "Wed", "start": "21:00", "end": "23:00" },
    { "day": "Fri", "start": "22:00", "end": "01:00" }
  ],
  "overrides": [
    { "date": "2026-06-03", "off": true, "note": "out of town" }
  ]
}
```

- `day` accepts the 3-letter abbreviations Mon..Sun. Times are 24-hour in the schedule's home `tz`.
- A slot wrapping past midnight (`start > end`) means the slot extends into the next day.
- `overrides[]` is a forward-looking exception list. An override with `off: true` cancels any slots on that calendar date in the schedule's `tz`. Optional `note` is currently informational only (not rendered).
- LIVE detection: compute the current moment in the schedule's `tz`, find any slot containing it, and check that no override cancels today. If both pass → LIVE.

### Gallery (no structural change, content swap)

- `gallery.json` paths updated to `.webp` filenames.
- New `tools/optimize-images.js` produces WebP at target <120 KB per teaser. Aspect ratio matches the existing 3:4 tile (so the source can be 600×800 or similar — the rendered preview is blurred and dim, no need for full-res).
- Modal copy and behavior unchanged. Still "coming soon → Unlock on OnlyFans".

### Testimonials (new) — placed between gallery and FAQ

Section header: eyebrow `What fans are saying`, title `From the DMs` (or whatever feels right — final pick in implementation).

**Card layout:** 1 / 2 / 3 columns at 360 / 640 / 900 px breakpoints.

**Card contents:**
- Subtle violet quote-mark glyph (top-left, decorative, `aria-hidden`)
- Quote text (16px, normal weight, max ~140 chars per quote enforced by the editor — keeps cards balanced)
- Handle line (12.5px muted): `@fan_xyz` or "Fan from X" — optional

**Data model — `testimonials.json`:**
```json
{
  "items": [
    { "quote": "…short fan quote…", "handle": "@fan_xyz" },
    { "quote": "…", "handle": "Fan from OnlyFans" }
  ]
}
```

If the array is empty, the entire section hides itself (the IIFE never appends the section wrapper to the DOM) so the page degrades gracefully.

### Sticky mobile CTA (new)

```
+----------------------+----------------------+
|  ●  Watch live       |  🔒  Unlock OF       |
+----------------------+----------------------+
```

- Only renders at `≤640px` (`@media (max-width: 640px)`).
- Fixed to bottom edge, full-width, two equal-width buttons, 56px tall.
- Backdrop-blurred translucent base (`rgba(6,6,8,0.85)` + `backdrop-filter: blur(10px)`), 1px top border.
- Left button: red accent + pulse dot when `isLive` (from `schedule:state`); neutral violet outline otherwise. Always points at Chaturbate.
- Right button: violet gradient, always points at OnlyFans.
- Hidden until the visitor has scrolled past the hero (use IntersectionObserver on the hero element so we don't fight the visitor while they're still reading the headline).
- Adds a `padding-bottom` shim to `body` while visible so the footer copyright isn't covered.
- Respects `prefers-reduced-motion` (no slide-in animation when set).

### FAQ refresh

- **Add:** "Where can I see your schedule?" → links to the new Schedule section.
- **Add:** "Are the testimonials real?" → short honest answer (real fans, with permission; handles may be partial).
- **Remove:** "When does the on-site paywall go live?" (less relevant now; the page no longer leans on that as a coming-soon hook).
- **Keep:** the other 4 items, copy unchanged.

### Footer

- Add a `mailto:` (or X DM) link in the footer-links row, labeled "Send a DM".
- No other changes.

## Performance & SEO pass

**Images:**
- All raster assets → WebP via `tools/optimize-images.js` (sharp). Pipeline mirrors the Business LP pattern: read source, output `.webp` at target quality, log sizes. Idempotent — re-running doesn't break anything.
- `profile.webp` at 480×480 plus `profile@2x.webp` at 960×960 for retina. The avatar renders at 180px, so 480 is comfortable.
- `<link rel="preload" as="image" type="image/webp" href="images/profile.webp">` in `<head>` for LCP.
- Gallery `<img>` and `<video>` elements get `loading="lazy"` (everything is below the fold).
- New `tools/optimize-images.js` lives in `tools/` (NOT shipped to Netlify — `sharp` is dev-only; add `tools/node_modules/` to `.gitignore`).

**OG share card:**
- 1200×630, branded (KEITH wordmark + avatar + violet glow), generated by a small `scripts/make-og.ps1` (System.Drawing, same approach as the Business LP).
- Updates `<meta property="og:image">` and `<meta name="twitter:image">` to point at it.
- Keeps the dark/violet brand.

**SEO additions:**
- `<link rel="canonical" href="https://keith-links-995.pages.dev/">` in `<head>`.
- JSON-LD `Person` schema in `<head>` (name, url, image, sameAs links to X / Instagram / OnlyFans / Chaturbate).
- `sitemap.xml` at root listing the single canonical URL.
- `robots.txt` allowing all crawlers (page is intentionally public; honest about that).

## CMS additions (`admin/config.yml`)

Three new collections (Decap-editable once Netlify Identity is enabled):

1. **`schedule`** (single-file `schedule.json`) — fields: `tz` (string, default `America/Chicago`), `slots` (list of `{day, start, end}`), `overrides` (list of `{date, off, note}`).
2. **`testimonials`** (single-file `testimonials.json`) — fields: `items` (list of `{quote, handle}`). Validation: quote `max: 200` characters.
3. **`bio`** (single-file `bio.json`) — fields: `subtitle` (e.g. "Welcome to my world"), `tagline` (the one-line bio under the wordmark). Renders into the hero via a fourth IIFE that fetches `bio.json` and writes to dedicated DOM nodes by `id`.

The existing `gallery` collection is unchanged (still `gallery.json` with `items: [{media, caption, price}]`).

**CMS-without-Identity caveat:** Until the user enables Netlify Identity, all three new collections (plus the existing `gallery`) can only be edited by hand-editing the JSON files. The site renders fine either way because every IIFE has a fallback: missing/empty file → section hides itself.

## Security & convention guardrails (unchanged but called out)

- **No `innerHTML` on dynamic data.** Every new IIFE uses `createElement` / `textContent` / `appendChild`. The PreToolUse hook will block anything else. Quote text, handles, schedule day strings, and bio text all flow through `textContent`.
- **`validateUrl` helper continues to gate any URL written to `.src` or `.href`.** Schedule and testimonials don't introduce new URLs, but the `mailto:` link in the footer is a static string (no data flow).
- **Single-file `index.html`.** No splitting into modules. New CSS goes into the existing `<style>`, new JS into the existing `<script>`.

## Open implementation questions (resolve during planning)

1. **Bio tagline final pick** — present the 3 drafts to the user; pick one or write a 4th.
2. **Testimonials section title** — "What fans are saying" (eyebrow) + "From the DMs" (title) is the working pair; user can override.
3. **Initial schedule + testimonials content** — needed before deploy. User said both are available.
4. **2x avatar source** — current `profile.png` is 3.2 MB at unknown dimensions. Confirm the source is high enough resolution for a 960×960 export, or use 480 only.

## Risks & mitigations

- **Schedule lies about being live.** Inferring LIVE from schedule means a skipped session shows a false LIVE badge. Mitigation: `overrides[].off=true` lets the user cancel a day from the CMS without editing slots. Future option: a manual "I'm offline tonight" override switch.
- **Testimonials read as fake.** Mitigated by the new FAQ item ("Are the testimonials real?") and by skipping avatars (no stock-photo trap). Users should put real, attributable quotes here.
- **Sticky mobile bar covers content on tiny viewports.** Mitigated by `padding-bottom` shim on body when bar is visible, and by hiding the bar until past-hero (so it doesn't fight the headline).
- **WebP support.** Universal at this point (≥97% global); no fallback needed. If a true ancient browser ever matters, the `<img>` will fail to load and we'll see it in logs.

## Decisions log (from brainstorming)

| Decision | Choice | Rationale |
|---|---|---|
| Primary goal | Convert more + premium feel | User picked both |
| Platform hierarchy | OnlyFans + Chaturbate equal | User decision; the design's organizing constraint |
| Lane card layout | Side-by-side desktop, stacked mobile | True equal weight |
| LIVE state source | Inferred from schedule | Zero-maintenance; overrides handle the false-positive risk |
| Testimonials tone | "What fans are saying" | On-brand, casual |
| Sticky mobile CTA | Split bar (2 buttons) | Mirrors the equal-lane hero design |
| Real Stripe paywall | Out of scope (deferred) | Existing decision, not revisited |

## Deliverables

When the implementation plan finishes, the visitor experience is:

1. Lands on a hero that visually presents two equal paths.
2. Sees real LIVE state (when scheduled), or "next stream" with a day/time in their local zone.
3. Scrolls a few sections: schedule → gallery (with real teasers, fast-loading) → testimonials → FAQ.
4. On mobile, always has a sticky split CTA bar in reach once past the hero.
5. Sees a branded share card when the URL is dropped into X / iMessage / Telegram.
6. Page weight drops from ~16 MB to under 1 MB.

The CMS structure is in place for the user to edit bio, schedule, testimonials, and gallery from one Decap panel once Netlify Identity is enabled.
