# Paywall Modal + Video Uploads — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the exclusive-gallery tiles from "click → opens OnlyFans" to "click → opens 'Coming soon' modal with per-tile price"; add video upload support; defer all real payment infrastructure to a later round.

**Architecture:** Single-page vanilla HTML/CSS/JS. Tiles become `<button>` elements with `data-index`. A native `<dialog>` at the end of `<body>` is opened by a click-delegation handler that looks up the tile's data from an in-memory array. Decap CMS schema swaps `image`+`unlock_url` for `media`+`price` and uses Decap's `file` widget (so it accepts both images and videos). No backend changes.

**Tech Stack:** Vanilla HTML/CSS/JS, native `<dialog>` element (Safari 15.4+/all other evergreens), Decap CMS file widget, Netlify static hosting.

**Spec:** [`docs/superpowers/specs/2026-05-17-paywall-modal-and-video-uploads-design.md`](../specs/2026-05-17-paywall-modal-and-video-uploads-design.md)

---

## Working environment

- Repo path: `C:\Users\keyst\Personal-Landing-Page`
- Local preview (required for verifying fetch behavior):
  ```powershell
  cd C:\Users\keyst\Personal-Landing-Page
  python -m http.server 8000
  ```
  Then open http://localhost:8000/.
- The repo is on branch `main`; commits go straight to main (matches the established pattern).
- Deploy to Netlify happens in Task 5 via `netlify deploy --prod --dir .`.

---

## File structure

**Modified files:**
- `index.html` — modal markup at end of `<body>`, new modal CSS in `<style>`, expanded render IIFE, new modal-handling IIFE
- `gallery.json` — items reshaped to `{ media, caption, price }`
- `admin/config.yml` — fields list updated

**No new files. No new directories.**

The 4 existing seed images in `images/gallery/` continue to work — only their JSON record changes.

---

## Task 1: Migrate `gallery.json` + update Decap CMS schema

**Files:**
- Modify: `gallery.json`
- Modify: `admin/config.yml`

- [ ] **Step 1: Rewrite `gallery.json`**

Replace the contents of `C:\Users\keyst\Personal-Landing-Page\gallery.json` with:

```json
{
  "items": [
    {
      "media": "/images/gallery/teaser-01.jpg",
      "caption": "20 photos",
      "price": 10
    },
    {
      "media": "/images/gallery/teaser-02.jpg",
      "caption": "Video · 4 min",
      "price": 15
    },
    {
      "media": "/images/gallery/teaser-03.jpg",
      "caption": "12 photos",
      "price": 8
    },
    {
      "media": "/images/gallery/teaser-04.jpg",
      "caption": "Video · 6 min",
      "price": 20
    }
  ]
}
```

Note: the existing seed images are still `.jpg` files (image type). Captions are kept identical to the previous shape so they continue to feel consistent. Placeholder prices are: $10, $15, $8, $20.

- [ ] **Step 2: Validate the JSON**

```powershell
python -m json.tool C:\Users\keyst\Personal-Landing-Page\gallery.json
```

Expected: prints the formatted JSON without errors.

- [ ] **Step 3: Update `admin/config.yml`**

In `C:\Users\keyst\Personal-Landing-Page\admin\config.yml`, find the existing `fields` list under the `items` widget:

```yaml
            fields:
              - { name: image, label: "Preview image", widget: image }
              - { name: caption, label: "Caption (optional)", widget: string, required: false }
              - { name: unlock_url, label: "Unlock URL", widget: string, default: "https://onlyfans.com/keithbarron199" }
```

Replace those three lines with:

```yaml
            fields:
              - { name: media, label: "Media (photo or short video, max 25MB)", widget: file, allow_multiple: false }
              - { name: caption, label: "Caption (optional)", widget: string, required: false }
              - { name: price, label: "Price (USD, whole dollars)", widget: number, value_type: int, min: 1, default: 10 }
```

Leave the rest of the file unchanged (backend, media_folder, collection name, etc).

- [ ] **Step 4: Validate YAML**

```powershell
python -c "import yaml; print(yaml.safe_load(open(r'C:\Users\keyst\Personal-Landing-Page\admin\config.yml')))"
```

