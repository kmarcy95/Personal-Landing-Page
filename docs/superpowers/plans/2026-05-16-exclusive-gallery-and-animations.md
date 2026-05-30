# Exclusive Gallery + Additional Animations — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an "Exclusive Content" teaser gallery (Decap-CMS-managed) and four new animations to the keithlinks landing page, funneling subscribers to OnlyFans without any real paywall infrastructure.

**Architecture:** Single-file vanilla HTML/CSS/JS extended with: a 2×2 gallery grid rendered at runtime from a `gallery.json` manifest; a Decap CMS shell at `/admin` for managing that manifest via Git Gateway; four new animations layered onto the existing styles. Reduced-motion users get instant-no-animation everywhere. No build step.

**Tech Stack:** Vanilla HTML/CSS/JS, Decap CMS (CDN-loaded), Netlify Identity + Git Gateway for auth, Netlify hosting.

**Spec:** [`docs/superpowers/specs/2026-05-16-exclusive-gallery-and-animations-design.md`](../specs/2026-05-16-exclusive-gallery-and-animations-design.md)

---

## Working environment

- Repo path: `C:\Users\keyst\Personal-Landing-Page`
- Local preview: serve the folder over HTTP (required from Task 9 onward because `fetch('/gallery.json')` doesn't work on `file://`):
  ```powershell
  cd C:\Users\keyst\Personal-Landing-Page
  python -m http.server 8000
  ```
  Then open http://localhost:8000/.
- Deploy after each task is not required — commit each task locally, then bulk-deploy at the end via `netlify deploy --prod --dir .`.

---

## File structure

**New files:**
- `gallery.json` — content manifest (array of tile objects)
- `admin/index.html` — Decap CMS shell page
- `admin/config.yml` — Decap content-model configuration
- `images/gallery/.gitkeep` — keeps folder under version control
- `images/gallery/teaser-01.jpg` through `teaser-04.jpg` — seed placeholder images (copies of `images/profile.png`)

**Modified files:**
- `index.html` — card width, new gallery section markup, new CSS blocks, expanded JS

---

## Task 1: Widen the card to 520px

**Files:**
- Modify: `index.html` (the `.card` rule in the inline `<style>`)

- [ ] **Step 1: Edit `.card` max-width**

In [index.html](index.html), find the `.card` rule and change `max-width: 400px;` to `max-width: 520px;`. The full rule should read:

```css
.card {
  position: relative;
  z-index: 1;
  width: 100%;
  max-width: 520px;
  text-align: center;
  animation: fadeUp 0.6s ease both;
}
```

- [ ] **Step 2: Verify in browser**

Open `index.html` in a browser. The card should appear wider (~520px). The avatar stays centered, the social buttons stretch slightly wider but remain readable. No layout breakage.

- [ ] **Step 3: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add index.html
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Widen card to 520px to fit upcoming gallery grid"
```

---

## Task 2: Add the empty Exclusive section scaffold

**Files:**
- Modify: `index.html` (body markup + new CSS rules)

- [ ] **Step 1: Add the section markup**

In [index.html](index.html), inside `<main class="card">`, find the existing `<nav class="links">…</nav>` block. Immediately AFTER its closing `</nav>` and BEFORE `<p class="footer">…</p>`, insert:

```html
    <section class="exclusive" aria-labelledby="exclusive-heading">
      <div class="divider divider-exclusive" role="separator">
        <span id="exclusive-heading">Exclusive Content</span>
      </div>
      <p class="exclusive-tease">Locked previews — unlock the full set on OnlyFans.</p>
      <div class="gallery-grid" id="gallery-grid">
        <!-- tiles rendered here (Task 9 fills this dynamically; Tasks 3-8 use a hardcoded version we replace) -->
      </div>
    </section>
```

- [ ] **Step 2: Add section CSS**

In [index.html](index.html), inside the `<style>` block, immediately after the `.divider` rule block (the one with `::before, ::after`), add:

```css
    /* exclusive section */
    .exclusive {
      margin-top: 2rem;
    }
    .divider-exclusive {
      color: #c084fc;
      font-weight: 700;
      letter-spacing: 0.18em;
      margin-bottom: 0.6rem;
    }
    .divider-exclusive::before,
    .divider-exclusive::after {
      background: linear-gradient(90deg, transparent, rgba(192,132,252,0.4), transparent);
    }
    .exclusive-tease {
      font-size: 0.78rem;
      color: rgba(255,255,255,0.55);
      margin-bottom: 1rem;
      letter-spacing: 0.02em;
    }
    .gallery-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0.65rem;
    }
    @media (max-width: 480px) {
      .gallery-grid { grid-template-columns: 1fr; }
    }
