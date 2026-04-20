# Markdown Quick Reference

Everything you need to know to write your weekly entries.

## Adding a new weekly entry

1. Open the `docs/entries/` folder.
2. Copy the most recent `YYYY-MM-DD-slug` folder and rename it: start with today's date, then a short description (e.g. `2026-04-27-trip-to-berlin`).
3. Open `index.md` inside the new folder.
4. Update the date and title at the top (inside the `---` block).
5. Write your entry below.
6. Drop photos into the same folder.
7. Double-click **Upload My Website** on your desktop.

## Text formatting

| What | How |
|---|---|
| Big heading | `# Heading` |
| Smaller heading | `## Heading` |
| Bold | `**bold text**` |
| Italic | `*italic text*` |
| Bullet list | `- item` |
| Numbered list | `1. item` |
| Link | `[link text](https://example.com)` |
| Image | `![caption](photo.jpg)` |

## Images

Drop the image file into the same folder as your `index.md`, then reference it by filename only:

```
![A lovely sunset](sunset.jpg)
```

For the gallery page: drop images into `docs/pictures/` and reference them as:

```
![Caption](../pictures/sunset.jpg)
```

## The date/title block

Each entry's `index.md` starts with:

```
---
date: 2026-04-20
authors:
  - her
---

# Entry Title
```

The date is what orders the entries. Keep the format `YYYY-MM-DD`.

## If something looks wrong on the site

1. Wait 2 minutes — the site rebuilds on every upload, it's not instant.
2. Check the date in the entry's `index.md` — if it's in the future, the entry won't show.
3. Check photo filenames — uppercase/lowercase matters. `Photo.jpg` is different from `photo.jpg`.
4. Still wrong? Message the person who set this up.