Expected: prints a dict; no parse error. (If `pyyaml` is missing, install via `pip install pyyaml`; if pip is unavailable, skip — Decap will validate in-browser later.)

- [ ] **Step 5: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add gallery.json admin/config.yml
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Migrate gallery schema to media+price (drops unlock_url)"
```

---

## Task 2: Add `<dialog>` modal markup + modal CSS

**Files:**
- Modify: `index.html` (new modal element at end of `<body>`; new CSS block inside `<style>`)

- [ ] **Step 1: Insert the dialog markup**

In `index.html`, find the closing `</main>` (the one closing `<main class="card">`). Immediately AFTER `</main>` and BEFORE the `<script>` tag at the end of `<body>`, insert:

```html
  <dialog id="tile-modal" class="modal" aria-labelledby="modal-title">
    <button class="modal-close" type="button" aria-label="Close">×</button>
    <div class="modal-media" id="modal-media"><!-- img or video injected --></div>
    <h2 class="modal-title" id="modal-title">Locked content</h2>
    <p class="modal-price" id="modal-price">$0 to unlock</p>
    <div class="modal-status">Purchases coming soon</div>
    <p class="modal-followup">Follow <a href="https://x.com/Keithbarron3333" target="_blank" rel="noopener noreferrer">@Keithbarron3333</a> on X for launch updates &rarr;</p>
  </dialog>