```

- [ ] **Step 3: Verify in browser**

Refresh `index.html`. Below the social buttons you should see a purple "EXCLUSIVE CONTENT" divider, the tease line, and an empty grid space. No console errors.

- [ ] **Step 4: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add index.html
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Add Exclusive section scaffold (heading + empty grid)"
```

---

## Task 3: Add 4 hardcoded tiles + base tile styling

This task makes a visible 2×2 grid of blurred tiles using static markup. Task 9 will later replace the static tiles with JSON-driven rendering — keeping the static version first means CSS can be tested in isolation.

**Files:**
- Modify: `index.html` (inside `#gallery-grid`, and new CSS rules)

- [ ] **Step 1: Add four placeholder tile elements**

In [index.html](index.html), replace the `<!-- tiles rendered here … -->` comment inside `<div class="gallery-grid" id="gallery-grid">` with:

```html
        <a class="tile" href="https://onlyfans.com/keithbarron199" target="_blank" rel="noopener" aria-label="Unlock photo set 1 on OnlyFans">
          <img class="tile-image" src="images/profile.png" alt="" aria-hidden="true" />
          <span class="tile-lock" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="3" y="11" width="18" height="11" rx="2"/>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
          </span>
          <span class="tile-cta" aria-hidden="true">Unlock on OnlyFans →</span>
          <span class="tile-caption" aria-hidden="true">20 photos</span>
        </a>
        <a class="tile" href="https://onlyfans.com/keithbarron199" target="_blank" rel="noopener" aria-label="Unlock video set on OnlyFans">
          <img class="tile-image" src="images/profile.png" alt="" aria-hidden="true" />
          <span class="tile-lock" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="3" y="11" width="18" height="11" rx="2"/>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
          </span>
          <span class="tile-cta" aria-hidden="true">Unlock on OnlyFans →</span>
          <span class="tile-caption" aria-hidden="true">Video · 4 min</span>
        </a>
        <a class="tile" href="https://onlyfans.com/keithbarron199" target="_blank" rel="noopener" aria-label="Unlock photo set 2 on OnlyFans">
          <img class="tile-image" src="images/profile.png" alt="" aria-hidden="true" />
          <span class="tile-lock" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="3" y="11" width="18" height="11" rx="2"/>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
          </span>
          <span class="tile-cta" aria-hidden="true">Unlock on OnlyFans →</span>
          <span class="tile-caption" aria-hidden="true">12 photos</span>
        </a>
        <a class="tile" href="https://onlyfans.com/keithbarron199" target="_blank" rel="noopener" aria-label="Unlock video set 2 on OnlyFans">
          <img class="tile-image" src="images/profile.png" alt="" aria-hidden="true" />
          <span class="tile-lock" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="3" y="11" width="18" height="11" rx="2"/>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
            </svg>
          </span>
          <span class="tile-cta" aria-hidden="true">Unlock on OnlyFans →</span>
          <span class="tile-caption" aria-hidden="true">Video · 6 min</span>
        </a>
```

- [ ] **Step 2: Add tile CSS (base state, no hover yet)**

In [index.html](index.html), inside the `<style>` block, immediately after the `.gallery-grid` media query you added in Task 2, add:

```css
    /* gallery tile */
    .tile {
      position: relative;
      aspect-ratio: 1 / 1;
      border-radius: 14px;
      overflow: hidden;
      display: block;
      text-decoration: none;
      color: #fff;
      isolation: isolate;
      background: #1a1035;
      transition: transform 0.3s ease, box-shadow 0.3s ease;
    }
    .tile-image {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      object-fit: cover;
      filter: blur(18px) brightness(0.55) saturate(1.1);
      transform: scale(1.15);
      transition: filter 0.4s ease, transform 0.4s ease;
    }
    .tile-lock {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%) scale(0.9);
      width: 30px;
      height: 30px;
      color: #fff;
      opacity: 0.95;
      filter: drop-shadow(0 2px 8px rgba(0,0,0,0.6));
      transition: transform 0.3s ease-out;
    }
    .tile-lock svg { width: 100%; height: 100%; display: block; }
    .tile-cta {
      position: absolute;
      bottom: 38px;
      left: 50%;
      transform: translateX(-50%);
      font-size: 0.72rem;
      font-weight: 700;
      letter-spacing: 0.04em;
      color: #fff;
      background: rgba(0,0,0,0.55);
      padding: 6px 10px;
      border-radius: 999px;
      opacity: 0;
      transition: opacity 0.25s ease;
      white-space: nowrap;
      pointer-events: none;
    }
    .tile-caption {
      position: absolute;
      bottom: 8px;
      left: 50%;
      transform: translateX(-50%);
      font-size: 0.65rem;
      font-weight: 600;
      letter-spacing: 0.05em;
      color: rgba(255,255,255,0.85);
      background: rgba(0,0,0,0.45);
      padding: 3px 8px;
      border-radius: 999px;
      white-space: nowrap;
    }
    .tile:focus-visible {
      outline: 2px solid #c084fc;
      outline-offset: 3px;
    }
```

