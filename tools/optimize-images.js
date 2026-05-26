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

const SOURCE_EXTS = ['.jpg', '.jpeg', '.png', '.webp'];

function findSource(stem, subdir = '') {
  for (const ext of SOURCE_EXTS) {
    const p = path.join(SRC, subdir, stem + ext);
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
    const src = findSource(stem, 'gallery');
    if (!src) {
      console.log(`SKIP ${stem}: no _image-sources/gallery/${stem}.{jpg,png,webp} found`);
      continue;
    }
    const out = path.join(OUT_GALLERY, stem + '.webp');
    // fit: 'cover' center-crops the source to 3:4. Provide a source ≥600×800 in 3:4 to avoid losing content.
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