```

- [ ] **Step 2: Add modal CSS**

In `index.html`, inside the `<style>` block, immediately AFTER the existing `@media (prefers-reduced-motion: reduce) { … }` block (this is near the end of the style block), add:

```css
    /* paywall modal */
    .modal {
      border: none;
      padding: 0;
      background: transparent;
      color: #fff;
      max-width: 420px;
      width: calc(100% - 2rem);
      max-height: 90vh;
      overflow: hidden;
      border-radius: 18px;
    }
    .modal::backdrop {
      background: rgba(0, 0, 0, 0.78);
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
    }
    .modal[open] {
      display: flex;
      flex-direction: column;
      background: #15151d;
      padding: 1.5rem;
      box-shadow: 0 20px 60px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.06);
      animation: modal-in 0.25s ease both;
    }
    @keyframes modal-in {
      from { opacity: 0; transform: translateY(20px) scale(0.97); }
      to   { opacity: 1; transform: translateY(0)    scale(1); }
    }
    .modal-close {
      position: absolute;
      top: 12px;
      right: 12px;
      width: 32px;
      height: 32px;
      border-radius: 999px;
      background: rgba(255,255,255,0.1);
      color: #fff;
      border: none;
      font-size: 1.2rem;
      line-height: 1;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: background 0.18s ease;
    }
    .modal-close:hover { background: rgba(255,255,255,0.2); }
    .modal-close:focus-visible {
      outline: 2px solid #c084fc;
      outline-offset: 2px;
    }
    .modal-media {
      width: 100%;
      aspect-ratio: 1 / 1;
      border-radius: 12px;
      overflow: hidden;
      background: #1a1035;
      margin-bottom: 1rem;
    }
    .modal-media-el {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
      filter: blur(22px) brightness(0.6) saturate(1.1);
      transform: scale(1.15);
    }
    .modal-title {
      font-size: 1.1rem;
      font-weight: 700;
      margin-bottom: 0.25rem;
      letter-spacing: -0.01em;
    }
    .modal-price {
      font-size: 0.95rem;
      font-weight: 600;
      color: rgba(255,255,255,0.75);
      margin-bottom: 1rem;
    }
    .modal-status {
      background: linear-gradient(135deg, #7c3aed, #db2777);
      color: #fff;
      font-size: 0.85rem;
      font-weight: 700;
      letter-spacing: 0.04em;
      text-align: center;
      padding: 0.7rem 1rem;
      border-radius: 10px;
      margin-bottom: 1rem;
      text-transform: uppercase;
    }
    .modal-followup {
      font-size: 0.78rem;
      color: rgba(255,255,255,0.6);
      text-align: center;
    }
    .modal-followup a {
      color: #c084fc;
      text-decoration: none;
      font-weight: 600;
    }
    .modal-followup a:hover { text-decoration: underline; }
```

- [ ] **Step 3: Verify in browser**

Start the local server (if not already running):
```powershell
cd C:\Users\keyst\Personal-Landing-Page
python -m http.server 8000
```

Open http://localhost:8000/. The modal isn't visible yet (nothing opens it). Open DevTools console and run:
```js
document.getElementById('tile-modal').showModal()
```

Expected: A dark centered card appears with the close X in the corner, an empty media block, "Locked content" title, "$0 to unlock" price, the "Purchases coming soon" gradient badge, and the "Follow @Keithbarron3333" link. Press Esc to close.

- [ ] **Step 4: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add index.html
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Add paywall modal markup and styling"
```

---

## Task 3: Refactor render IIFE for new schema + buttons + media type detection

**Files:**
- Modify: `index.html` (rewrite the gallery render IIFE inside `<script>`)

- [ ] **Step 1: Locate the existing render IIFE**

In `index.html`, inside the `<script>` block at the end of `<body>`, find the existing async render IIFE. It currently starts with:
```js
    // Gallery render — fetch the manifest, build tiles, then init interactions.
    (async function init() {
```
and ends with:
```js
      window.dispatchEvent(new Event('gallery:ready'));
    })();
```

You will REPLACE the entire IIFE (from the comment to the closing `})();`).

- [ ] **Step 2: Add a script-scope `galleryItems` variable**

The modal handler in Task 4 needs to read the tiles' data on click. We make it a module-scope `let` so the render IIFE can populate it and the modal IIFE can read it.

Immediately ABOVE the render IIFE comment (one blank line above), add:

```js
    // In-memory tile data, populated by the render IIFE and read by the modal IIFE.
    let galleryItems = [];

```

- [ ] **Step 3: Replace the render IIFE**

Replace the entire existing render IIFE with this new version:

```js
    // Gallery render — fetch manifest, detect media types, build button tiles.
    (async function init() {
      const grid = document.getElementById('gallery-grid');
      if (!grid) return;

      const lockSvg = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>`;
      const playSvg = `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>`;
      const VIDEO_EXTS = /\.(mp4|webm)(\?|$)/i;

      try {
        const res = await fetch('/gallery.json', { cache: 'no-cache' });
        if (!res.ok) throw new Error(`gallery.json HTTP ${res.status}`);
        const data = await res.json();
        galleryItems = Array.isArray(data.items) ? data.items : [];

        grid.innerHTML = galleryItems.map((it, i) => {
          const mediaPath = it.media || '';
          const isVideo = VIDEO_EXTS.test(mediaPath);
          const mediaEl = isVideo
            ? `<video class="tile-image" preload="metadata" muted playsinline aria-hidden="true"><source src="${safeUrl(mediaPath)}" /></video>`
            : `<img class="tile-image" src="${safeUrl(mediaPath)}" alt="" aria-hidden="true" />`;
          const videoIcon = isVideo
            ? `<span class="tile-video-indicator" aria-hidden="true">${playSvg}</span>`
            : '';
          const cap = it.caption ? `<span class="tile-caption" aria-hidden="true">${escapeHtml(it.caption)}</span>` : '';
          const priceNum = Number(it.price) || 0;
          const priceText = `$${priceNum}`;
          const labelParts = ['Unlock'];
          if (it.caption) labelParts.push(it.caption);
          labelParts.push(`— ${priceText}`);
          const label = labelParts.join(' ');
          return `
            <button type="button" class="tile reveal" data-index="${i}" aria-haspopup="dialog" aria-label="${escapeAttr(label)}">
              ${mediaEl}
              ${videoIcon}
              <span class="tile-lock" aria-hidden="true">${lockSvg}</span>
              <span class="tile-cta" aria-hidden="true">&#x1F512; ${escapeHtml(priceText)}</span>
              ${cap}
            </button>`;
        }).join('');
      } catch (err) {
        console.error('Gallery render failed:', err);
        grid.innerHTML = '';
      }

      window.dispatchEvent(new Event('gallery:ready'));
    })();