- [ ] **Step 3: Verify in browser**

Refresh `index.html`. You should see a 2×2 grid of dark, blurred squares, each with a centered white lock icon and a small caption pill at the bottom. The "Unlock on OnlyFans" pill is hidden (opacity 0 — we add hover in Task 4). At narrow viewports (<480px), the grid collapses to a single column.

- [ ] **Step 4: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add index.html
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Add hardcoded tile grid with blurred preview + lock"
```

---

## Task 4: Tile hover micro-interactions

**Files:**
- Modify: `index.html` (extend `.tile` CSS with hover/focus states)

- [ ] **Step 1: Add hover/focus CSS**

In [index.html](index.html), inside the `<style>` block, immediately after the `.tile:focus-visible` rule from Task 3, add:

```css
    /* tile hover micro-interactions */
    .tile:hover .tile-image,
    .tile:focus-visible .tile-image {
      filter: blur(8px) brightness(0.7) saturate(1.15);
      transform: scale(1.08);
    }
    .tile:hover .tile-lock,
    .tile:focus-visible .tile-lock {
      transform: translate(-50%, -50%) scale(1.1);
    }
    .tile:hover .tile-cta,
    .tile:focus-visible .tile-cta {
      opacity: 1;
    }
    .tile:hover {
      box-shadow: 0 8px 24px rgba(168,85,247,0.35);
    }
```

- [ ] **Step 2: Verify in browser**

Refresh `index.html`. Hover any tile — the blur should ease off, the lock icon should grow slightly, the "Unlock on OnlyFans →" CTA should fade in above the caption, and the tile should gain a soft purple glow. Tab to the tile (via keyboard) — same effects should fire.

- [ ] **Step 3: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add index.html
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Add tile hover/focus micro-interactions (unblur, lock bounce, CTA reveal)"
```

---

## Task 5: Extend magnetic tilt to tiles

The existing IIFE at the bottom of `index.html` applies magnetic hover to `.btn` only. We extend it to also cover `.tile`.

**Files:**
- Modify: `index.html` (the `<script>` block at the end of `<body>`)

- [ ] **Step 1: Update the magnetic IIFE selector**

In [index.html](index.html), find the existing `<script>` block at the end of `<body>`. The current line is:

```js
      document.querySelectorAll('.btn').forEach(btn => {
```

Change it to:

```js
      document.querySelectorAll('.btn, .tile').forEach(btn => {
```

The rest of the IIFE stays unchanged — `btn` is just a loop variable name and will now also receive `.tile` elements.

- [ ] **Step 2: Verify in browser**

Refresh `index.html`. Move the cursor slowly across each tile — the tile should subtly tilt/translate toward the cursor. On `mouseleave`, the tile should snap back. Existing button magnetic behavior must still work unchanged.

