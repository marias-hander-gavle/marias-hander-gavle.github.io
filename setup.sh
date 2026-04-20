#!/usr/bin/env bash
# One-time setup for Mac. Installs prerequisites, runs GitHub OAuth, clones the repo,
# creates a Desktop shortcut.

set -u

say() { printf '%s\n' "$1"; }
die() { say ""; say "✗ $1"; say ""; exit 1; }

say "=== Setting up your website tools ==="
say ""

# Check for git.
if ! command -v git >/dev/null 2>&1; then
  say "Git is not installed."
  say "macOS will now prompt you to install the Command Line Tools."
  xcode-select --install || true
  die "After the tools finish installing, please re-run this script."
fi

# Check for gh CLI; install via Homebrew if missing.
if ! command -v gh >/dev/null 2>&1; then
  # If brew is installed but not yet on PATH (common right after installing Homebrew),
  # load its environment from the standard locations.
  if ! command -v brew >/dev/null 2>&1; then
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  if command -v brew >/dev/null 2>&1; then
    say "→ Installing GitHub CLI via Homebrew..."
    brew install gh || die "Could not install 'gh'. Please install it manually from https://cli.github.com and re-run."
  else
    die "Homebrew is not installed. Please install Homebrew from https://brew.sh, then re-run this script."
  fi
fi

# OAuth login via browser.
if ! gh auth status >/dev/null 2>&1; then
  say "→ Signing in to GitHub (a browser will open)..."
  gh auth login --web --git-protocol https --hostname github.com || die "GitHub sign-in failed. Please try again."
fi

# Configure git to use gh's stored OAuth token as its credential helper.
# Without this, a later `git clone` over HTTPS may fall through to a password prompt and fail.
gh auth setup-git 2>/dev/null || die "Could not wire gh credentials into git. Try running 'gh auth setup-git' manually."

# Prompt for username and repo.
printf "GitHub username: "
read -r GH_USERNAME
[ -n "$GH_USERNAME" ] || die "Username cannot be empty."

DEFAULT_REPO="${GH_USERNAME}.github.io"
printf "Repository name [%s]: " "$DEFAULT_REPO"
read -r REPO_NAME
REPO_NAME="${REPO_NAME:-$DEFAULT_REPO}"

CLONE_DIR="$HOME/Documents/my-website"
if [ -d "$CLONE_DIR/.git" ]; then
  say "→ Repo already cloned at $CLONE_DIR; skipping clone."
else
  say "→ Cloning $GH_USERNAME/$REPO_NAME into $CLONE_DIR..."
  git clone "https://github.com/$GH_USERNAME/$REPO_NAME.git" "$CLONE_DIR" || die "Clone failed. Double-check the repo name and that it exists."
fi

# Configure git name/email if not set.
cd "$CLONE_DIR" || die "Could not enter $CLONE_DIR."
if [ -z "$(git config user.name || true)" ]; then
  printf "Your name (for commit history): "
  read -r GIT_NAME
  git config user.name "$GIT_NAME"
fi
if [ -z "$(git config user.email || true)" ]; then
  printf "Your email: "
  read -r GIT_EMAIL
  git config user.email "$GIT_EMAIL"
fi

# Create a .command shortcut on Desktop that runs upload.sh.
SHORTCUT="$HOME/Desktop/Upload My Website.command"
cat > "$SHORTCUT" <<EOF
#!/usr/bin/env bash
cd "$CLONE_DIR" && ./upload.sh
EOF
chmod +x "$SHORTCUT"

say ""
say "✓ All set!"
say ""
say "  Your files: $CLONE_DIR"
say "  Upload shortcut: $SHORTCUT (on your Desktop)"
say ""
say "Edit files inside $CLONE_DIR, then double-click 'Upload My Website' on your Desktop."
say ""