```

- [ ] **Step 4: Add CSS for the video indicator**

The new render IIFE outputs `<span class="tile-video-indicator">` for video tiles, but the CSS doesn't style it yet. In the `<style>` block, immediately AFTER the existing `.tile:focus-visible` rule (and BEFORE the `.tile:hover .tile-image,` block from Task 4 of the prior plan), add:

```css
    .tile-video-indicator {
      position: absolute;
      top: 8px;
      right: 8px;
      width: 22px;
      height: 22px;
      padding: 4px;
      background: rgba(0, 0, 0, 0.55);
      border-radius: 50%;
      color: #fff;
      z-index: 1;
      pointer-events: none;
    }
    .tile-video-indicator svg {
      width: 100%;
      height: 100%;
      display: block;
    }
```

- [ ] **Step 5: Verify in browser**

Hard-refresh http://localhost:8000/. The 4 tiles should render with:
- Same blurred preview as before
- A new dark price pill at the bottom showing 🔒 $10, 🔒 $15, 🔒 $8, 🔒 $20 (replacing the "Unlock on OnlyFans →" text)
- No video play indicators (all 4 seed items are images)
- Hovering still produces the unblur + lock bounce + magnetic tilt
- Clicking a tile does NOTHING for now — the modal wiring comes in Task 4

Sanity check tile element type by running in the console:
```js
document.querySelectorAll('.tile')[0].tagName
```
Expected: `"BUTTON"` (was `"A"` before).

To test the video code path, temporarily edit `gallery.json` and change the first item's `media` to `/videos/sample.mp4`. The tile should now contain a `<video>` element with a play indicator in the corner (broken video icon because the file doesn't exist — fine, we're just verifying the render branch). Revert the change before committing.

- [ ] **Step 6: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add index.html
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Render tiles as buttons; support video media; show per-tile price"
```

---

## Task 4: Wire up modal open/close behavior

**Files:**
- Modify: `index.html` (new IIFE at end of `<script>` block, before `</script>`)

This task adds a fourth IIFE that handles:
- Click delegation on `#gallery-grid` → opens modal with the clicked tile's data
- Close button click → closes modal
- Backdrop click → closes modal
- After-close cleanup: clear media, restore body scroll, return focus

The modal IIFE does NOT need to wait for `gallery:ready` — `#gallery-grid` exists at parse time even when empty, and event delegation works on future descendants. So we add this IIFE at the script top-level, alongside the render IIFE and helpers.

- [ ] **Step 1: Add the modal IIFE**

In `index.html`, inside the `<script>` block, immediately AFTER the existing `safeUrl` function definition (added in Task 9 of the previous plan), and BEFORE the `window.addEventListener('gallery:ready', () => {` block, add:

```js
    // Modal handler — click tile → open dialog with price + "coming soon" message.
    (function setupModal() {
      const dialog = document.getElementById('tile-modal');
      if (!dialog) return;
      const grid = document.getElementById('gallery-grid');
      if (!grid) return;

      const closeBtn = dialog.querySelector('.modal-close');
      const mediaSlot = document.getElementById('modal-media');
      const titleSlot = document.getElementById('modal-title');
      const priceSlot = document.getElementById('modal-price');
      const VIDEO_EXTS = /\.(mp4|webm)(\?|$)/i;
      let lastFocused = null;

      function openModal(item, triggerEl) {
        lastFocused = triggerEl;
        titleSlot.textContent = item.caption || 'Locked content';
        const priceNum = Number(item.price) || 0;
        priceSlot.textContent = `$${priceNum} to unlock`;

        const mediaPath = item.media || '';
        const isVideo = VIDEO_EXTS.test(mediaPath);
        if (isVideo) {
          mediaSlot.innerHTML = `<video class="modal-media-el" preload="metadata" muted playsinline><source src="${safeUrl(mediaPath)}" /></video>`;
        } else {
          mediaSlot.innerHTML = `<img class="modal-media-el" src="${safeUrl(mediaPath)}" alt="" />`;
        }

        document.body.style.overflow = 'hidden';
        dialog.showModal();
      }

      // Click delegation on the grid — opens modal for the clicked tile.
      grid.addEventListener('click', (e) => {
        const tile = e.target.closest('.tile');
        if (!tile || !grid.contains(tile)) return;
        const i = parseInt(tile.dataset.index, 10);
        const item = galleryItems[i];
        if (!item) return;
        openModal(item, tile);
      });

      // Explicit close button.
      closeBtn.addEventListener('click', () => dialog.close());

      // Backdrop click — dialog element fills the viewport; clicks on inner content don't bubble to dialog itself.
      dialog.addEventListener('click', (e) => {
        if (e.target === dialog) dialog.close();
      });

      // Cleanup after close (close event fires for both .close() and Esc).
      dialog.addEventListener('close', () => {
        mediaSlot.innerHTML = '';
        document.body.style.overflow = '';
        if (lastFocused) {
          lastFocused.focus();
          lastFocused = null;
        }
      });
    })();
```

