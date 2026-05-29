# Instagram Posting Planner — Design Spec

**Date:** 2026-05-28
**Status:** Approved
**Scope:** New standalone `planner.html` page on the Personal Landing Page.

## Purpose

A **private** weekly planner for the creator to lay out when they plan to post
to Instagram. It is an operational tool for the creator only — NOT fan-facing.

## Decisions (from brainstorming)

- **Type & audience:** Private planner, edited live in the browser, hidden from
  fans. Persists via `localStorage` (no backend, no deploy to change).
- **Placement:** Separate page at `/planner.html`, not linked from the nav,
  footer, or anywhere on `index.html`. Reachable by direct URL / bookmark only.
- **Posts per day:** One planned post per day (or "off"/empty).
- **Fields per post:** Time + content type (Reel / Photo / Carousel / Story) +
  short free-text note.
- **Cadence:** Recurring weekly routine (Mon–Sun columns), not calendar dates.

## Layout

1. **Header** — "Instagram Planner" title + sub-line: "Private — saved on this
   device only." Small "← Back to site" link to `/`.
2. **Weekly grid** — 7 day cells Mon–Sun, today highlighted. Each cell shows the
   planned time + a color-coded type chip + the note, or a muted "Off" when
   empty. 7-column grid on wide screens; collapses to a stacked day list on
   mobile.
3. **Edit panel** (inline, below the grid) — clicking a day selects it and shows
   a form: `<input type="time">`, a type `<select>`, a note `<input>`
   (maxlength ~80), plus **Save** and **Clear day** buttons. A "Clear whole
   week" action sits at the bottom (with confirm).

## Data model

Single `localStorage` key `ig_planner_v1`:

```json
{
  "Mon": { "time": "18:00", "type": "Reel", "note": "gym set" },
  "Tue": null,
  "Wed": { "time": "07:30", "type": "Photo", "note": "" },
  "Thu": null, "Fri": null, "Sat": null, "Sun": null
}
```

- `time` stored 24h `HH:MM` (from the native time input); displayed 12h (6:00 PM).
- A `null` (or missing) day = no post / "Off".
- Every Save / Clear writes immediately.

## Type chip colors

- Reel — coral `#ff8fa3`
- Photo — violet `#c0a8ff`
- Carousel — cyan `#5fd0e0`
- Story — amber `#ffcf6b`

## Constraints / consistency

- Self-contained single file; reuses the site theme tokens (bg `#060608`,
  violet `#7a4dff`/`#a06bff`, Inter + Archivo Black).
- No new dependencies, no build step.
- All dynamic DOM via `createElement` + `textContent` (the note is free text and
  the project's security hook blocks `innerHTML` on dynamic content).
- `prefers-reduced-motion` respected.

## Out of scope (YAGNI)

- Multiple posts per day, calendar dates, cross-device sync, CMS integration.
- A "Copy week / Paste week" text export was offered as a cheap cross-device
  workaround; deferred — easy to add later if device-portability is wanted.

## Addendum — page enrichment (2026-05-28)

Added four panels so the page reads as a full tool, all client-side and
localStorage-derived:

1. **Stat bar** (above the grid) — "Next post" (next upcoming slot across the
   recurring week, in local time + relative "in Xh", refreshed every 60s) and a
   "This week" block: planned-vs-off counts + a content-mix meter
   (colored segments + legend by type).
2. **Recommended-time hint** in the editor — `💡 Most active <Day>: <window>`
   pulled from the `RECOMMENDED` map for the selected day.
3. **Best Times to Post panel** — per-day recommended windows (today highlighted)
   + a tip line. `RECOMMENDED` map holds starter niche benchmarks; swap with the
   user's real Instagram Insights later.
4. **Need an Idea? panel** — on-brand prompt bank (`IDEAS`), shows 5 random with
   a "New ideas" shuffle. Tapping an idea drops it into the selected day's note
   (or copies to clipboard if no day selected). Prompts pass Brand Guard
   (witty/teasing, one joke, innuendo-not-crude, short).

All still DOM-methods + `textContent` (mix-meter colors set via `element.style`,
not innerHTML).

## Privacy note

`localStorage` is per-device and per-browser. The plan never leaves the browser,
is not present in the page's shipped HTML, and is not visible to fans even if
they find the URL. Clearing browser data wipes it — stated on the page.
