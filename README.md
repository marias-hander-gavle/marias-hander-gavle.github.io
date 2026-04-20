# My Weekly Website

This is the source for my personal website at `https://herusername.github.io`.

## For me (the author)

To add a weekly entry: see [`CHEATSHEET.md`](CHEATSHEET.md).

To publish: double-click **Upload My Website** on my Desktop.

## For whoever set this up

- Tech stack: MkDocs + Material theme, deployed to GitHub Pages via GitHub Actions.
- Authentication: Git Credential Manager (Windows) / `gh` CLI (Mac) — browser OAuth.
- Weekly entries: `docs/entries/YYYY-MM-DD-slug/index.md` + co-located images.
- Homepage is auto-assembled by Material's blog plugin.
- Build runs on push to `main` via `.github/workflows/deploy.yml`.

### Local development

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
mkdocs serve
```

Open http://127.0.0.1:8000 to preview.