- [ ] **Step 2: Verify modal opens on tile click**

Refresh http://localhost:8000/. Click any tile. Expected:
- Modal opens with smooth fade-in
- Modal title shows the tile's caption (e.g., "20 photos")
- Price shows correct amount (e.g., "$10 to unlock")
- Media slot shows the blurred image
- Backdrop is dark/blurred behind the modal
- Page content behind the backdrop is not interactive (try clicking buttons through the backdrop)

- [ ] **Step 3: Verify close behaviors**

With the modal open, test all three close paths:
1. Click the X button → modal closes; focus returns to the originally-clicked tile (verify by tabbing or checking `document.activeElement`)
2. Press Esc → modal closes; focus returns to the tile
3. Click on the dark backdrop area (NOT on the modal card itself) → modal closes; focus returns to the tile

After close, verify:
- Body scroll is restored (try scrolling the page)
- The `<img>` inside the modal media slot is removed (check via DevTools: `document.getElementById('modal-media').innerHTML` should be `""`)

- [ ] **Step 4: Keyboard-only test**

Press Tab repeatedly from the page top. Verify:
- All 4 tiles are reachable via keyboard with visible focus outline
- Pressing Enter on a focused tile opens the modal
- While modal is open, focus is trapped inside it (Tab cycles through close button → modal links → back to close)
- Pressing Esc closes; focus returns to the tile

- [ ] **Step 5: Reduced-motion verification**

In Chrome DevTools → `Ctrl+Shift+P` → "Show Rendering" → set `prefers-reduced-motion` to `reduce`. Hard-refresh. Click a tile:
- Modal should still open (instantly, no fade-in animation) thanks to the existing `@media (prefers-reduced-motion: reduce) { animation-duration: 0.001ms !important }` global override

- [ ] **Step 6: Commit**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page add index.html
git -C C:\Users\keyst\Personal-Landing-Page commit -m "Wire tile clicks to paywall modal with focus management"
```

---

## Task 5: Final verification + deploy

**Files:** none changed

- [ ] **Step 1: Cross-cutting sanity checks**

With the local server running at http://localhost:8000/, verify holistically:

1. All previous-round features still work:
   - Gradient h1 still cycles
   - Card spotlight still follows cursor
   - Scroll reveals still fire
   - Magnetic tilt still works on buttons AND tiles
   - Tile hover micro-interactions still happen (unblur, lock bounce, CTA opacity)
   - Social buttons (Chaturbate, X, IG, OF) still open in new tabs
   - `/admin` still renders the Decap CMS login

2. New modal-specific checks:
   - All 4 tiles open the modal with their own caption + price
   - Backdrop blur looks right (page content should be visibly blurred behind the modal)
   - Modal looks good on a narrow viewport (resize browser to ~360px wide — modal stretches to fit with `width: calc(100% - 2rem)`)

3. Console is clean — no errors on page load or on any interaction.

- [ ] **Step 2: Push commits**

```powershell
git -C C:\Users\keyst\Personal-Landing-Page push origin main
```

Expected: push succeeds.

- [ ] **Step 3: Deploy to Netlify production**

```powershell
cd C:\Users\keyst\Personal-Landing-Page
netlify deploy --prod --dir .
```

Expected: "Deploy is live" with the production URL.

- [ ] **Step 4: Verify the live deployment**

```powershell
$site = (Invoke-WebRequest -Uri 'https://keithlinks.netlify.app/' -UseBasicParsing).Content
"size: $($site.Length)"
"has 'tile-modal': $(if ($site -match 'tile-modal') { 'YES' } else { 'NO' })"
"has 'modal-status': $(if ($site -match 'modal-status') { 'YES' } else { 'NO' })"
"has 'aria-haspopup': $(if ($site -match 'aria-haspopup') { 'YES' } else { 'NO' })"
"has 'galleryItems': $(if ($site -match 'galleryItems') { 'YES' } else { 'NO' })"