- [ ] **Step 3: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add index.html
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Extend magnetic cursor-follow tilt to gallery tiles"
```

---

## Task 6: Animated gradient text on the wordmark

**Files:**
- Modify: `index.html` (the `h1` CSS rule)

- [ ] **Step 1: Update `h1` rule**

In [index.html](index.html), find the existing `h1` rule. Replace it with:

```css
    h1 {
      font-size: 2rem;
      font-weight: 800;
      letter-spacing: -0.03em;
      background: linear-gradient(135deg, #ffffff 0%, #c084fc 35%, #f472b6 70%, #ffffff 100%);
      background-size: 220% 220%;
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      margin-bottom: 0.35rem;
      line-height: 1.1;
      animation: hue-drift 8s ease-in-out infinite;
    }
    @keyframes hue-drift {
      0%, 100% { background-position: 0% 50%; }
      50%      { background-position: 100% 50%; }
    }
```

- [ ] **Step 2: Verify in browser**

Refresh `index.html`. The "Keith" wordmark should slowly cycle its gradient over 8 seconds — a subtle wash of pink/purple/white shifting horizontally. Effect should be gentle, not distracting.

- [ ] **Step 3: Verify reduced-motion still halts it**

In Chrome DevTools, open the Rendering tab (`Ctrl+Shift+P` → "Show Rendering"). Set "Emulate CSS media feature `prefers-reduced-motion`" to `reduce`. Refresh the page — the gradient should not animate. The existing global `@media (prefers-reduced-motion: reduce)` block already covers this via the `animation-duration: 0.001ms !important` override.

- [ ] **Step 4: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add index.html
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Animate h1 gradient with 8s drift"
```

---

## Task 7: Cursor-following spotlight on the card

**Files:**
- Modify: `index.html` (add CSS pseudo-element on `.card`; extend `<script>` block with mousemove handler)

- [ ] **Step 1: Add spotlight CSS**

In [index.html](index.html), inside the `<style>` block, immediately after the `@keyframes fadeUp` rule, add:

```css
    /* cursor-following spotlight overlay on the card */
    .card::before {
      content: '';
      position: absolute;
      inset: 0;
      border-radius: inherit;
      pointer-events: none;
      z-index: 2;
      background: radial-gradient(circle 220px at var(--mx, 50%) var(--my, 50%), rgba(255,255,255,0.07), transparent 70%);
      opacity: 0;
      transition: opacity 0.3s ease;
    }
    .card.spotlight-on::before { opacity: 1; }
```

- [ ] **Step 2: Add the spotlight JS**

In [index.html](index.html), inside the existing `<script>` block, immediately AFTER the closing `})();` of the magnetic IIFE, add a second IIFE:

```js
    // Cursor-following spotlight on the card — skips touch + reduced-motion users.
    (function () {
      if (!matchMedia('(hover: hover)').matches) return;
      if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;

      const card = document.querySelector('.card');
      if (!card) return;

      card.addEventListener('mousemove', (e) => {
        const r = card.getBoundingClientRect();
        const x = ((e.clientX - r.left) / r.width) * 100;
        const y = ((e.clientY - r.top) / r.height) * 100;
        card.style.setProperty('--mx', `${x}%`);
        card.style.setProperty('--my', `${y}%`);
        card.classList.add('spotlight-on');
      });
      card.addEventListener('mouseleave', () => {
        card.classList.remove('spotlight-on');
      });
    })();
```

- [ ] **Step 3: Verify in browser**

Refresh `index.html`. Move the cursor across the card — a soft circular glow should follow it across the surface. The glow should NOT show on touch devices or under reduced motion. The glow must not interfere with clicking buttons or tiles (the pseudo-element has `pointer-events: none`).

- [ ] **Step 4: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add index.html
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Add cursor-following spotlight glow on card"
```

---

## Task 8: Scroll-triggered reveals

The card is short enough that on a desktop viewport the whole page is visible without scrolling — so reveals will mostly trigger on initial load (once the IntersectionObserver attaches and finds elements already in view). On longer mobile viewports or when the address bar collapses, the gallery may genuinely scroll into view. Either way, the implementation is the same.

**Files:**
- Modify: `index.html` (add `.reveal` class to selected markup; new CSS rules; new IIFE in `<script>` block)

- [ ] **Step 1: Add `.reveal` class to target elements**

In [index.html](index.html), add `class="reveal"` (or merge into existing class lists) on these elements inside the `.exclusive` section:

- `<div class="divider divider-exclusive" role="separator">` → change to `<div class="divider divider-exclusive reveal" role="separator">`
- `<p class="exclusive-tease">` → change to `<p class="exclusive-tease reveal">`
- Each of the four `<a class="tile" …>` opening tags → change to `<a class="tile reveal" …>`

- [ ] **Step 2: Add reveal CSS**

In [index.html](index.html), inside the `<style>` block, immediately AFTER the `@keyframes pulse-ring` rule, add:

```css
    /* scroll-triggered reveals */
    .reveal {
      opacity: 0;
      transform: translateY(20px);
      transition: opacity 0.6s ease, transform 0.6s ease;
    }
    .reveal.in-view {
      opacity: 1;
      transform: translateY(0);
    }
```

- [ ] **Step 3: Add the IntersectionObserver IIFE**

In [index.html](index.html), inside the `<script>` block, immediately AFTER the spotlight IIFE you added in Task 7, add:

```js
    // Scroll-triggered reveals via IntersectionObserver.
    (function () {
      const items = document.querySelectorAll('.reveal');
      if (!items.length) return;

      // Reduced motion: skip the choreography entirely, show items immediately.
      if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
        items.forEach(el => el.classList.add('in-view'));
        return;
      }

      // Stagger tiles only (80ms between them); non-tile reveals get no extra delay.
      const tiles = document.querySelectorAll('.tile.reveal');
      tiles.forEach((tile, i) => {
        tile.style.transitionDelay = `${i * 80}ms`;
      });

      const io = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            entry.target.classList.add('in-view');
            io.unobserve(entry.target);
          }
        });
      }, { threshold: 0.15 });

      items.forEach(el => io.observe(el));
    })();
```

- [ ] **Step 4: Verify in browser**

Refresh `index.html`. The Exclusive divider, tease line, and tiles should fade up from below on first paint (since they enter the viewport immediately). To verify the trigger threshold works, narrow the browser window to a short height (~400px tall) so the gallery is below the fold; reload; scroll down — they should fade up as you scroll. With reduced motion enabled (Task 6 step 3), everything appears instantly with no transition.

- [ ] **Step 5: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add index.html
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Add scroll-triggered reveals for exclusive section + tiles"
```

