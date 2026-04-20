#!/usr/bin/env bash
# Weekly upload script for Mac. Double-clickable when renamed to .command.

set -u

# Resolve the repo root from the script's own location.
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR" || exit 1

LOG_DIR="$HOME/Desktop"
LOG_FILE="$LOG_DIR/upload-log-$(date +%Y-%m-%d-%H%M%S).txt"

say() { printf '%s\n' "$1"; }

# Append a status snapshot to the log so the setup author has useful context.
log_status_snapshot() {
  {
    echo ""
    echo "--- git status ---"
    git status 2>&1 | tail -20
    echo "--- git log -5 ---"
    git log --oneline -5 2>&1
  } >> "$LOG_FILE" 2>/dev/null || true
}

fail() {
  log_status_snapshot
  say ""
  say "✗ $1"
  say ""
  say "A log has been saved to: $LOG_FILE"
  say "Please send it to the person who set this up."
  say ""
  read -n 1 -s -r -p "Press any key to close..."
  exit 1
}

# Check internet.
if ! curl -s --max-time 5 https://github.com > /dev/null; then
  fail "No internet connection. Check your Wi-Fi and try again."
fi

say "→ Checking for updates from GitHub..."
if ! git pull --rebase 2> "$LOG_FILE.tmp"; then
  cat "$LOG_FILE.tmp" >> "$LOG_FILE"
  git rebase --abort 2>/dev/null || true
  if grep -q -i "could not read Username\|Authentication failed" "$LOG_FILE.tmp"; then
    rm -f "$LOG_FILE.tmp"
    fail "GitHub sign-in expired. Please re-run the setup script to sign in again."
  fi
  if grep -q -i "conflict" "$LOG_FILE.tmp"; then
    rm -f "$LOG_FILE.tmp"
    fail "Something got out of sync. We couldn't merge the changes automatically."
  fi
  rm -f "$LOG_FILE.tmp"
  fail "Something unexpected happened while checking for updates."
fi
rm -f "$LOG_FILE.tmp"

say "→ Preparing your changes..."
git add -A

if git diff --cached --quiet; then
  say ""
  say "✓ No changes to upload — everything's already up to date."
  say ""
  read -n 1 -s -r -p "Press any key to close..."
  exit 0
fi

TIMESTAMP="$(date +'%Y-%m-%d %H:%M')"
say "→ Saving your changes..."
if ! git commit -m "Update $TIMESTAMP" > "$LOG_FILE.tmp" 2>&1; then
  cat "$LOG_FILE.tmp" >> "$LOG_FILE"
  rm -f "$LOG_FILE.tmp"
  fail "Something went wrong saving your changes."
fi
rm -f "$LOG_FILE.tmp"

say "→ Uploading to GitHub..."
if ! git push 2> "$LOG_FILE.tmp"; then
  cat "$LOG_FILE.tmp" >> "$LOG_FILE"
  if grep -q -i "could not read Username\|Authentication failed" "$LOG_FILE.tmp"; then
    rm -f "$LOG_FILE.tmp"
    fail "GitHub sign-in expired. Please re-run the setup script to sign in again."
  fi
  if grep -q -i "Could not resolve host\|Failed to connect\|Connection timed out\|Network is unreachable" "$LOG_FILE.tmp"; then
    rm -f "$LOG_FILE.tmp"
    fail "Lost internet connection while uploading. Your changes are saved locally — check your Wi-Fi and try again."
  fi
  rm -f "$LOG_FILE.tmp"
  fail "Something went wrong uploading."
fi
rm -f "$LOG_FILE.tmp"

REPO_URL="$(git config --get remote.origin.url 2>/dev/null || echo '')"
USERNAME="$(printf '%s' "$REPO_URL" | sed -E 's#.*[:/]([^/]+)/[^/]+\.git$#\1#')"

say ""
say "✓ Uploaded! Your site will update in about 1 minute."
if [ -n "$USERNAME" ] && [ "$USERNAME" != "$REPO_URL" ]; then
  say "  Visit: https://${USERNAME}.github.io"
fi
say ""
read -n 1 -s -r -p "Press any key to close..."
exit 0