$gj = (Invoke-WebRequest -Uri 'https://keithlinks.netlify.app/gallery.json' -UseBasicParsing).Content
$parsed = $gj | ConvertFrom-Json
"items count: $($parsed.items.Count)"
"first item price: $($parsed.items[0].price)"
"first item media: $($parsed.items[0].media)"
```

Expected: all `YES`, items count is 4, first price is 10, first media is `/images/gallery/teaser-01.jpg`.

- [ ] **Step 5: Browser smoke test on live URL**

Open https://keithlinks.netlify.app/ in an incognito window (bypasses cache). Confirm:
- Page renders with the gallery
- Clicking a tile opens the modal
- All previously-working features still work
- No console errors

---

## Spec Coverage Self-Review

Walked the spec section by section:

| Spec section | Tasks that cover it |
|---|---|
| Goals 1 (tiles → modal with price) | Tasks 3, 4 |
| Goals 2 (CMS accepts photos + short videos) | Task 1 |
| Goals 3 (defer real paywall infra) | Honored throughout — no Stripe/Cloudinary/backend code added |
| Non-goals (no payment, no access control, no poster gen, no analytics, no backend) | Honored throughout |
| "What changes" table (button, fields, media type, CTA, click, safeUrl, rel, aria-label) | Tasks 1, 3, 4 |
| Tile rendering (image vs video detection) | Task 3 |
| Tile interaction (button + data-index + click delegation) | Tasks 3, 4 |
| Modal design (dialog markup, styling, interactions) | Task 2 (markup+CSS), Task 4 (behavior) |
| Modal a11y (aria-labelledby, focus return, close handlers) | Task 4 |
| Content model (gallery.json shape) | Task 1 |
| Decap CMS config (field schema) | Task 1 |
| File changes (no new files, no new dirs) | Tasks 1-4 |
| Risks (large video, dialog browser support, video bandwidth) | Acknowledged in spec; verification steps cover what we can test client-side |
| Deferred work ("real paywall later") | Explicitly out of scope |

No gaps.

## Placeholder Scan

Scanned plan for "TBD", "TODO", "Add appropriate", "fill in details", "similar to Task N" — none present. Every step has either complete code blocks or exact PowerShell commands.

## Type/Name Consistency

- JSON field names `media` / `caption` / `price` — match between `gallery.json` (Task 1), Decap config `admin/config.yml` (Task 1), render IIFE (Task 3), and modal IIFE (Task 4).
- Variable `galleryItems` — declared in Task 3 Step 2, populated in Task 3 Step 3, read in Task 4 Step 1.
- DOM IDs `tile-modal`, `modal-media`, `modal-title`, `modal-price` — defined in Task 2 markup, queried in Task 4 JS.
- CSS class names `modal`, `modal-close`, `modal-media`, `modal-media-el`, `modal-title`, `modal-price`, `modal-status`, `modal-followup`, `tile-video-indicator` — consistent between Task 2 (CSS), Task 3 (renders `tile-video-indicator` and `modal-media-el`), and Task 4 (queries `modal-close`, `modal-media`, etc.).
- Regex `VIDEO_EXTS = /\.(mp4|webm)(\?|$)/i` — same definition in Task 3 (render IIFE) and Task 4 (modal IIFE).
- Helper functions `escapeHtml`, `escapeAttr`, `safeUrl` — all pre-existing from the previous plan, used by Tasks 3 and 4.

All consistent.