---

## Task 9: Seed `gallery.json` and replace hardcoded tiles with dynamic render

This is the most significant task — the hardcoded markup from Task 3 gets removed and replaced with JS that renders tiles from a fetched manifest.

**Files:**
- Create: `gallery.json`
- Modify: `index.html` (replace hardcoded tiles with empty container; add render IIFE)

- [ ] **Step 1: Create `gallery.json`**

Create a new file at `C:\Users\keyst\Personal-Landing-Page\gallery.json` with this content:

```json
{
  "items": [
    {
      "image": "/images/profile.png",
      "caption": "20 photos",
      "unlock_url": "https://onlyfans.com/keithbarron199"
    },
    {
      "image": "/images/profile.png",
      "caption": "Video · 4 min",
      "unlock_url": "https://onlyfans.com/keithbarron199"
    },
    {
      "image": "/images/profile.png",
      "caption": "12 photos",
      "unlock_url": "https://onlyfans.com/keithbarron199"
    },
    {
      "image": "/images/profile.png",
      "caption": "Video · 6 min",
      "unlock_url": "https://onlyfans.com/keithbarron199"
    }
  ]
}
```

(We're using `profile.png` as the placeholder image for all four tiles since it already exists. Task 10 swaps in real seed images.)

- [ ] **Step 2: Remove the hardcoded tiles from `index.html`**

In [index.html](index.html), find the `<div class="gallery-grid" id="gallery-grid">` block. Replace ALL of its contents (the four `<a class="tile reveal" …>…</a>` blocks) with just a comment so the container is empty:

```html
      <div class="gallery-grid" id="gallery-grid">
        <!-- populated at runtime from gallery.json -->
      </div>
```

- [ ] **Step 3: Add the gallery render IIFE**

In [index.html](index.html), the gallery render must run BEFORE the magnetic, spotlight, and scroll-reveal IIFEs (so they pick up the dynamically-added tiles). Inside the `<script>` block, immediately AFTER the opening `<script>` tag and BEFORE the magnetic IIFE, insert this async IIFE wrapper that runs render then re-fires the other setups:

```js
    // Gallery render — fetch the manifest, build tiles, then init interactions.
    (async function init() {
      const grid = document.getElementById('gallery-grid');
      if (!grid) return;

      const lockSvg = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>`;

      const DEFAULT_UNLOCK = 'https://onlyfans.com/keithbarron199';

      try {
        const res = await fetch('/gallery.json', { cache: 'no-cache' });
        if (!res.ok) throw new Error(`gallery.json HTTP ${res.status}`);
        const data = await res.json();
        const items = Array.isArray(data.items) ? data.items : [];

        grid.innerHTML = items.map((it, i) => {
          const url = it.unlock_url || DEFAULT_UNLOCK;
          const cap = it.caption ? `<span class="tile-caption" aria-hidden="true">${escapeHtml(it.caption)}</span>` : '';
          const label = it.caption ? `Unlock ${escapeHtml(it.caption)} on OnlyFans` : 'Unlock on OnlyFans';
          return `
            <a class="tile reveal" href="${escapeAttr(url)}" target="_blank" rel="noopener" aria-label="${label}">
              <img class="tile-image" src="${escapeAttr(it.image)}" alt="" aria-hidden="true" />
              <span class="tile-lock" aria-hidden="true">${lockSvg}</span>
              <span class="tile-cta" aria-hidden="true">Unlock on OnlyFans →</span>
              ${cap}
            </a>`;
        }).join('');
      } catch (err) {
        console.error('Gallery render failed:', err);
        grid.innerHTML = '';
      }

      // After the DOM is populated, kick off the interaction setups.
      // The other IIFEs below depend on .tile / .reveal being in the DOM already.
      window.dispatchEvent(new Event('gallery:ready'));
    })();

    function escapeHtml(s) {
      return String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
    }
    function escapeAttr(s) {
      return escapeHtml(s);
    }
```

- [ ] **Step 4: Defer the other IIFEs until `gallery:ready` fires**

The magnetic, spotlight, and scroll-reveal IIFEs currently run at parse time. They need to wait until tiles exist in the DOM. Wrap each of them in a single `window.addEventListener('gallery:ready', ...)` listener. In [index.html](index.html), find the magnetic, spotlight, and scroll-reveal IIFEs (the three immediately following the gallery render IIFE you just added). Wrap all three of them in a single listener:

Before:
```js
    (function () {  // magnetic
      ...
    })();

    (function () {  // spotlight
      ...
    })();

    (function () {  // scroll reveals
      ...
    })();
```

After:
```js
    window.addEventListener('gallery:ready', () => {
      (function () {  // magnetic
        ...
      })();

      (function () {  // spotlight
        ...
      })();

      (function () {  // scroll reveals
        ...
      })();
    });
