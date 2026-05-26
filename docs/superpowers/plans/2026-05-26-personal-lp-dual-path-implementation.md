# Dual-Path Conversion & Premium Pass — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the hero around two equal CTAs (Chaturbate / OnlyFans), add Schedule + Testimonials sections, swap in real WebP teasers, add a sticky mobile CTA, and ship SEO/OG basics — without changing the dark/violet theme or adding a build step.

**Architecture:** Single-file vanilla HTML/CSS/JS in `index.html`. Existing three IIFEs (gallery render, modal, scroll-reveal) gain four new siblings: Bio, Schedule, Hero LIVE-state listener, Testimonials. A simple `schedule:state` custom event decouples the schedule computation from the hero pulse and the sticky bar. Three new JSON data files (`schedule.json`, `testimonials.json`, `bio.json`) sit at repo root and are Decap-editable.

**Tech Stack:** Vanilla HTML/CSS/JS, native `<dialog>`, IntersectionObserver, `Intl.DateTimeFormat`, sharp (Node, dev-only) for WebP, PowerShell + System.Drawing for the OG share card, Netlify static hosting + Decap CMS.

**Spec:** [`docs/superpowers/specs/2026-05-26-personal-lp-dual-path-design.md`](../specs/2026-05-26-personal-lp-dual-path-design.md)

---

## Working environment