```

(Keep the inner contents of each IIFE exactly as written — only the wrapper changes.)

- [ ] **Step 5: Start a local HTTP server**

From now on, opening `index.html` directly as `file://` won't work because `fetch('/gallery.json')` requires HTTP. Run:

```powershell
cd C:\Users\keyst\Personal-Landing-Page
python -m http.server 8000
```

Open http://localhost:8000/ in a browser.

- [ ] **Step 6: Verify dynamic render works identically**

The page should look identical to Task 8's state — same 2×2 grid, same blurs, same captions, same hover effects, same magnetic tilt, same spotlight, same reveal. Open DevTools → Network → confirm `gallery.json` was fetched and returned 200. Open Console — no errors.

- [ ] **Step 7: Verify graceful failure**

Temporarily rename `gallery.json` to `gallery.json.bak`, hard-refresh the page. The exclusive section should still render with its heading and tease line, but the grid is empty. Console shows the error from the catch block. Rename back to `gallery.json` after verifying.

- [ ] **Step 8: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add index.html gallery.json
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Render gallery tiles dynamically from gallery.json"
```

---

## Task 10: Seed real placeholder images in `images/gallery/`

Right now all four tiles render `images/profile.png`. We add a proper `images/gallery/` folder with distinct placeholder files so the structure is correct for Decap's media folder convention.

**Files:**
- Create: `images/gallery/.gitkeep`
- Create: `images/gallery/teaser-01.jpg` through `teaser-04.jpg` (as copies of `images/profile.png`)
- Modify: `gallery.json` (point at the new paths)

- [ ] **Step 1: Create the folder + placeholder files**

Run in PowerShell:

```powershell
$src = 'C:\Users\keyst\Personal-Landing-Page\images\profile.png'
$dst = 'C:\Users\keyst\Personal-Landing-Page\images\gallery'
New-Item -ItemType Directory -Force $dst | Out-Null
New-Item -ItemType File -Force "$dst\.gitkeep" | Out-Null
1..4 | ForEach-Object {
  $n = $_.ToString('00')
  Copy-Item $src "$dst\teaser-$n.jpg"
}
```

(Note: the file extension is `.jpg` for Decap's media library convention; the underlying bytes are PNG. Browsers detect format from content, not extension, so this displays correctly.)

- [ ] **Step 2: Update `gallery.json` to use the new paths**

Replace the contents of `C:\Users\keyst\Personal-Landing-Page\gallery.json` with:

```json
{
  "items": [
    {
      "image": "/images/gallery/teaser-01.jpg",
      "caption": "20 photos",
      "unlock_url": "https://onlyfans.com/keithbarron199"
    },
    {
      "image": "/images/gallery/teaser-02.jpg",
      "caption": "Video · 4 min",
      "unlock_url": "https://onlyfans.com/keithbarron199"
    },
    {
      "image": "/images/gallery/teaser-03.jpg",
      "caption": "12 photos",
      "unlock_url": "https://onlyfans.com/keithbarron199"
    },
    {
      "image": "/images/gallery/teaser-04.jpg",
      "caption": "Video · 6 min",
      "unlock_url": "https://onlyfans.com/keithbarron199"
    }
  ]
}
```

- [ ] **Step 3: Verify in browser**

With the local server still running, refresh http://localhost:8000/. The grid should render identically (still blurred profile photo, but now sourced from the new gallery folder). Open DevTools → Network → confirm requests to `/images/gallery/teaser-01.jpg` etc. all return 200.

- [ ] **Step 4: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add images/gallery gallery.json
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Seed images/gallery with 4 placeholder tiles"
```

---

## Task 11: Decap CMS admin page

**Files:**
- Create: `admin/index.html`
- Create: `admin/config.yml`

- [ ] **Step 1: Create `admin/index.html`**

Create a new file at `C:\Users\keyst\Personal-Landing-Page\admin\index.html` with this content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Keith — Content Manager</title>
  <script src="https://identity.netlify.com/v1/netlify-identity-widget.js"></script>
</head>
<body>
  <script src="https://unpkg.com/decap-cms@^3.3.0/dist/decap-cms.js"></script>
</body>
</html>
```

- [ ] **Step 2: Create `admin/config.yml`**

Create a new file at `C:\Users\keyst\Personal-Landing-Page\admin\config.yml` with this content:

```yaml
backend:
  name: git-gateway
  branch: main

media_folder: "images/gallery"
public_folder: "/images/gallery"

publish_mode: simple

collections:
  - name: gallery
    label: "Exclusive Gallery"
    files:
      - name: tiles
        label: "Tiles"
        file: "gallery.json"
        format: "json"
        fields:
          - name: items
            label: "Tiles"
            label_singular: "Tile"
            widget: list
            summary: "{{caption}}"
            fields:
              - { name: image, label: "Preview image", widget: image }
              - { name: caption, label: "Caption (optional)", widget: string, required: false }
              - { name: unlock_url, label: "Unlock URL", widget: string, default: "https://onlyfans.com/keithbarron199" }
```

- [ ] **Step 3: Verify YAML parses (lightweight syntax check)**

Run:

```powershell
python -c "import yaml; print(yaml.safe_load(open(r'C:\Users\keyst\Personal-Landing-Page\admin\config.yml')))"
```

Expected: prints a dict containing `backend`, `collections`, etc. If you get a YAML parse error, fix the indentation.

If Python doesn't have PyYAML installed, skip this and rely on Decap's own validation in the browser (Step 5 below).

- [ ] **Step 4: Verify `/admin` page loads (locally)**

With the local server still running on port 8000, open http://localhost:8000/admin/ in a browser. You'll see Decap's login screen. The login itself won't work locally because Git Gateway needs Netlify infrastructure — that comes in Task 13 after deploy. Console may show identity warnings; that's expected locally.

- [ ] **Step 5: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add admin
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Add Decap CMS admin page and config"
```

---

## Task 12: Reduced-motion and accessibility audit

**Files:**
- Modify (potentially): `index.html` (only if issues are found — none expected)

- [ ] **Step 1: Verify reduced-motion in DevTools**

In Chrome at http://localhost:8000/, open DevTools → `Ctrl+Shift+P` → "Show Rendering" → set "Emulate CSS media feature `prefers-reduced-motion`" to `reduce`. Hard-refresh. Confirm:
- Mesh orbs do not drift
- Avatar ring does not spin
- Live pill dot does not pulse
- h1 gradient does not shift
- Reveals appear immediately (no fade)
- Magnetic tilt: hover a button or tile, no movement
- Cursor spotlight: hover the card, no glow
- Tile hover still WORKS (CSS transitions are 0.001ms so they snap, but unblur/CTA still appear — this is correct, transitions aren't blocked, they're just instant)

If any animation still plays under reduced motion, locate the offending rule and add it to the `@media (prefers-reduced-motion: reduce)` block. None expected — the global override should cover everything via `animation-duration: 0.001ms !important`.

- [ ] **Step 2: Keyboard navigation pass**

With reduced motion still set to `reduce` (or unset, either way), tab through the whole page from top to bottom. Each focusable element (4 social buttons + 4 tiles = 8 total) must show a visible purple outline. Pressing Enter on a tile must open its `unlock_url` in a new tab.

- [ ] **Step 3: Lighthouse accessibility audit**

In Chrome DevTools at http://localhost:8000/, open the Lighthouse tab. Run an Accessibility-only audit (Desktop). Aim for a score of 95+. Common findings to fix if they appear:
- "Image elements do not have `[alt]` attributes" — the tile preview images intentionally have empty `alt=""` because the link's `aria-label` describes the destination; this is correct. If flagged, ignore.
- "Background and foreground colors do not have a sufficient contrast ratio" — most likely target is `.exclusive-tease` at `rgba(255,255,255,0.55)`. If Lighthouse flags it, change to `rgba(255,255,255,0.65)`.
- "Heading elements are not in a sequentially-descending order" — we have an `<h1>` and a `<span id="exclusive-heading">` (deliberately a `<span>` for visual reasons). If flagged, change the span to an `<h2>` and re-style with `font-size`/`font-weight` overrides.

- [ ] **Step 4: Commit any fixes (only if Step 3 surfaced issues)**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add index.html
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Address Lighthouse a11y findings"
```

Skip this commit if no fixes were needed.

---

## Task 13: Deploy + enable Netlify Identity + Git Gateway

**Files:** none changed in this task

- [ ] **Step 1: Push commits to GitHub**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page push origin main
```

Expected: push succeeds. GitHub Pages will redeploy automatically.

- [ ] **Step 2: Deploy to Netlify production**

```powershell
cd C:\Users\keyst\Personal-Landing-Page
netlify deploy --prod --dir .
```