- Repo: `C:\Users\keyst\Personal-Landing-Page` (branch `main`).
- Local preview (required for verifying `fetch()` of JSON files — `file://` won't work):
  ```powershell
  cd C:\Users\keyst\Personal-Landing-Page
  python -m http.server 8000
  ```
  Then open http://localhost:8000/.
- Node 18+ available globally (for `tools/optimize-images.js` via `sharp`).
- Image-pipeline `node_modules` lives under `tools/` and is gitignored — `sharp` is dev-only and must NOT ship to Netlify.
- Commits go straight to `main` (per project convention). Push only when the user authorizes it.
- Deploy via `netlify deploy --prod --dir .` from repo root (Task 14).

---

## File structure

**New files:**
- `schedule.json` — weekly recurring slots + date overrides
- `testimonials.json` — fan quote list
- `bio.json` — hero subtitle + tagline
- `images/profile.webp` (+ `profile@2x.webp`) — compressed avatar
- `images/gallery/teaser-0{1..4}.webp` — real teasers (user provides sources)
- `images/og.png` — 1200×630 branded share card
- `tools/optimize-images.js` — sharp pipeline (dev-only)
- `tools/package.json` + `tools/package-lock.json` — sharp dep manifest
- `scripts/make-og.ps1` — System.Drawing OG card generator (dev-only)
- `sitemap.xml`, `robots.txt`

**Modified files:**
- `index.html` — every section: hero HTML/CSS rewrite, new Schedule + Testimonials sections, sticky mobile bar, FAQ refresh, footer DM link, `<head>` (preload + JSON-LD + canonical), four new IIFEs.
- `gallery.json` — `media` paths repointed to `.webp`
- `admin/config.yml` — three new collections (`schedule`, `testimonials`, `bio`)
- `.gitignore` — add `tools/node_modules/`
- `images/profile.png` — DELETED (replaced by `profile.webp`)
- `images/gallery/teaser-0{1..4}.jpg` — DELETED (replaced by `.webp`)

**Why these boundaries:** Each new section (Schedule, Testimonials) gets its own IIFE so concerns don't tangle. The bio IIFE is split out (not folded into hero markup) so the hero stays editable in code without a CMS roundtrip. The image pipeline lives under `tools/` so production assets stay clean and `sharp` never ships to Netlify.

---

## Task 1: Add data files + Decap CMS collections + .gitignore

**Files:**
- Create: `schedule.json`, `testimonials.json`, `bio.json`, `.gitignore`
- Modify: `admin/config.yml`

- [ ] **Step 1: Create `schedule.json`**

Write to `C:\Users\keyst\Personal-Landing-Page\schedule.json`:

```json
{
  "tz": "America/Chicago",
  "slots": [
    { "day": "Mon", "start": "21:00", "end": "23:30" },
    { "day": "Wed", "start": "21:00", "end": "23:30" },
    { "day": "Fri", "start": "22:00", "end": "01:00" }
  ],
  "overrides": []
}
```

(User can replace these slots with their real schedule via the CMS later. Times in 24-hour, local to `tz`.)

- [ ] **Step 2: Create `testimonials.json`**

Write to `C:\Users\keyst\Personal-Landing-Page\testimonials.json`:

```json
{
  "items": [
    { "quote": "Caught his live last night — best $20 I've spent all month.", "handle": "@fan_one" },
    { "quote": "The OF library is wild. Worth every penny.", "handle": "@fan_two" },
    { "quote": "Real, raw, and actually responds in chat. Rare these days.", "handle": "Fan from X" }
  ]
}
```

(Placeholders only — user will swap to real quotes via the CMS.)

- [ ] **Step 3: Create `bio.json`**

Write to `C:\Users\keyst\Personal-Landing-Page\bio.json`:

```json
{
  "subtitle": "Welcome to my world",
  "tagline": "Live on cam most nights · Full library on OnlyFans · Real moments, daddy energy"
}
```

- [ ] **Step 4: Create `.gitignore`**

Write to `C:\Users\keyst\Personal-Landing-Page\.gitignore`:

```
# Dev-only image pipeline — never ships to Netlify
tools/node_modules/

# Local Netlify CLI artifacts
.netlify/

# OS noise
.DS_Store
Thumbs.db
```

- [ ] **Step 5: Update `admin/config.yml` with three new collections**

Replace the entire contents of `C:\Users\keyst\Personal-Landing-Page\admin\config.yml` with:

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
              - { name: media, label: "Media (photo or short video, max 25MB)", widget: file, allow_multiple: false }
              - { name: caption, label: "Caption (optional)", widget: string, required: false }
              - { name: price, label: "Price (USD, whole dollars)", widget: number, value_type: int, min: 1, default: 10 }

  - name: schedule
    label: "Stream Schedule"
    files:
      - name: weekly
        label: "Weekly schedule"
        file: "schedule.json"
        format: "json"
        fields:
          - { name: tz, label: "Home timezone (IANA, e.g. America/Chicago)", widget: string, default: "America/Chicago" }
          - name: slots
            label: "Weekly recurring slots"
            label_singular: "Slot"
            widget: list
            summary: "{{day}} {{start}}-{{end}}"
            fields:
              - { name: day, label: "Day", widget: select, options: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"] }
              - { name: start, label: "Start (24h, HH:MM)", widget: string, pattern: ['^\d{2}:\d{2}$', "Use HH:MM"] }
              - { name: end, label: "End (24h, HH:MM)", widget: string, pattern: ['^\d{2}:\d{2}$', "Use HH:MM"] }
          - name: overrides
            label: "One-off overrides (cancel a day)"
            label_singular: "Override"
            widget: list
            required: false
            summary: "{{date}}"
            fields:
              - { name: date, label: "Date (YYYY-MM-DD)", widget: string, pattern: ['^\d{4}-\d{2}-\d{2}$', "Use YYYY-MM-DD"] }
              - { name: off, label: "Cancelled?", widget: boolean, default: true }
              - { name: note, label: "Note (optional)", widget: string, required: false }

  - name: testimonials
    label: "Testimonials"
    files:
      - name: list
        label: "Fan quotes"
        file: "testimonials.json"
        format: "json"
        fields:
          - name: items
            label: "Quotes"
            label_singular: "Quote"
            widget: list
            summary: "{{quote}}"
            fields:
              - { name: quote, label: "Quote (max ~200 chars)", widget: string, pattern: ['^.{1,200}$', "Keep under 200 characters"] }
              - { name: handle, label: "Handle or attribution (optional)", widget: string, required: false }

  - name: bio
    label: "Hero copy"
    files:
      - name: bio
        label: "Bio"
        file: "bio.json"
        format: "json"
        fields:
          - { name: subtitle, label: "Eyebrow (small line above wordmark)", widget: string }
          - { name: tagline, label: "Tagline (single line under wordmark)", widget: string }
```

- [ ] **Step 6: Validate JSON + YAML**

```powershell
python -m json.tool C:\Users\keyst\Personal-Landing-Page\schedule.json
python -m json.tool C:\Users\keyst\Personal-Landing-Page\testimonials.json
python -m json.tool C:\Users\keyst\Personal-Landing-Page\bio.json
python -c "import yaml; yaml.safe_load(open(r'C:\Users\keyst\Personal-Landing-Page\admin\config.yml'))"
```

Expected: each prints/parses without error. (If pyyaml is missing: `pip install pyyaml`.)

- [ ] **Step 7: Commit**

```powershell
git add schedule.json testimonials.json bio.json .gitignore admin/config.yml
git -c commit.gpgsign=false commit -m "Add schedule/testimonials/bio data files and CMS collections"
```

---

## Task 2: Set up `tools/optimize-images.js` (sharp pipeline)

**Files:**
- Create: `tools/package.json`, `tools/optimize-images.js`

- [ ] **Step 1: Create `tools/package.json`**

```powershell
New-Item -ItemType Directory -Force -Path C:\Users\keyst\Personal-Landing-Page\tools | Out-Null
```

Then write `C:\Users\keyst\Personal-Landing-Page\tools\package.json`:

```json
{
  "private": true,
  "name": "personal-lp-tools",
  "description": "Dev-only image pipeline. Never ships to Netlify.",
  "scripts": {
    "optimize": "node optimize-images.js"
  },
  "dependencies": {
    "sharp": "^0.33.0"
  }
}
```

- [ ] **Step 2: Create `tools/optimize-images.js`**

Write `C:\Users\keyst\Personal-Landing-Page\tools\optimize-images.js`:

```javascript
// Dev-only image pipeline. Reads sources from ../_image-sources/ (gitignored),
// writes optimized WebP into ../images/. Idempotent — safe to re-run.
//
// Convention:
//   _image-sources/profile.<ext>           -> images/profile.webp (480x480) + images/profile@2x.webp (960x960)
//   _image-sources/gallery/teaser-NN.<ext> -> images/gallery/teaser-NN.webp (600x800, fit=cover)

const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const ROOT = path.resolve(__dirname, '..');
const SRC = path.join(ROOT, '_image-sources');
const OUT_IMAGES = path.join(ROOT, 'images');
const OUT_GALLERY = path.join(OUT_IMAGES, 'gallery');

const PROFILE_QUALITY = 82;
const TEASER_QUALITY = 75;

function fmtKb(bytes) { return (bytes / 1024).toFixed(1) + ' KB'; }

function findSource(stem) {
  const exts = ['.jpg', '.jpeg', '.png', '.webp'];
  for (const ext of exts) {
    const p = path.join(SRC, stem + ext);
    if (fs.existsSync(p)) return p;
  }
  return null;
}

function findGallerySource(stem) {
  const exts = ['.jpg', '.jpeg', '.png', '.webp'];
  for (const ext of exts) {
    const p = path.join(SRC, 'gallery', stem + ext);
    if (fs.existsSync(p)) return p;
  }
  return null;
}

async function processProfile() {
  const src = findSource('profile');
  if (!src) {
    console.log('SKIP profile: no _image-sources/profile.{jpg,png,webp} found');
    return;
  }
  const variants = [
    { out: path.join(OUT_IMAGES, 'profile.webp'),    size: 480 },
    { out: path.join(OUT_IMAGES, 'profile@2x.webp'), size: 960 },
  ];
  for (const v of variants) {
    await sharp(src)
      .resize(v.size, v.size, { fit: 'cover' })
      .webp({ quality: PROFILE_QUALITY })
      .toFile(v.out);
    const bytes = fs.statSync(v.out).size;
    console.log(`OK  ${path.relative(ROOT, v.out)}  (${fmtKb(bytes)})`);
  }
}

async function processTeasers() {
  for (let i = 1; i <= 4; i++) {
    const stem = 'teaser-' + String(i).padStart(2, '0');
    const src = findGallerySource(stem);
    if (!src) {
      console.log(`SKIP ${stem}: no _image-sources/gallery/${stem}.{jpg,png,webp} found`);
      continue;
    }
    const out = path.join(OUT_GALLERY, stem + '.webp');
    await sharp(src)
      .resize(600, 800, { fit: 'cover' })
      .webp({ quality: TEASER_QUALITY })
      .toFile(out);
    const bytes = fs.statSync(out).size;
    console.log(`OK  ${path.relative(ROOT, out)}  (${fmtKb(bytes)})`);
  }
}

async function main() {
  if (!fs.existsSync(SRC)) {
    console.error(`ERROR: ${SRC} does not exist.`);
    console.error('Create it and drop sources in:');
    console.error('  _image-sources/profile.{jpg,png}');
    console.error('  _image-sources/gallery/teaser-01.{jpg,png}  (and 02, 03, 04)');
    process.exit(1);
  }
  if (!fs.existsSync(OUT_GALLERY)) fs.mkdirSync(OUT_GALLERY, { recursive: true });
  await processProfile();
  await processTeasers();
  console.log('Done.');
}

main().catch(err => { console.error(err); process.exit(1); });
```

- [ ] **Step 3: Update `.gitignore` to exclude `_image-sources/`**

Append to `C:\Users\keyst\Personal-Landing-Page\.gitignore`:

```
# Local-only image sources (do not publish originals)
_image-sources/
```

- [ ] **Step 4: Install sharp**

```powershell
cd C:\Users\keyst\Personal-Landing-Page\tools
npm install
cd C:\Users\keyst\Personal-Landing-Page
```

Expected: `tools/node_modules/sharp/` exists; no errors. (`tools/node_modules/` is gitignored.)

- [ ] **Step 5: Smoke-test the script (no sources yet)**

```powershell
node C:\Users\keyst\Personal-Landing-Page\tools\optimize-images.js
```

Expected: errors out with `_image-sources` missing message, OR (if you preemptively created the dir) prints `SKIP` lines for every source. Either is fine — confirms the script runs.

- [ ] **Step 6: Commit**

```powershell
git add tools/package.json tools/package-lock.json tools/optimize-images.js .gitignore
git -c commit.gpgsign=false commit -m "Add sharp-based image optimization pipeline (dev-only)"
```

---

## Task 3: Compress `profile.png` → WebP + update `<head>` preload

**Files:**
- Create: `_image-sources/profile.png` (local-only, not committed)
- Create: `images/profile.webp`, `images/profile@2x.webp`
- Delete: `images/profile.png`
- Modify: `index.html` (preload + hero `<img>`)

- [ ] **Step 1: Stage the source for the pipeline**

```powershell
New-Item -ItemType Directory -Force -Path C:\Users\keyst\Personal-Landing-Page\_image-sources | Out-Null
Copy-Item C:\Users\keyst\Personal-Landing-Page\images\profile.png C:\Users\keyst\Personal-Landing-Page\_image-sources\profile.png
```

- [ ] **Step 2: Run the optimizer**

```powershell
node C:\Users\keyst\Personal-Landing-Page\tools\optimize-images.js
```

Expected output includes:
```
OK  images\profile.webp  (~70-110 KB)
OK  images\profile@2x.webp  (~180-260 KB)
```

If either profile WebP is >250 KB, lower `PROFILE_QUALITY` in `tools/optimize-images.js` from 82 to 75 and re-run.

- [ ] **Step 3: Delete the old PNG**

```powershell
Remove-Item C:\Users\keyst\Personal-Landing-Page\images\profile.png
```

- [ ] **Step 4: Add preload + update hero `<img>` in `index.html`**

In `C:\Users\keyst\Personal-Landing-Page\index.html`, find the `<head>` block right before the `<link rel="preconnect" href="https://fonts.googleapis.com" />` line and INSERT:

```html
  <!-- LCP image preload -->
  <link rel="preload" as="image" type="image/webp" href="images/profile.webp" fetchpriority="high" />

```

Then find the existing hero avatar `<img>`:

```html
      <img class="hero-avatar" src="images/profile.png" alt="Keith" />
```

Replace with:

```html
      <img class="hero-avatar" src="images/profile.webp" srcset="images/profile.webp 1x, images/profile@2x.webp 2x" width="180" height="180" alt="Keith" />
```

Also update the OG/Twitter image tags (still pointing at the deleted PNG):

```html
  <meta property="og:image" content="https://keith-links-995.netlify.app/images/profile.png" />
  ...
  <meta name="twitter:image" content="https://keith-links-995.netlify.app/images/profile.png" />
```

For now, repoint to the WebP (Task 5 will replace with a purpose-built OG card):

```html
  <meta property="og:image" content="https://keith-links-995.netlify.app/images/profile.webp" />
  ...
  <meta name="twitter:image" content="https://keith-links-995.netlify.app/images/profile.webp" />
```

- [ ] **Step 5: Verify in browser**

```powershell
cd C:\Users\keyst\Personal-Landing-Page
python -m http.server 8000
```

Open http://localhost:8000/. Confirm:
- Avatar still renders correctly (round, 180px, violet border).
- DevTools Network tab shows `profile.webp` loaded (NOT `profile.png`), under ~150 KB.
- No 404s for `profile.png`.

Stop the server with Ctrl+C.

- [ ] **Step 6: Commit**

```powershell
git add index.html images/profile.webp images/profile@2x.webp
git -c commit.gpgsign=false commit -m "Replace 3.2MB profile.png with WebP variants + LCP preload"
git rm images/profile.png 2>$null
```

If `images/profile.png` is still showing as deleted in `git status`, add the deletion:

```powershell
git add -u images/profile.png
git -c commit.gpgsign=false commit -m "Remove obsolete profile.png"
```

---

## Task 4: Real WebP teasers + repoint `gallery.json`

**User-asset gate:** This task requires the user to drop their 4 real teaser sources into `_image-sources/gallery/` before running. If they're not ready, skip this task and revisit later — the rest of the plan works with the existing placeholder JPGs (they'll just look like copies of the avatar until the real teasers land).

**Files:**
- Create: `_image-sources/gallery/teaser-0{1..4}.{jpg|png}` (local-only)
- Create: `images/gallery/teaser-0{1..4}.webp`
- Delete: `images/gallery/teaser-0{1..4}.jpg`
- Modify: `gallery.json`

- [ ] **Step 1: User drops 4 source teasers**

User places sources at:
```
_image-sources/gallery/teaser-01.jpg  (or .png/.webp)
_image-sources/gallery/teaser-02.jpg
_image-sources/gallery/teaser-03.jpg
_image-sources/gallery/teaser-04.jpg
```

Any source size works; the script outputs 600×800 WebP regardless.

- [ ] **Step 2: Run the optimizer**

```powershell
node C:\Users\keyst\Personal-Landing-Page\tools\optimize-images.js
```

Expected output:
```
OK  images\profile.webp  (...)             <-- re-emitted, no harm
OK  images\profile@2x.webp  (...)
OK  images\gallery\teaser-01.webp  (~40-100 KB)
OK  images\gallery\teaser-02.webp
OK  images\gallery\teaser-03.webp
OK  images\gallery\teaser-04.webp
```

If any teaser is >150 KB, lower `TEASER_QUALITY` in the script from 75 to 65 and re-run.

- [ ] **Step 3: Delete the old JPG placeholders**

```powershell
Remove-Item C:\Users\keyst\Personal-Landing-Page\images\gallery\teaser-01.jpg
Remove-Item C:\Users\keyst\Personal-Landing-Page\images\gallery\teaser-02.jpg
Remove-Item C:\Users\keyst\Personal-Landing-Page\images\gallery\teaser-03.jpg
Remove-Item C:\Users\keyst\Personal-Landing-Page\images\gallery\teaser-04.jpg
```

- [ ] **Step 4: Repoint `gallery.json` to `.webp`**

Replace contents of `C:\Users\keyst\Personal-Landing-Page\gallery.json` with:

```json
{
  "items": [
    { "media": "/images/gallery/teaser-01.webp", "caption": "20 photos",   "price": 10 },
    { "media": "/images/gallery/teaser-02.webp", "caption": "Video · 4 min", "price": 15 },
    { "media": "/images/gallery/teaser-03.webp", "caption": "12 photos",   "price": 8  },
    { "media": "/images/gallery/teaser-04.webp", "caption": "Video · 6 min", "price": 20 }
  ]
}
```

- [ ] **Step 4b: Add `loading="lazy"` to gallery media in the render IIFE** (independent of the user-asset gate — safe to run even if Steps 1–3 are skipped)

In `C:\Users\keyst\Personal-Landing-Page\index.html`, inside the existing gallery render IIFE, find the block that creates the media element:

```javascript
          let media;
          if (isVideo) {
            media = document.createElement('video');
            media.preload = 'metadata';
            media.muted = true;
            media.playsInline = true;
            const source = document.createElement('source');
            source.src = validateUrl(mediaPath);
            media.appendChild(source);
          } else {
            media = document.createElement('img');
            media.src = validateUrl(mediaPath);
            media.alt = '';
          }
          media.className = 'content-preview';
          media.setAttribute('aria-hidden', 'true');
          tile.appendChild(media);
```

Insert `media.loading = 'lazy';` between the `media.className` line and `media.setAttribute('aria-hidden', 'true');`:

```javascript
          media.className = 'content-preview';
          media.loading = 'lazy';
          media.setAttribute('aria-hidden', 'true');
          tile.appendChild(media);
```

(`loading="lazy"` is honored on both `<img>` and `<video>` in evergreen browsers; unsupported attributes are simply ignored.)

- [ ] **Step 5: Verify in browser**

Start `python -m http.server 8000`, open `/`. Confirm gallery tiles render the new images (blurred preview style is unchanged; only the source asset is new). Check DevTools Network: all 4 gallery loads are `.webp` and under ~150 KB each.

- [ ] **Step 6: Commit**

```powershell
git add gallery.json images/gallery/*.webp
git rm images/gallery/teaser-01.jpg images/gallery/teaser-02.jpg images/gallery/teaser-03.jpg images/gallery/teaser-04.jpg
git -c commit.gpgsign=false commit -m "Replace placeholder gallery teasers with real WebPs"
```

---

## Task 5: Generate + wire OG share card

**Files:**
- Create: `scripts/make-og.ps1`, `images/og.png`
- Modify: `index.html` (`<meta og:image>`, `<meta twitter:image>`)

- [ ] **Step 1: Create `scripts/make-og.ps1`**

```powershell
New-Item -ItemType Directory -Force -Path C:\Users\keyst\Personal-Landing-Page\scripts | Out-Null
```

Write `C:\Users\keyst\Personal-Landing-Page\scripts\make-og.ps1`:

```powershell
# Generates a 1200x630 branded OG share card.
# Output: images/og.png

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$outPath = Join-Path $root 'images\og.png'

$width = 1200
$height = 630
$bmp = New-Object System.Drawing.Bitmap $width, $height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# Background: dark base
$g.Clear([System.Drawing.Color]::FromArgb(255, 6, 6, 8))

# Violet glow orb (top-right)
$orbBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush (
  [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(900, 0),
    [System.Drawing.PointF]::new(1200, 0),
    [System.Drawing.PointF]::new(1200, 400),
    [System.Drawing.PointF]::new(900, 400)
  )
)
$orbBrush.CenterColor = [System.Drawing.Color]::FromArgb(180, 122, 77, 255)
$orbBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 122, 77, 255))
$g.FillEllipse($orbBrush, 700, -200, 700, 700)

# Secondary glow (bottom-left)
$orbBrush2 = New-Object System.Drawing.Drawing2D.PathGradientBrush (
  [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(0, 400),
    [System.Drawing.PointF]::new(400, 400),
    [System.Drawing.PointF]::new(400, 700),
    [System.Drawing.PointF]::new(0, 700)
  )
)
$orbBrush2.CenterColor = [System.Drawing.Color]::FromArgb(120, 160, 107, 255)
$orbBrush2.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 160, 107, 255))
$g.FillEllipse($orbBrush2, -150, 350, 500, 500)

# KEITH wordmark
$wordmarkFont = New-Object System.Drawing.Font 'Arial Black', 140, ([System.Drawing.FontStyle]::Bold)
$wordmarkBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 244, 241, 255))
$g.DrawString('KEITH', $wordmarkFont, $wordmarkBrush, 80, 200)

# Tagline
$taglineFont = New-Object System.Drawing.Font 'Segoe UI', 26, ([System.Drawing.FontStyle]::Regular)
$taglineBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 155, 150, 180))
$g.DrawString('Watch live * Unlock the library * Real moments', $taglineFont, $taglineBrush, 92, 380)

# Domain footer
$domainFont = New-Object System.Drawing.Font 'Segoe UI', 22, ([System.Drawing.FontStyle]::Bold)
$domainBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 160, 107, 255))
$g.DrawString('keith-links-995.netlify.app', $domainFont, $domainBrush, 92, 520)

# Save
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
Write-Host "Wrote $outPath"
```

- [ ] **Step 2: Run it**

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\keyst\Personal-Landing-Page\scripts\make-og.ps1
```

Expected: `Wrote C:\Users\keyst\Personal-Landing-Page\images\og.png`. Open the file — should be a 1200×630 dark card with violet orb glows, "KEITH" wordmark, tagline, and domain.

- [ ] **Step 3: Update OG/Twitter meta tags in `index.html`**

In `C:\Users\keyst\Personal-Landing-Page\index.html`, find:

```html
  <meta property="og:image" content="https://keith-links-995.netlify.app/images/profile.webp" />
```

Replace with:

```html
  <meta property="og:image" content="https://keith-links-995.netlify.app/images/og.png" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="630" />
```

Then find:

```html
  <meta name="twitter:image" content="https://keith-links-995.netlify.app/images/profile.webp" />
```

Replace with:

```html
  <meta name="twitter:image" content="https://keith-links-995.netlify.app/images/og.png" />
```

- [ ] **Step 4: Verify**

Open `images/og.png` directly to confirm it looks branded. The actual share-card preview test happens post-deploy (Twitter/LinkedIn share preview tools).

- [ ] **Step 5: Commit**

```powershell
git add scripts/make-og.ps1 images/og.png index.html
git -c commit.gpgsign=false commit -m "Add branded 1200x630 OG share card + wire meta tags"
```

---

## Task 6: Hero rebuild — lane cards, social row, neutralized nav

**Files:**
- Modify: `index.html` (CSS + nav + hero markup)

- [ ] **Step 1: Replace nav CTA + hero HTML**

In `C:\Users\keyst\Personal-Landing-Page\index.html`, find the nav block:

```html
  <nav class="topbar">
    <a href="#" class="brand"><span class="brand-dot"></span>KEITH</a>
    <a href="https://chaturbate.com/brad_larck199" class="cta-btn" target="_blank" rel="noopener">Watch live →</a>
  </nav>
```

Replace with:

```html
  <nav class="topbar">
    <a href="#" class="brand"><span class="brand-dot"></span>KEITH</a>
    <a href="#follow" class="cta-btn cta-ghost">Follow ↓</a>
  </nav>
```

Then find the entire `<section class="hero">...</section>` block and replace it with:

```html
  <!-- HERO -->
  <section class="hero">
    <div class="hero-avatar-wrap">
      <img class="hero-avatar" src="images/profile.webp" srcset="images/profile.webp 1x, images/profile@2x.webp 2x" width="180" height="180" alt="Keith" />
      <span class="live-badge" id="hero-live-badge" hidden aria-label="Currently live"><span class="live-dot" aria-hidden="true"></span>LIVE</span>
    </div>
    <p class="hero-subtitle" id="hero-subtitle">Welcome to my world</p>
    <h1 class="hero-title">Keith</h1>
    <p class="hero-bio" id="hero-tagline">Live on cam most nights · Full library on OnlyFans · Real moments, daddy energy</p>

    <div class="lane-cards" role="navigation" aria-label="Primary actions">
      <a href="https://chaturbate.com/brad_larck199" class="lane-card lane-live" target="_blank" rel="noopener" id="lane-chaturbate">
        <span class="lane-eyebrow" id="lane-live-eyebrow"><span class="lane-pulse" aria-hidden="true"></span>NEXT STREAM</span>
        <span class="lane-title">Watch on Chaturbate</span>
        <span class="lane-sub" id="lane-live-sub">Loading schedule…</span>
        <span class="lane-arrow" aria-hidden="true">→</span>
      </a>
      <a href="https://onlyfans.com/keithbarron199" class="lane-card lane-library" target="_blank" rel="noopener">
        <span class="lane-eyebrow"><svg class="lane-lock" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>FULL LIBRARY</span>
        <span class="lane-title">Unlock on OnlyFans</span>
        <span class="lane-sub">New drops weekly · Exclusive sets</span>
        <span class="lane-arrow" aria-hidden="true">→</span>
      </a>
    </div>

    <nav class="social-row" id="follow" aria-label="Social channels">
      <a href="https://x.com/Keithbarron3333" class="social-btn" target="_blank" rel="noopener" aria-label="Keith on X">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>
      </a>
      <a href="https://instagram.com/keithmarc295" class="social-btn" target="_blank" rel="noopener" aria-label="Keith on Instagram">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.16c3.2 0 3.58 0 4.85.07 1.17.05 1.8.25 2.22.41.56.22.96.48 1.38.9.42.42.68.82.9 1.38.16.42.36 1.05.41 2.22.06 1.27.07 1.65.07 4.85s0 3.58-.07 4.85c-.05 1.17-.25 1.8-.41 2.22-.22.56-.48.96-.9 1.38-.42.42-.82.68-1.38.9-.42.16-1.05.36-2.22.41-1.27.06-1.65.07-4.85.07s-3.58 0-4.85-.07c-1.17-.05-1.8-.25-2.22-.41a3.7 3.7 0 0 1-1.38-.9 3.7 3.7 0 0 1-.9-1.38c-.16-.42-.36-1.05-.41-2.22C2.16 15.58 2.16 15.2 2.16 12s0-3.58.07-4.85c.05-1.17.25-1.8.41-2.22.22-.56.48-.96.9-1.38.42-.42.82-.68 1.38-.9.42-.16 1.05-.36 2.22-.41C8.42 2.16 8.8 2.16 12 2.16zM12 0C8.74 0 8.33 0 7.05.07 5.78.13 4.9.33 4.14.63a5.9 5.9 0 0 0-2.13 1.38A5.9 5.9 0 0 0 .63 4.14C.33 4.9.13 5.78.07 7.05.01 8.33 0 8.74 0 12s0 3.67.07 4.95c.06 1.27.26 2.15.56 2.91.31.8.73 1.48 1.38 2.13.65.65 1.33 1.07 2.13 1.38.76.3 1.64.5 2.91.56 1.28.06 1.69.07 4.95.07s3.67 0 4.95-.07c1.27-.06 2.15-.26 2.91-.56.8-.31 1.48-.73 2.13-1.38.65-.65 1.07-1.33 1.38-2.13.3-.76.5-1.64.56-2.91.06-1.28.07-1.69.07-4.95s0-3.67-.07-4.95c-.06-1.27-.26-2.15-.56-2.91a5.9 5.9 0 0 0-1.38-2.13A5.9 5.9 0 0 0 19.86.63c-.76-.3-1.64-.5-2.91-.56C15.67.01 15.26 0 12 0zm0 5.84a6.16 6.16 0 1 0 0 12.32 6.16 6.16 0 0 0 0-12.32zm0 10.16a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm6.4-11.85a1.44 1.44 0 1 0 0 2.88 1.44 1.44 0 0 0 0-2.88z"/></svg>
      </a>
      <a href="mailto:keith@keith-links.example?subject=DM%20via%20site" class="social-btn" aria-label="Send Keith a DM">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
      </a>
    </nav>
  </section>
```

**Note:** the mailto address `keith@keith-links.example` is a placeholder. User should replace with a real address (or swap for a direct X DM link `https://x.com/messages/compose?recipient_id=...`) before production deploy.

- [ ] **Step 2: Add lane card + social row CSS**

In `C:\Users\keyst\Personal-Landing-Page\index.html`, find the existing `.cta-btn` rule inside `<style>` and IMMEDIATELY AFTER it (still inside `<style>`), insert:

```css
    .cta-btn.cta-ghost {
      background: transparent;
      border: 1px solid var(--border);
      color: var(--text);
    }
    .cta-btn.cta-ghost:hover {
      background: rgba(122, 77, 255, 0.12);
      border-color: var(--violet);
    }
```

Then find the existing `.links-grid` ruleset (and its `@media` variants) and REPLACE all of them — including `.link-tile`, `.link-tile.primary`, `.link-icon`, `.link-label`, etc. through the end of the LINKS GRID section — with the new lane-card + social-row styles:

```css
    /* LANE CARDS — two equal-weight CTAs (Chaturbate / OnlyFans) */
    .lane-cards {
      display: grid;
      grid-template-columns: 1fr;
      gap: 14px;
      max-width: 420px;
      width: 100%;
      margin: 0 auto;
    }
    @media (min-width: 720px) {
      .lane-cards {
        grid-template-columns: 1fr 1fr;
        max-width: 760px;
        gap: 18px;
      }
    }
    .lane-card {
      position: relative;
      display: flex;
      flex-direction: column;
      gap: 6px;
      padding: 22px 24px;
      border-radius: 18px;
      background: var(--card);
      border: 1px solid var(--border);
      text-decoration: none;
      color: var(--text);
      min-height: 130px;
      transition: background 0.2s ease, border-color 0.2s ease, transform 0.2s ease;
    }
    .lane-card:hover {
      background: rgba(122, 77, 255, 0.08);
      border-color: var(--violet);
      transform: translateY(-2px);
    }
    .lane-card:focus-visible {
      outline: 2px solid var(--violet-bright);
      outline-offset: 3px;
    }
    .lane-card.lane-library {
      background: linear-gradient(135deg, var(--violet), var(--violet-bright));
      border-color: rgba(255, 255, 255, 0.2);
    }
    .lane-card.lane-library:hover { opacity: 0.94; }
    .lane-eyebrow {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      font-size: 11.5px;
      font-weight: 700;
      letter-spacing: 0.14em;
      text-transform: uppercase;
      color: var(--muted);
    }
    .lane-card.lane-library .lane-eyebrow { color: rgba(255, 255, 255, 0.88); }
    .lane-card.lane-live.is-live .lane-eyebrow { color: #ff2c5a; }
    .lane-pulse {
      display: inline-block;
      width: 8px; height: 8px;
      border-radius: 50%;
      background: var(--muted);
      flex-shrink: 0;
    }
    .lane-card.lane-live.is-live .lane-pulse {
      background: #ff2c5a;
      animation: pulse-dot 1.4s ease-in-out infinite;
    }
    .lane-lock { width: 14px; height: 14px; flex-shrink: 0; }
    .lane-title {
      font-family: 'Archivo Black', sans-serif;
      font-size: 22px;
      line-height: 1.1;
    }
    .lane-sub {
      font-size: 13.5px;
      color: var(--muted);
    }
    .lane-card.lane-library .lane-sub { color: rgba(255, 255, 255, 0.85); }
    .lane-arrow {
      position: absolute;
      bottom: 18px;
      right: 22px;
      font-size: 20px;
      transition: transform 0.2s ease;
    }
    .lane-card:hover .lane-arrow { transform: translateX(4px); }

    /* SOCIAL ROW — slim secondary follow targets */
    .social-row {
      display: flex;
      justify-content: center;
      gap: 14px;
      margin-top: 28px;
    }
    .social-btn {
      width: 44px; height: 44px;
      border-radius: 50%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      background: var(--card);
      border: 1px solid var(--border);
      color: var(--text);
      text-decoration: none;
      transition: background 0.2s ease, border-color 0.2s ease;
    }
    .social-btn:hover {
      background: rgba(122, 77, 255, 0.12);
      border-color: var(--violet);
    }
    .social-btn:focus-visible {
      outline: 2px solid var(--violet-bright);
      outline-offset: 3px;
    }
    .social-btn svg { width: 18px; height: 18px; fill: currentColor; }
```

The existing `.live-badge` rule continues to work; the `hidden` HTML attribute handles its default off state.

- [ ] **Step 3: Verify in browser**

```powershell
cd C:\Users\keyst\Personal-Landing-Page
python -m http.server 8000
```

Open `/`. Confirm:
- Nav shows "Follow ↓" (ghost outlined) instead of "Watch live".
- Hero shows avatar (LIVE badge hidden — will toggle on in Task 9), wordmark, tagline.
- Two lane cards visible: left (Chaturbate, dark with "NEXT STREAM" eyebrow), right (OnlyFans, violet gradient with lock + "FULL LIBRARY").
- On desktop ≥720px: side-by-side. On mobile <720px: stacked.
- Hover: both cards lift + violet border / opacity dip. Arrow nudges right.
- Three social buttons below.
- Tab order: Follow → Chaturbate → OnlyFans → X → Instagram → DM.
- Click "Follow ↓" in nav scrolls down to the social row.

Stop the server.

- [ ] **Step 4: Commit**

```powershell
git add index.html
git -c commit.gpgsign=false commit -m "Rebuild hero with equal lane cards (Chaturbate/OnlyFans) + social row"
```

---

## Task 7: Bio IIFE — load `bio.json` into hero copy

**Files:**
- Modify: `index.html` (`<script>` block, append new IIFE)

- [ ] **Step 1: Add the Bio IIFE**

In `C:\Users\keyst\Personal-Landing-Page\index.html`, find the closing `</script>` tag. Immediately BEFORE that `</script>`, append:

```javascript
    // Bio IIFE — load subtitle + tagline from bio.json, fall back to hardcoded copy on failure.
    (async function loadBio() {
      const subtitleEl = document.getElementById('hero-subtitle');
      const taglineEl = document.getElementById('hero-tagline');
      if (!subtitleEl || !taglineEl) return;
      try {
        const res = await fetch('/bio.json', { cache: 'no-cache' });
        if (!res.ok) return;
        const data = await res.json();
        if (data && typeof data.subtitle === 'string' && data.subtitle.trim()) {
          subtitleEl.textContent = data.subtitle;
        }
        if (data && typeof data.tagline === 'string' && data.tagline.trim()) {
          taglineEl.textContent = data.tagline;
        }
      } catch (err) {
        console.warn('Bio load failed:', err);
      }
    })();
```

- [ ] **Step 2: Verify**

Start `python -m http.server 8000`, open `/`. Confirm:
- Subtitle reads "Welcome to my world" (matches `bio.json`).
- Tagline reads "Live on cam most nights · Full library on OnlyFans · Real moments, daddy energy".
- Edit `bio.json`, refresh page → copy updates.
- Rename `bio.json` to `bio.bak.json` temporarily, refresh → hardcoded fallbacks still display (no broken hero). Rename back.

- [ ] **Step 3: Commit**

```powershell
git add index.html
git -c commit.gpgsign=false commit -m "Add Bio IIFE: load hero subtitle/tagline from bio.json"
```

---

## Task 8: Schedule section — markup, CSS, IIFE

**Files:**
- Modify: `index.html` (new section, CSS, IIFE)

- [ ] **Step 1: Insert schedule section markup**

In `C:\Users\keyst\Personal-Landing-Page\index.html`, find the EXCLUSIVE CONTENT section start (`<!-- EXCLUSIVE CONTENT -->`). Immediately BEFORE that comment, insert:

```html
  <!-- SCHEDULE -->
  <section class="section section-schedule" id="schedule" aria-labelledby="schedule-heading" hidden>
    <div class="section-eyebrow reveal">Stream Schedule</div>
    <h2 class="section-title reveal" id="schedule-heading">When I'm Live</h2>
    <div class="schedule-wrap reveal">
      <div class="schedule-next" id="schedule-next">
        <span class="schedule-next-eyebrow" id="schedule-next-eyebrow">NEXT STREAM</span>
        <span class="schedule-next-when" id="schedule-next-when">—</span>
        <span class="schedule-next-local" id="schedule-next-local"></span>
      </div>
      <div class="schedule-week" id="schedule-week" aria-label="Weekly schedule"></div>
    </div>
  </section>
```

(The section starts `hidden`. The IIFE removes the `hidden` attr only when there's data to show — same graceful-degradation pattern used for testimonials.)

- [ ] **Step 2: Add schedule CSS**

In the `<style>` block, find the `/* CONTENT GRID */` comment and IMMEDIATELY BEFORE it, insert:

```css
    /* SCHEDULE */
    .schedule-wrap {
      display: grid;
      grid-template-columns: 1fr;
      gap: 22px;
      max-width: 880px;
      margin: 0 auto;
    }
    @media (min-width: 720px) {
      .schedule-wrap {
        grid-template-columns: minmax(0, 360px) 1fr;
        align-items: stretch;
      }
    }
    .schedule-next {
      display: flex;
      flex-direction: column;
      gap: 10px;
      padding: 24px 26px;
      border-radius: 18px;
      background: var(--card);
      border: 1px solid var(--border);
    }
    .schedule-next-eyebrow {
      font-size: 11.5px;
      font-weight: 700;
      letter-spacing: 0.14em;
      text-transform: uppercase;
      color: var(--muted);
    }
    .schedule-next.is-live .schedule-next-eyebrow,
    .schedule-next.is-live .schedule-next-eyebrow a {
      color: #ff2c5a;
    }
    .schedule-next-eyebrow a {
      color: inherit;
      text-decoration: none;
    }
    .schedule-next-when {
      font-family: 'Archivo Black', sans-serif;
      font-size: 26px;
      line-height: 1.1;
    }
    .schedule-next-local {
      font-size: 13.5px;
      color: var(--muted);
    }
    .schedule-week {
      display: grid;
      grid-template-columns: repeat(7, minmax(0, 1fr));
      gap: 8px;
    }
    .schedule-day {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 6px;
      padding: 14px 4px;
      border-radius: 12px;
      background: var(--card);
      border: 1px solid var(--border);
      text-align: center;
    }
    .schedule-day.is-today {
      border-color: var(--violet);
      background: rgba(122, 77, 255, 0.08);
    }
    .schedule-day-name {
      font-size: 11.5px;
      font-weight: 700;
      letter-spacing: 0.1em;
      text-transform: uppercase;
      color: var(--text);
    }
    .schedule-day-time {
      font-size: 12.5px;
      color: var(--violet-bright);
      font-weight: 600;
    }
    .schedule-day.is-off .schedule-day-time {
      color: var(--muted);
      font-weight: 400;
    }
```

- [ ] **Step 3: Add the Schedule IIFE**

In the `<script>` block, find the Bio IIFE you added in Task 7. IMMEDIATELY AFTER it (still before the closing `</script>`), append:

```javascript
    // Schedule IIFE — fetch schedule.json, compute live state + next slot, render, emit schedule:state event.
    (async function loadSchedule() {
      const section = document.getElementById('schedule');
      const nextEl = document.getElementById('schedule-next');
      const nextEyebrow = document.getElementById('schedule-next-eyebrow');
      const nextWhen = document.getElementById('schedule-next-when');
      const nextLocal = document.getElementById('schedule-next-local');
      const weekEl = document.getElementById('schedule-week');
      if (!section || !nextEl || !nextEyebrow || !nextWhen || !nextLocal || !weekEl) return;

      const DAYS_ORDER = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      const DAY_TO_INDEX = { Mon:1, Tue:2, Wed:3, Thu:4, Fri:5, Sat:6, Sun:0 };

      function parseHM(s) {
        const m = String(s || '').match(/^(\d{1,2}):(\d{2})$/);
        if (!m) return null;
        const h = parseInt(m[1], 10), min = parseInt(m[2], 10);
        if (h < 0 || h > 23 || min < 0 || min > 59) return null;
        return { h, m: min };
      }

      // Convert a slot (day + start + end in schedule tz) into UTC ms ranges anchored to a specific "today" in the schedule tz.
      // Returns { startUtc, endUtc } pairs. Handles slots that wrap past midnight (end < start).
      function slotToUtcRange(slot, tz, anchorDate) {
        const start = parseHM(slot.start);
        const end = parseHM(slot.end);
        if (!start || !end) return null;
        const wraps = (end.h < start.h) || (end.h === start.h && end.m <= start.m);
        const startUtc = tzWallTimeToUtcMs(anchorDate, start.h, start.m, tz);
        const endAnchor = wraps ? addDays(anchorDate, 1) : anchorDate;
        const endUtc = tzWallTimeToUtcMs(endAnchor, end.h, end.m, tz);
        return { startUtc, endUtc };
      }

      // Approximate the UTC ms for a wall-clock time in the given IANA tz.
      // Uses Intl to find the tz offset; accurate enough for schedule windows.
      function tzWallTimeToUtcMs(dateInTz, hour, minute, tz) {
        const y = dateInTz.year, mo = dateInTz.month, d = dateInTz.day;
        const utcGuess = Date.UTC(y, mo - 1, d, hour, minute, 0);
        const offsetMs = tzOffsetMs(utcGuess, tz);
        return utcGuess - offsetMs;
      }

      function tzOffsetMs(utcMs, tz) {
        const dtf = new Intl.DateTimeFormat('en-US', {
          timeZone: tz, hour12: false,
          year: 'numeric', month: '2-digit', day: '2-digit',
          hour: '2-digit', minute: '2-digit', second: '2-digit'
        });
        const parts = dtf.formatToParts(new Date(utcMs));
        const get = (t) => parseInt(parts.find(p => p.type === t).value, 10);
        const localAsUtc = Date.UTC(get('year'), get('month') - 1, get('day'), get('hour') === 24 ? 0 : get('hour'), get('minute'), get('second'));
        return localAsUtc - utcMs;
      }

      function dateInTz(utcMs, tz) {
        const dtf = new Intl.DateTimeFormat('en-CA', { timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit' });
        const parts = dtf.formatToParts(new Date(utcMs));
        return {
          year: parseInt(parts.find(p => p.type === 'year').value, 10),
          month: parseInt(parts.find(p => p.type === 'month').value, 10),
          day: parseInt(parts.find(p => p.type === 'day').value, 10),
        };
      }

      function addDays(d, n) {
        const js = new Date(Date.UTC(d.year, d.month - 1, d.day));
        js.setUTCDate(js.getUTCDate() + n);
        return { year: js.getUTCFullYear(), month: js.getUTCMonth() + 1, day: js.getUTCDate() };
      }

      function isoDate(d) {
        return d.year + '-' + String(d.month).padStart(2, '0') + '-' + String(d.day).padStart(2, '0');
      }

      function findCurrentAndNext(schedule, nowMs) {
        const tz = schedule.tz || 'America/Chicago';
        const slots = Array.isArray(schedule.slots) ? schedule.slots : [];
        const overrides = Array.isArray(schedule.overrides) ? schedule.overrides : [];
        const offDates = new Set(overrides.filter(o => o && o.off).map(o => o.date));
        const today = dateInTz(nowMs, tz);

        const instances = [];
        for (let dayOffset = -1; dayOffset <= 8; dayOffset++) {
          const anchor = addDays(today, dayOffset);
          if (offDates.has(isoDate(anchor))) continue;
          const anchorJs = new Date(Date.UTC(anchor.year, anchor.month - 1, anchor.day));
          const dow = anchorJs.getUTCDay();
          for (const slot of slots) {
            const slotDow = DAY_TO_INDEX[slot.day];
            if (slotDow === undefined || slotDow !== dow) continue;
            const range = slotToUtcRange(slot, tz, anchor);
            if (!range) continue;
            instances.push({ slot, anchor, ...range });
          }
        }

        instances.sort((a, b) => a.startUtc - b.startUtc);

        let current = null;
        let next = null;
        for (const inst of instances) {
          if (nowMs >= inst.startUtc && nowMs < inst.endUtc) { current = inst; }
          if (inst.startUtc > nowMs && !next) { next = inst; }
        }
        return { current, next, tz };
      }

      function renderWeek(schedule, todayInTz) {
        const slots = Array.isArray(schedule.slots) ? schedule.slots : [];
        const todayJs = new Date(Date.UTC(todayInTz.year, todayInTz.month - 1, todayInTz.day));
        const todayDow = todayJs.getUTCDay();
        const byDay = {};
        for (const s of slots) {
          if (!s || !s.day) continue;
          if (!byDay[s.day]) byDay[s.day] = [];
          byDay[s.day].push(s);
        }
        while (weekEl.firstChild) weekEl.removeChild(weekEl.firstChild);
        for (const d of DAYS_ORDER) {
          const chip = document.createElement('div');
          chip.className = 'schedule-day';
          if (DAY_TO_INDEX[d] === todayDow) chip.classList.add('is-today');

          const name = document.createElement('span');
          name.className = 'schedule-day-name';
          name.textContent = d;
          chip.appendChild(name);

          const time = document.createElement('span');
          time.className = 'schedule-day-time';
          const list = byDay[d];
          if (list && list.length > 0) {
            const first = list[0];
            const label = first.start + (list.length > 1 ? ' +' + (list.length - 1) : '');
            time.textContent = label;
          } else {
            chip.classList.add('is-off');
            time.textContent = 'Off';
          }
          chip.appendChild(time);
          weekEl.appendChild(chip);
        }
      }

      function formatNextWhen(inst, tz) {
        const dtf = new Intl.DateTimeFormat('en-US', {
          timeZone: tz, weekday: 'long', hour: 'numeric', minute: '2-digit', timeZoneName: 'short'
        });
        return dtf.format(new Date(inst.startUtc));
      }

      function formatLocalDelta(inst) {
        const dtf = new Intl.DateTimeFormat('en-US', {
          weekday: 'long', hour: 'numeric', minute: '2-digit', timeZoneName: 'short'
        });
        const local = dtf.format(new Date(inst.startUtc));
        const days = Math.round((inst.startUtc - Date.now()) / 86400000);
        const rel = days <= 0 ? 'today' : (days === 1 ? 'tomorrow' : 'in ' + days + ' days');
        return 'Your time: ' + local + ' (' + rel + ')';
      }

      function emit(state) {
        window.dispatchEvent(new CustomEvent('schedule:state', { detail: state }));
      }

      try {
        const res = await fetch('/schedule.json', { cache: 'no-cache' });
        if (!res.ok) { emit({ isLive: false, nextSlot: null, chaturbateUrl: null }); return; }
        const schedule = await res.json();
        if (!schedule || !Array.isArray(schedule.slots) || schedule.slots.length === 0) {
          emit({ isLive: false, nextSlot: null, chaturbateUrl: null });
          return;
        }

        const tz = schedule.tz || 'America/Chicago';
        const now = Date.now();
        const todayInTz = dateInTz(now, tz);
        const { current, next } = findCurrentAndNext(schedule, now);

        if (current) {
          nextEl.classList.add('is-live');
          const liveLink = document.createElement('a');
          liveLink.href = 'https://chaturbate.com/brad_larck199';
          liveLink.target = '_blank';
          liveLink.rel = 'noopener';
          liveLink.textContent = 'LIVE NOW → Watch on Chaturbate';
          nextEyebrow.textContent = '';
          nextEyebrow.appendChild(liveLink);
          nextWhen.textContent = 'Streaming right now';
          nextLocal.textContent = '';
        } else if (next) {
          nextEl.classList.remove('is-live');
          nextEyebrow.textContent = 'NEXT STREAM';
          nextWhen.textContent = formatNextWhen(next, tz);
          nextLocal.textContent = formatLocalDelta(next);
        } else {
          nextEl.classList.remove('is-live');
          nextEyebrow.textContent = 'SCHEDULE';
          nextWhen.textContent = 'Check back soon';
          nextLocal.textContent = '';
        }

        renderWeek(schedule, todayInTz);
        section.hidden = false;

        emit({
          isLive: !!current,
          nextSlot: next ? { startUtc: next.startUtc, day: next.slot.day, start: next.slot.start } : null,
          chaturbateUrl: 'https://chaturbate.com/brad_larck199'
        });
      } catch (err) {
        console.warn('Schedule load failed:', err);
        emit({ isLive: false, nextSlot: null, chaturbateUrl: null });
      }
    })();
```

- [ ] **Step 4: Verify**

Start `python -m http.server 8000`, open `/`. Confirm:
- New "When I'm Live" section appears between hero and gallery.
- Next-stream callout shows a day + time matching one of `schedule.json`'s slots.
- "Your time:" line displays in the visitor's local timezone with "in N days" or "tomorrow"/"today".
- Weekly grid shows 7 chips: lit on Mon/Wed/Fri (per default `schedule.json`), "Off" on others. Today's chip has the violet outline.
- LIVE state test: temporarily edit `schedule.json` so today's day-of-week has a slot whose `start` is 5 min ago and `end` is 1 hour from now. Refresh → callout flips to "LIVE NOW → Watch on Chaturbate" with red eyebrow. Revert `schedule.json`.
- Override test: add an override entry for today like `{"date":"YYYY-MM-DD","off":true}` (use today's date). If a slot was scheduled for today, the LIVE/next display should no longer reflect it. Remove the override.
- Empty test: rename `schedule.json` to `schedule.bak.json`. Refresh → schedule section stays hidden, page still works. Revert.

- [ ] **Step 5: Commit**

```powershell
git add index.html
git -c commit.gpgsign=false commit -m "Add Schedule section: next-stream callout + weekly grid (schedule.json)"
```

---

## Task 9: Hero LIVE-state listener IIFE

**Files:**
- Modify: `index.html` (`<script>` block, append new IIFE)

- [ ] **Step 1: Add the listener IIFE**

In the `<script>` block, find the Schedule IIFE you just added. IMMEDIATELY AFTER it, append:

```javascript
    // Hero LIVE-state listener — react to schedule:state events.
    // Toggles the hero's LIVE badge, the left lane card's eyebrow/pulse, and (later) the sticky bar accent.
    (function heroLiveListener() {
      const heroBadge = document.getElementById('hero-live-badge');
      const lane = document.getElementById('lane-chaturbate');
      const eyebrow = document.getElementById('lane-live-eyebrow');
      const sub = document.getElementById('lane-live-sub');
      if (!heroBadge || !lane || !eyebrow || !sub) return;

      function fmtNext(state) {
        if (!state || !state.nextSlot) return 'Schedule coming soon';
        const when = new Date(state.nextSlot.startUtc);
        const dtf = new Intl.DateTimeFormat('en-US', {
          weekday: 'short', hour: 'numeric', minute: '2-digit', timeZoneName: 'short'
        });
        return dtf.format(when);
      }

      window.addEventListener('schedule:state', (e) => {
        const state = e.detail || {};
        if (state.isLive) {
          heroBadge.hidden = false;
          lane.classList.add('is-live');
          while (eyebrow.firstChild) eyebrow.removeChild(eyebrow.firstChild);
          const pulse = document.createElement('span');
          pulse.className = 'lane-pulse';
          pulse.setAttribute('aria-hidden', 'true');
          eyebrow.appendChild(pulse);
          eyebrow.appendChild(document.createTextNode('LIVE NOW'));
          sub.textContent = 'Streaming on Chaturbate right now';
        } else {
          heroBadge.hidden = true;
          lane.classList.remove('is-live');
          while (eyebrow.firstChild) eyebrow.removeChild(eyebrow.firstChild);
          const pulse = document.createElement('span');
          pulse.className = 'lane-pulse';
          pulse.setAttribute('aria-hidden', 'true');
          eyebrow.appendChild(pulse);
          eyebrow.appendChild(document.createTextNode('NEXT STREAM'));
          sub.textContent = fmtNext(state);
        }
      });
    })();
```

- [ ] **Step 2: Verify**

Start `python -m http.server 8000`, open `/`. Confirm:
- Default state (no live slot): hero LIVE badge hidden; left lane card eyebrow reads "NEXT STREAM" with grey pulse, sub shows next day/time abbreviated (e.g. "Wed, 9:00 PM CT").
- Force LIVE via the same `schedule.json` edit as Task 8 step 4. Refresh. Confirm: hero LIVE badge visible (red, pulsing); left lane eyebrow flips to red "LIVE NOW" with pulsing red dot; sub reads "Streaming on Chaturbate right now".
- Revert the schedule edit.

- [ ] **Step 3: Commit**

```powershell
git add index.html
git -c commit.gpgsign=false commit -m "Wire hero LIVE pulse + lane eyebrow to schedule:state events"
```

---

## Task 10: Testimonials section — markup, CSS, IIFE

**Files:**
- Modify: `index.html` (new section, CSS, IIFE)

- [ ] **Step 1: Insert testimonials section markup**

In `C:\Users\keyst\Personal-Landing-Page\index.html`, find the FAQ section (`<!-- FAQ -->`). IMMEDIATELY BEFORE that comment, insert:

```html
  <!-- TESTIMONIALS -->
  <section class="section section-testimonials" id="testimonials" aria-labelledby="testimonials-heading" hidden>
    <div class="section-eyebrow reveal">What Fans Are Saying</div>
    <h2 class="section-title reveal" id="testimonials-heading">From the DMs</h2>
    <div class="testimonials-grid reveal" id="testimonials-grid"></div>
  </section>
```

- [ ] **Step 2: Add testimonials CSS**

In the `<style>` block, find the `/* FAQ */` comment and IMMEDIATELY BEFORE it, insert:

```css
    /* TESTIMONIALS */
    .testimonials-grid {
      display: grid;
      grid-template-columns: 1fr;
      gap: 16px;
      max-width: 1000px;
      margin: 0 auto;
    }
    @media (min-width: 640px) {
      .testimonials-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    }
    @media (min-width: 900px) {
      .testimonials-grid { grid-template-columns: repeat(3, minmax(0, 1fr)); }
    }
    .testimonial {
      position: relative;
      padding: 26px 22px 22px;
      border-radius: 16px;
      background: var(--card);
      border: 1px solid var(--border);
    }
    .testimonial::before {
      content: '\201C';
      position: absolute;
      top: 4px;
      left: 14px;
      font-family: 'Archivo Black', serif;
      font-size: 56px;
      color: var(--violet-bright);
      opacity: 0.45;
      line-height: 1;
      pointer-events: none;
    }
    .testimonial-quote {
      font-size: 15.5px;
      line-height: 1.55;
      color: var(--text);
      margin-top: 16px;
    }
    .testimonial-handle {
      display: block;
      margin-top: 14px;
      font-size: 12.5px;
      color: var(--muted);
    }
```

- [ ] **Step 3: Add the Testimonials IIFE**

In the `<script>` block, find the Hero LIVE-state listener IIFE you added in Task 9. IMMEDIATELY AFTER it, append:

```javascript
    // Testimonials IIFE — fetch testimonials.json, render cards via DOM methods.
    (async function loadTestimonials() {
      const section = document.getElementById('testimonials');
      const grid = document.getElementById('testimonials-grid');
      if (!section || !grid) return;
      try {
        const res = await fetch('/testimonials.json', { cache: 'no-cache' });
        if (!res.ok) return;
        const data = await res.json();
        const items = Array.isArray(data && data.items) ? data.items : [];
        if (items.length === 0) return;

        const frag = document.createDocumentFragment();
        for (const it of items) {
          if (!it || typeof it.quote !== 'string' || !it.quote.trim()) continue;
          const card = document.createElement('article');
          card.className = 'testimonial reveal';

          const q = document.createElement('p');
          q.className = 'testimonial-quote';
          q.textContent = it.quote;
          card.appendChild(q);

          if (typeof it.handle === 'string' && it.handle.trim()) {
            const h = document.createElement('span');
            h.className = 'testimonial-handle';
            h.textContent = it.handle;
            card.appendChild(h);
          }

          frag.appendChild(card);
        }

        if (!frag.childNodes.length) return;
        while (grid.firstChild) grid.removeChild(grid.firstChild);
        grid.appendChild(frag);
        section.hidden = false;

        // The scroll-reveal IIFE runs on initial load; observe the newly-appended cards too.
        const newReveals = section.querySelectorAll('.reveal');
        if (newReveals.length && 'IntersectionObserver' in window) {
          const io = new IntersectionObserver((entries) => {
            for (const entry of entries) {
              if (entry.isIntersecting) {
                entry.target.classList.add('in-view');
                io.unobserve(entry.target);
              }
            }
          }, { threshold: 0.15 });
          newReveals.forEach(el => io.observe(el));
        }
      } catch (err) {
        console.warn('Testimonials load failed:', err);
      }
    })();
```

- [ ] **Step 4: Verify**

Start `python -m http.server 8000`, open `/`. Confirm:
- New "From the DMs" section appears between gallery and FAQ.
- 3 quote cards render (matching the seed `testimonials.json`).
- On <640px: stacked single column. 640-899px: 2 columns. ≥900px: 3 columns.
- Each card has a faint violet quote mark in the top-left, the quote text, and the handle below.
- Cards fade in on scroll (reveal animation works).
- Empty test: edit `testimonials.json` to `{"items":[]}`. Refresh → section disappears entirely (not just blank). Revert.
- Missing-file test: rename `testimonials.json` to `.bak`. Refresh → section stays hidden, no errors. Revert.

- [ ] **Step 5: Commit**

```powershell
git add index.html
git -c commit.gpgsign=false commit -m "Add Testimonials section (testimonials.json)"
```

---

## Task 11: FAQ refresh + Footer DM link

**Files:**
- Modify: `index.html` (FAQ + footer)

- [ ] **Step 1: Update FAQ items**

In `C:\Users\keyst\Personal-Landing-Page\index.html`, find the FAQ `<div class="faq-wrap reveal">` block. Replace its entire contents with:

```html
      <details class="faq-item">
        <summary class="faq-q">How often do you go live? <span class="toggle" aria-hidden="true">+</span></summary>
        <p class="faq-a">I stream regularly on Chaturbate. The <a href="#schedule" style="color:var(--violet-bright);">schedule above</a> shows the current week, and the LIVE banner lights up the moment I'm on cam.</p>
      </details>
      <details class="faq-item">
        <summary class="faq-q">Where can I see your stream schedule? <span class="toggle" aria-hidden="true">+</span></summary>
        <p class="faq-a">Right at the top of this page — the "When I'm Live" section shows the next stream in your local time plus the full week. Follow me on X for live announcements too.</p>
      </details>
      <details class="faq-item">
        <summary class="faq-q">Where can I follow you? <span class="toggle" aria-hidden="true">+</span></summary>
        <p class="faq-a">I'm on X, Instagram, OnlyFans, and Chaturbate. All my links are right at the top of this page.</p>
      </details>
      <details class="faq-item">
        <summary class="faq-q">What do I get on OnlyFans? <span class="toggle" aria-hidden="true">+</span></summary>
        <p class="faq-a">Exclusive content you won't find anywhere else. New uploads regularly — subscribe to see the full library.</p>
      </details>
      <details class="faq-item">
        <summary class="faq-q">Are the testimonials real? <span class="toggle" aria-hidden="true">+</span></summary>
        <p class="faq-a">Yep — they're real fan quotes shared with permission. Some handles are partial or anonymized at the fan's request.</p>
      </details>
      <details class="faq-item">
        <summary class="faq-q">How do I get in touch? <span class="toggle" aria-hidden="true">+</span></summary>
        <p class="faq-a">Slide into my DMs on X or Instagram — I read everything when I can.</p>
      </details>
```

- [ ] **Step 2: Add a footer DM link**

Find the footer-links block:

```html
      <div class="footer-links">
        <a href="https://chaturbate.com/brad_larck199" target="_blank" rel="noopener">Chaturbate</a>
        <a href="https://onlyfans.com/keithbarron199" target="_blank" rel="noopener">OnlyFans</a>
        <a href="https://x.com/Keithbarron3333" target="_blank" rel="noopener">Twitter / X</a>
        <a href="https://instagram.com/keithmarc295" target="_blank" rel="noopener">Instagram</a>
      </div>
```

Replace with:

```html
      <div class="footer-links">
        <a href="https://chaturbate.com/brad_larck199" target="_blank" rel="noopener">Chaturbate</a>
        <a href="https://onlyfans.com/keithbarron199" target="_blank" rel="noopener">OnlyFans</a>
        <a href="https://x.com/Keithbarron3333" target="_blank" rel="noopener">Twitter / X</a>
        <a href="https://instagram.com/keithmarc295" target="_blank" rel="noopener">Instagram</a>
        <a href="https://x.com/messages/compose?recipient_id=Keithbarron3333" target="_blank" rel="noopener">Send a DM</a>
      </div>
```

(Uses an X compose-DM link rather than a `mailto:`, matching the social-row button's intent. If the X recipient ID approach doesn't work for the user, swap to a real `mailto:` address.)

- [ ] **Step 3: Verify**

Start `python -m http.server 8000`, open `/`. Confirm:
- FAQ now has 6 items (the old "When does the on-site paywall go live" is gone; two new items present).
- The "How often do you go live?" answer has an in-page link to `#schedule` that scrolls smoothly.
- Footer shows the 5th "Send a DM" link.

- [ ] **Step 4: Commit**

```powershell
git add index.html
git -c commit.gpgsign=false commit -m "Refresh FAQ items + add Send a DM footer link"
```

---

## Task 12: Sticky mobile CTA — markup, CSS, observer

**Files:**
- Modify: `index.html` (markup at end of body, CSS, observer wiring)

- [ ] **Step 1: Insert sticky bar markup**

In `C:\Users\keyst\Personal-Landing-Page\index.html`, find the `<template id="lock-svg-tpl">` block. IMMEDIATELY BEFORE that `<template>`, insert:

```html
  <!-- STICKY MOBILE CTA (visible after hero scrolls past, mobile only) -->
  <div class="sticky-cta" id="sticky-cta" hidden aria-label="Quick actions">
    <a href="https://chaturbate.com/brad_larck199" class="sticky-btn sticky-live" id="sticky-live" target="_blank" rel="noopener">
      <span class="sticky-pulse" aria-hidden="true"></span>
      <span class="sticky-btn-label">Watch live</span>
    </a>
    <a href="https://onlyfans.com/keithbarron199" class="sticky-btn sticky-library" target="_blank" rel="noopener">
      <svg class="sticky-lock" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
      <span class="sticky-btn-label">Unlock OF</span>
    </a>
  </div>
```

- [ ] **Step 2: Add sticky CTA CSS**

In the `<style>` block, find the `/* scroll-triggered reveals */` comment and IMMEDIATELY BEFORE it, insert:

```css
    /* STICKY MOBILE CTA */
    .sticky-cta {
      position: fixed;
      left: 0; right: 0; bottom: 0;
      z-index: 90;
      display: none;
      grid-template-columns: 1fr 1fr;
      gap: 1px;
      background: rgba(6, 6, 8, 0.92);
      backdrop-filter: blur(10px);
      -webkit-backdrop-filter: blur(10px);
      border-top: 1px solid var(--border);
    }
    @media (max-width: 640px) {
      .sticky-cta:not([hidden]) { display: grid; }
      body.has-sticky-cta { padding-bottom: 64px; }
    }
    .sticky-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      height: 56px;
      text-decoration: none;
      color: var(--text);
      font-weight: 600;
      font-size: 14px;
      background: transparent;
    }
    .sticky-btn:focus-visible {
      outline: 2px solid var(--violet-bright);
      outline-offset: -2px;
    }
    .sticky-btn.sticky-library {
      background: linear-gradient(135deg, var(--violet), var(--violet-bright));
      color: #fff;
    }
    .sticky-pulse {
      display: inline-block;
      width: 8px; height: 8px;
      border-radius: 50%;
      background: var(--muted);
      flex-shrink: 0;
    }
    .sticky-btn.is-live .sticky-pulse {
      background: #ff2c5a;
      animation: pulse-dot 1.4s ease-in-out infinite;
    }
    .sticky-btn.is-live { color: #ff2c5a; }
    .sticky-lock { width: 16px; height: 16px; flex-shrink: 0; }
```

- [ ] **Step 3: Add the sticky-bar observer + listener IIFE**

In the `<script>` block, find the Testimonials IIFE you added in Task 10. IMMEDIATELY AFTER it, append:

```javascript
    // Sticky mobile CTA — reveal after the hero scrolls out of view (mobile only),
    // and reflect schedule:state on the live button accent.
    (function stickyCta() {
      const bar = document.getElementById('sticky-cta');
      const liveBtn = document.getElementById('sticky-live');
      const hero = document.querySelector('section.hero');
      if (!bar || !liveBtn || !hero) return;

      function show() {
        if (bar.hidden) {
          bar.hidden = false;
          document.body.classList.add('has-sticky-cta');
        }
      }
      function hide() {
        if (!bar.hidden) {
          bar.hidden = true;
          document.body.classList.remove('has-sticky-cta');
        }
      }

      if ('IntersectionObserver' in window) {
        const io = new IntersectionObserver((entries) => {
          for (const entry of entries) {
            if (entry.isIntersecting) hide();
            else show();
          }
        }, { threshold: 0 });
        io.observe(hero);
      } else {
        show();
      }

      window.addEventListener('schedule:state', (e) => {
        const state = e.detail || {};
        if (state.isLive) liveBtn.classList.add('is-live');
        else liveBtn.classList.remove('is-live');
      });
    })();
```

- [ ] **Step 4: Verify**

Start `python -m http.server 8000`, open `/`. Confirm on desktop:
- No sticky bar visible at any scroll position (CSS hides it on >640px).

Resize the browser to <640px width (or use DevTools mobile emulation). Confirm:
- At top of page (hero in view): no sticky bar.
- Scroll past the hero: sticky bar slides into view at bottom with two equal buttons.
- Left button: "Watch live" with grey dot (not live).
- Right button: violet "Unlock OF" with lock icon.
- Scroll back up to hero: sticky bar disappears.
- Body padding adjusts so footer copyright isn't covered when bar is visible.
- LIVE state test (re-use the Task 8 trick): set a live slot in `schedule.json`. Refresh. Left sticky button should turn red with pulsing dot. Revert schedule.

- [ ] **Step 5: Commit**

```powershell
git add index.html
git -c commit.gpgsign=false commit -m "Add sticky mobile CTA bar (split: Watch live / Unlock OF)"
```

---

## Task 13: SEO additions — canonical, JSON-LD, sitemap.xml, robots.txt

**Files:**
- Create: `sitemap.xml`, `robots.txt`
- Modify: `index.html` (`<head>`)

- [ ] **Step 1: Add canonical + JSON-LD to `<head>`**

In `C:\Users\keyst\Personal-Landing-Page\index.html`, find the line with `<title>Keith — Links</title>`. IMMEDIATELY AFTER it, insert:

```html
  <link rel="canonical" href="https://keith-links-995.netlify.app/" />
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Person",
    "name": "Keith",
    "url": "https://keith-links-995.netlify.app/",
    "image": "https://keith-links-995.netlify.app/images/profile.webp",
    "sameAs": [
      "https://chaturbate.com/brad_larck199",
      "https://onlyfans.com/keithbarron199",
      "https://x.com/Keithbarron3333",
      "https://instagram.com/keithmarc295"
    ]
  }
  </script>
```

(The JSON-LD `<script>` is static markup — no dynamic data flows in — so it's safe to write inline as a single block.)

- [ ] **Step 2: Create `sitemap.xml`**

Write `C:\Users\keyst\Personal-Landing-Page\sitemap.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://keith-links-995.netlify.app/</loc>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
</urlset>
```

- [ ] **Step 3: Create `robots.txt`**

Write `C:\Users\keyst\Personal-Landing-Page\robots.txt`:

```
User-agent: *
Allow: /

Sitemap: https://keith-links-995.netlify.app/sitemap.xml
```

- [ ] **Step 4: Verify**

Start `python -m http.server 8000`. Visit:
- http://localhost:8000/sitemap.xml — should display the XML sitemap.
- http://localhost:8000/robots.txt — should display the robots rules.
- http://localhost:8000/ → View Source (Ctrl+U). Confirm `<link rel="canonical">` and the JSON-LD `<script>` block are both present in `<head>`.

Optional: run the JSON-LD through Google's Rich Results Test (https://search.google.com/test/rich-results) by pasting the URL post-deploy.

- [ ] **Step 5: Commit**

```powershell
git add sitemap.xml robots.txt index.html
git -c commit.gpgsign=false commit -m "Add canonical, JSON-LD Person schema, sitemap.xml, robots.txt"
```

---

## Task 14: Final verification + deploy

**Files:** none (verification + deploy only)

- [ ] **Step 1: Full local smoke test**

```powershell
cd C:\Users\keyst\Personal-Landing-Page
python -m http.server 8000
```

Open http://localhost:8000/ and walk through:

1. **Hero:** avatar, KEITH wordmark, bio from `bio.json`, 2 lane cards (Chaturbate left / OnlyFans right side-by-side on desktop, stacked on mobile), 3 social buttons. Nav shows "Follow ↓" that scrolls to the social row.
2. **Schedule:** "When I'm Live" section renders below hero with next-stream callout and 7-chip weekly grid. Today's chip is outlined.
3. **Gallery:** 4 WebP tiles, blurred preview, click → "coming soon" modal → OnlyFans CTA. Modal close + backdrop click work.
4. **Testimonials:** 3 quote cards in "From the DMs" section.
5. **FAQ:** 6 items, accordion behavior intact, in-page link to `#schedule` works.
6. **Footer:** brand, 5 links (incl. Send a DM), copyright.
7. **Mobile (resize to <640px):** all sections stack; sticky bar appears below hero with two equal buttons.
8. **Network tab:** total transferred ≤ 1 MB. No 404s.
9. **DevTools Lighthouse:** Run on mobile preset. Expect Performance ≥ 90, Accessibility ≥ 95, SEO ≥ 95.

If any of the above fails, fix the relevant prior task before deploying.

- [ ] **Step 2: Confirm tools/ never ships**

```powershell
ls C:\Users\keyst\Personal-Landing-Page\tools\node_modules 2>$null
git check-ignore C:\Users\keyst\Personal-Landing-Page\tools\node_modules
```

Expected: `node_modules` dir exists locally, but `git check-ignore` confirms it's gitignored.

- [ ] **Step 3: Push to GitHub**

(User-authorized only — pause here for explicit confirmation per project convention.)

```powershell
git push origin main
```

- [ ] **Step 4: Deploy to Netlify**

Note: `netlify deploy --dir .` uploads everything in the working dir regardless of `.gitignore`. Before running, move `_image-sources/` and `tools/` out of the deploy path so originals + dev deps don't ship:

```powershell
Move-Item C:\Users\keyst\Personal-Landing-Page\_image-sources C:\Users\keyst\_deploy-stash\_image-sources -Force
Move-Item C:\Users\keyst\Personal-Landing-Page\tools C:\Users\keyst\_deploy-stash\tools -Force
netlify deploy --prod --dir C:\Users\keyst\Personal-Landing-Page
Move-Item C:\Users\keyst\_deploy-stash\_image-sources C:\Users\keyst\Personal-Landing-Page\_image-sources -Force
Move-Item C:\Users\keyst\_deploy-stash\tools C:\Users\keyst\Personal-Landing-Page\tools -Force
```

(Create the stash dir first if it doesn't exist: `New-Item -ItemType Directory -Force -Path C:\Users\keyst\_deploy-stash | Out-Null`.)

- [ ] **Step 5: Production smoke test**

Open https://keith-links-995.netlify.app/ in an incognito window. Re-walk the smoke-test checklist from Step 1. Test the OG share preview by pasting the URL into:
- Twitter Card Validator: https://cards-dev.twitter.com/validator
- Facebook Sharing Debugger: https://developers.facebook.com/tools/debug/

Both should render the new `og.png` card (1200×630 violet/dark branded).

- [ ] **Step 6: Commit any post-deploy fixes (if needed)**

If anything is off in production, fix locally, repeat verification, and re-deploy.

---

## Post-implementation handoff

Once deployed, the user still needs to (out-of-scope reminders, not plan tasks):

1. **Enable Netlify Identity** at https://app.netlify.com/projects/keith-links-995/configuration/identity to unlock CMS editing of `schedule.json`, `testimonials.json`, `bio.json`, `gallery.json`. Otherwise they remain JSON-file edits.
2. **Replace placeholder testimonials** with real fan quotes via the CMS (or by editing `testimonials.json` directly).
3. **Update `schedule.json`** with their real streaming schedule.
4. **Replace the placeholder `mailto:` and X compose-DM links** in the social row and footer if a real contact target is preferred.
5. **Consider adding GA4 or Plausible** for click-through measurement (deferred from this round).
6. **Real Stripe paywall** remains the next major feature when ready (~3 days, separate plan).