Expected: "Deploy is live" with production URL `https://voluble-sundae-98c2b6.netlify.app` (aliased as https://keithlinks.netlify.app/).

- [ ] **Step 3: Verify the live site**

Visit https://keithlinks.netlify.app/. The Exclusive section + 2×2 tile grid must render. Hover, magnetic, spotlight, and reveals all work. View source — `gallery.json` is fetched and tiles populate.

- [ ] **Step 4: Enable Netlify Identity**

In the Netlify dashboard:
1. Open the `voluble-sundae-98c2b6` site
2. Go to **Site configuration → Identity** (in older UI: top-nav **Identity** tab)
3. Click **Enable Identity**

If Identity is unavailable (button greyed out or error message), STOP and skip to Step 7 (fallback path).

- [ ] **Step 5: Configure Identity + Git Gateway**

1. Identity → Settings → Registration preferences → set to **Invite only**
2. Identity → Services → Git Gateway → click **Enable Git Gateway**
3. Identity → top of page → click **Invite users** → enter `keystonemarcywork@gmail.com` → send

- [ ] **Step 6: Accept the invitation and test `/admin`**

1. Check email at keystonemarcywork@gmail.com for the Netlify invite
2. Click the link, set a password
3. Visit https://keithlinks.netlify.app/admin/
4. Log in with the email + password just set
5. Confirm the "Exclusive Gallery" collection appears
6. Click into "Tiles" → confirm the 4 seed items are visible and editable
7. As a smoke test: edit the caption on tile 1 from "20 photos" to "20 NEW photos", save, publish
8. Wait ~30s for Netlify to redeploy
9. Refresh https://keithlinks.netlify.app/ — confirm the change is live
10. Revert the caption to "20 photos" via Decap and republish

- [ ] **Step 7 (fallback, ONLY if Step 4 failed): GitHub OAuth path**

If Netlify Identity is not available on this site, switch the Decap backend to GitHub OAuth. This is documented at https://decapcms.org/docs/github-backend/ and requires:

1. Creating a GitHub OAuth app at https://github.com/settings/applications/new with the homepage URL `https://keithlinks.netlify.app` and the authorization callback URL pointing at a Netlify Function we'll add
2. Adding a small Netlify Function (`netlify/functions/auth.js` and `netlify/functions/callback.js`) that handles the OAuth handshake — see Decap docs for reference implementation
3. Updating `admin/config.yml` to use `backend: { name: github, repo: kmarcy95/Personal-Landing-Page, branch: main }`

This step is gated on Step 4 failing. If Identity worked, skip this step entirely. If it didn't, treat this as a follow-up sub-task and confirm scope with the user before implementing — the fallback adds ~50 lines of serverless code that isn't in the current spec.

- [ ] **Step 8: Final verification**

Visit https://keithlinks.netlify.app/ in an incognito window (bypasses cache). Confirm:
- Exclusive section renders with 4 tiles
- All hover effects work (magnetic tilt, blur unblur, lock bounce, CTA reveal, card spotlight)
- h1 gradient slowly shifts
- Reveals fire on scroll/load
- All four social buttons still work (Chaturbate, X, IG, OF)
- View source includes new `<meta>` tags from earlier work
- `https://keithlinks.netlify.app/admin/` loads the CMS

---

## Spec Coverage Self-Review

Walked the spec section by section:

| Spec section | Tasks that cover it |
|---|---|
| Goals 1 (gallery below social) | Tasks 2, 3 |
| Goals 2 (Decap CMS managed) | Tasks 9, 11, 13 |
| Goals 3 (four new animations) | Tasks 4, 5, 6, 7, 8 |
| Non-goals (no real paywall) | Honored throughout — no payment code anywhere |
| Page layout (520px card) | Task 1 |
| Tile anatomy (blur, lock, caption, hover CTA) | Tasks 3, 4 |
| Content model (gallery.json shape) | Tasks 9, 10 |
| Animation table (4 effects) | Tasks 4, 5 (tile hover), 6 (gradient), 7 (spotlight), 8 (reveals) |
| File changes table | Tasks 9 (gallery.json), 10 (images/gallery/), 11 (admin/) |
| Decap config (git-gateway, media folder, list widget) | Task 11 |
| One-time manual setup (Identity, Git Gateway, invite) | Task 13 steps 4-6 |
| Accessibility (focus, aria-labels, contrast) | Tasks 3 (aria-labels), 4 (focus-visible), 12 (audit) |
| Risks (Identity deprecation) | Task 13 step 7 (fallback gate) |

No gaps found.

## Placeholder Scan

Scanned plan for "TBD", "TODO", "Add appropriate", "similar to Task N", "fill in details", "implement later" — none present.

## Type/Name Consistency

- `gallery.json` key `items` — used identically in seed (Task 9, 10), config schema (Task 11), and render code (Task 9).
- Field names `image` / `caption` / `unlock_url` — match between gallery.json, config.yml, and render code.
- CSS classes `.tile`, `.tile-image`, `.tile-lock`, `.tile-cta`, `.tile-caption`, `.reveal`, `.in-view`, `.gallery-grid`, `.exclusive`, `.exclusive-tease`, `.divider-exclusive` — used consistently.
- JS event name `gallery:ready` — emitted in Task 9 step 3, listened to in Task 9 step 4.
- Default unlock URL `https://onlyfans.com/keithbarron199` — appears in gallery.json (Tasks 9, 10), Decap config default (Task 11), and render code (Task 9). Calls out the spec's risk about keeping these in sync.

All consistent.
