# Dotfiles Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add focused verification and validation for the dotfiles installer, then remove the remaining machine-specific Claude statusline path.

**Architecture:** Keep `./install.sh` as the only user-facing installer interface. Deepen the existing `install/links.sh` module by making link-table invariants explicit, and add a small dependency-free test harness that exercises platform link composition without running package managers, symlink writes, login-shell changes, macOS defaults, or interactive prompts.

**Tech Stack:** Bash 4+, zsh syntax check when `zsh` exists, jq for JSON validation, existing Git hook flow.

## Global Constraints

- Do not add BATS, pytest, Node, Husky, GNU Stow, Nix, Ansible, or a new package manager dependency.
- Do not run `./install.sh` during implementation verification; it performs real installs/links.
- Do not change macOS, Omarchy, or Debian install behavior except to fail earlier on invalid committed link-table data.
- Preserve the committed Git hook behavior: `.githooks/pre-commit` formats `.claude/settings.json` with `jq -S` when that file is staged.
- Preserve `install.sh` as the one command users run.
- Preserve the `LINKS_*` group model in `install/links.sh`.
- Preserve `~/.claude/skills -> ../.agents/skills` as a special post-link cross-package symlink unless a later task explicitly replaces it.
- Keep tests executable from macOS without root privileges.
- Targeted verification commands are required after each task.

---

## File Structure

- Create `scripts/test-install.sh`
  - Responsibility: source installer modules in a safe mode, assert link profile composition and syntax, and exit nonzero on structural drift.
  - Interface: executable command `./scripts/test-install.sh`.

- Modify `install/links.sh`
  - Responsibility: link group declarations, link-table validation, link application, and Claude skills cross-link.
  - New interface: `validate_links`, called by `build_links` after `platform_add_links`.

- Modify `.claude/settings.json`
  - Responsibility: shared Claude Code settings across machines.
  - Change only `statusLine.command` from an absolute `/Users/sami/...` path to a `$HOME`-resolved command.

- Modify `AGENTS.md`
  - Responsibility: keep project instructions aligned with the new test harness and statusline command.

---

## Task 1: Add Installer Structure Test Harness

**Files:**
- Create: `scripts/test-install.sh`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: existing installer module functions from `install/lib.sh`, `install/packages.sh`, `install/links.sh`, `install/shell.sh`, `install/tmux.sh`, `install/macos.sh`, `install/omarchy.sh`, and `install/debian.sh`.
- Produces: executable command `./scripts/test-install.sh`.

### Intended behavior

`./scripts/test-install.sh` must verify:

- `bash -n install.sh install/*.sh` passes.
- `zsh -n .zshrc .zsh/*.zsh` passes when `zsh` exists; otherwise prints a skip line.
- macOS link profile contains `.zshrc`, `.config/ghostty`, `.config/aerospace`, `.config/homebrew`, and `.claude/settings.json`.
- Omarchy link profile contains `.claude/settings.json`, `.config/workmux`, and `.config/nvim`.
- Omarchy link profile does **not** contain `.zshrc`, `.config/tmux`, `.config/starship.toml`, `.config/ghostty`, or `.config/aerospace`.
- Debian link profile contains `.zshrc`, `.zsh`, `.config/tmux`, `.config/starship.toml`, `.config/workmux`, and `.claude/settings.json`.
- Debian link profile does **not** contain `.config/ghostty`, `.config/aerospace`, or `.config/homebrew`.
- Every composed link entry has exactly three nonempty fields: `src::target::mode`.
- Every mode is `file` or `dir`.
- Every composed link source exists in the repo.
- Every composed profile has no duplicate target path.

### Steps

- [ ] **Step 1: Create the test script**

Create `scripts/test-install.sh` with this content:

```bash
#!/usr/bin/env bash

# Match install.sh's Bash 4+ requirement without installing anything.
if ((BASH_VERSINFO[0] < 4)); then
  if [ -x /opt/homebrew/bin/bash ]; then
    exec /opt/homebrew/bin/bash "$0" "$@"
  fi

  printf 'error: %s requires Bash 4+. Install Homebrew bash or run through ./install.sh first.\n' "$0" >&2
  exit 1
fi
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pass() {
  printf 'ok %s\n' "$*"
}

fail() {
  printf 'not ok %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local needle="$1"
  shift

  local item
  for item in "$@"; do
    if [ "$item" = "$needle" ]; then
      return 0
    fi
  done

  fail "expected profile to contain $needle"
}

assert_not_contains() {
  local needle="$1"
  shift

  local item
  for item in "$@"; do
    if [ "$item" = "$needle" ]; then
      fail "expected profile to exclude $needle"
    fi
  done
}

link_sources() {
  local entry
  for entry in "${LINKS[@]}"; do
    printf '%s\n' "${entry%%::*}"
  done
}

check_link_entries() {
  local platform="$1"
  local entry src_rel rest target mode
  local -A targets=()

  for entry in "${LINKS[@]}"; do
    if [[ "$entry" != *::*::* ]]; then
      fail "$platform link entry is not src::target::mode: $entry"
    fi

    src_rel="${entry%%::*}"
    rest="${entry#*::}"
    target="${rest%%::*}"
    mode="${rest#*::}"

    [ -n "$src_rel" ] || fail "$platform link entry has empty source: $entry"
    [ -n "$target" ] || fail "$platform link entry has empty target: $entry"

    case "$mode" in
    file | dir) ;;
    *) fail "$platform link entry has invalid mode '$mode': $entry" ;;
    esac

    [ -e "$REPO/$src_rel" ] || fail "$platform link source missing: $src_rel"

    if [ -n "${targets[$target]+set}" ]; then
      fail "$platform duplicate link target: $target from $src_rel and ${targets[$target]}"
    fi
    targets[$target]="$src_rel"
  done
}

build_profile() {
  local platform="$1"
  OS_TYPE="$platform"
  build_links
  check_link_entries "$platform"
}

# shellcheck source=../install/lib.sh
. "$REPO/install/lib.sh"
# shellcheck source=../install/packages.sh
. "$REPO/install/packages.sh"
# shellcheck source=../install/links.sh
. "$REPO/install/links.sh"
# shellcheck source=../install/shell.sh
. "$REPO/install/shell.sh"
# shellcheck source=../install/tmux.sh
. "$REPO/install/tmux.sh"
# shellcheck source=../install/macos.sh
. "$REPO/install/macos.sh"
# shellcheck source=../install/omarchy.sh
. "$REPO/install/omarchy.sh"
# shellcheck source=../install/debian.sh
. "$REPO/install/debian.sh"

bash -n "$REPO/install.sh" "$REPO"/install/*.sh
pass "bash syntax"

if command -v zsh >/dev/null 2>&1; then
  zsh -n "$REPO/.zshrc" "$REPO"/.zsh/*.zsh
  pass "zsh syntax"
else
  pass "zsh syntax skipped: zsh not installed"
fi

build_profile macos
mapfile -t macos_sources < <(link_sources)
assert_contains ".claude/settings.json" "${macos_sources[@]}"
assert_contains ".zshrc" "${macos_sources[@]}"
assert_contains ".config/ghostty" "${macos_sources[@]}"
assert_contains ".config/aerospace" "${macos_sources[@]}"
assert_contains ".config/homebrew" "${macos_sources[@]}"
pass "macos link profile"

build_profile omarchy
mapfile -t omarchy_sources < <(link_sources)
assert_contains ".claude/settings.json" "${omarchy_sources[@]}"
assert_contains ".config/workmux" "${omarchy_sources[@]}"
assert_contains ".config/nvim" "${omarchy_sources[@]}"
assert_not_contains ".zshrc" "${omarchy_sources[@]}"
assert_not_contains ".config/tmux" "${omarchy_sources[@]}"
assert_not_contains ".config/starship.toml" "${omarchy_sources[@]}"
assert_not_contains ".config/ghostty" "${omarchy_sources[@]}"
assert_not_contains ".config/aerospace" "${omarchy_sources[@]}"
pass "omarchy link profile"

build_profile debian
mapfile -t debian_sources < <(link_sources)
assert_contains ".claude/settings.json" "${debian_sources[@]}"
assert_contains ".zshrc" "${debian_sources[@]}"
assert_contains ".zsh" "${debian_sources[@]}"
assert_contains ".config/tmux" "${debian_sources[@]}"
assert_contains ".config/starship.toml" "${debian_sources[@]}"
assert_contains ".config/workmux" "${debian_sources[@]}"
assert_not_contains ".config/ghostty" "${debian_sources[@]}"
assert_not_contains ".config/aerospace" "${debian_sources[@]}"
assert_not_contains ".config/homebrew" "${debian_sources[@]}"
pass "debian link profile"
```

- [ ] **Step 2: Make the script executable**

Run:

```bash
chmod +x scripts/test-install.sh
```

- [ ] **Step 3: Run the new harness**

Run:

```bash
./scripts/test-install.sh
```

Expected output includes these lines:

```text
ok bash syntax
ok zsh syntax
ok macos link profile
ok omarchy link profile
ok debian link profile
```

If `zsh` is not installed, expected second line is:

```text
ok zsh syntax skipped: zsh not installed
```

- [ ] **Step 4: Update AGENTS.md command list**

In `AGENTS.md`, add this command near the existing syntax-check bullets:

```markdown
- Installer structure test: `./scripts/test-install.sh` verifies Bash syntax, zsh syntax when available, platform link composition, link-table shape, source existence, and duplicate link targets without running the real installer.
```

- [ ] **Step 5: Verify documentation and harness together**

Run:

```bash
./scripts/test-install.sh
```

Expected: exit 0 and the same `ok ...` lines from Step 3.

- [ ] **Step 6: Commit**

Run:

```bash
git add scripts/test-install.sh AGENTS.md
git commit -m "test(install): add structure harness"
```

---

## Task 2: Validate Link Tables Before Applying Links

**Files:**
- Modify: `install/links.sh`
- Modify: `scripts/test-install.sh` if needed after implementation
- Modify: `AGENTS.md` if the validation behavior needs documentation detail

**Interfaces:**
- Consumes: final `LINKS` array composed by `platform_add_links`.
- Produces: function `validate_links`, called by `build_links`.

### Intended behavior

`build_links` must fail before any symlink writes when a composed link profile has invalid committed metadata.

Validation failures must use `log_error` and exit nonzero for:

- malformed entry that is not `src::target::mode`
- empty source
- empty target
- mode other than `file` or `dir`
- missing source path under `$REPO`
- duplicate target path in the final composed `LINKS` array

### Steps

- [ ] **Step 1: Add `validate_links` to `install/links.sh`**

Insert this function after `build_links` or directly before it, then call it from `build_links` after `platform_add_links`:

```bash
validate_links() {
  local entry src_rel rest target mode
  local -A targets=()

  for entry in "${LINKS[@]}"; do
    if [[ "$entry" != *::*::* ]]; then
      log_error "Invalid link entry; expected src::target::mode: $entry"
      exit 1
    fi

    src_rel="${entry%%::*}"
    rest="${entry#*::}"
    target="${rest%%::*}"
    mode="${rest#*::}"

    if [ -z "$src_rel" ]; then
      log_error "Invalid link entry with empty source: $entry"
      exit 1
    fi

    if [ -z "$target" ]; then
      log_error "Invalid link entry with empty target: $entry"
      exit 1
    fi

    case "$mode" in
    file | dir) ;;
    *)
      log_error "Invalid link mode '$mode' for $src_rel; expected file or dir."
      exit 1
      ;;
    esac

    if [ ! -e "$REPO/$src_rel" ]; then
      log_error "Link source missing for $target: $REPO/$src_rel"
      exit 1
    fi

    if [ -n "${targets[$target]+set}" ]; then
      log_error "Duplicate link target $target from $src_rel and ${targets[$target]}"
      exit 1
    fi

    targets[$target]="$src_rel"
  done
}

build_links() {
  LINKS=()
  platform_add_links
  validate_links
}
```

Keep `append_links`, `link_one`, `apply_links`, and `link_claude_skills` behavior otherwise unchanged.

- [ ] **Step 2: Run syntax and structure checks**

Run:

```bash
bash -n install.sh install/*.sh
./scripts/test-install.sh
```

Expected:

```text
bash -n: exit 0, no output
./scripts/test-install.sh: exit 0 with ok lines
```

- [ ] **Step 3: Manually prove duplicate-target validation fails**

Use a temporary copy so the repo is not modified:

```bash
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cp -R . "$tmpdir/repo"
cd "$tmpdir/repo"
printf '\nLINKS_BASE+=(".hushlogin::$HOME/.config/git/config::file")\n' >> install/links.sh
if ./scripts/test-install.sh >/tmp/dotfiles-test.out 2>/tmp/dotfiles-test.err; then
  echo "expected duplicate target validation to fail" >&2
  exit 1
fi
cat /tmp/dotfiles-test.out /tmp/dotfiles-test.err
```

Expected combined output contains:

```text
Duplicate link target
```

Return to the real repo before continuing:

```bash
cd - >/dev/null
```

- [ ] **Step 4: Verify real repo remains clean except intended files**

Run:

```bash
git status --short
```

Expected: only intended changes from `install/links.sh` and possibly `scripts/test-install.sh` / `AGENTS.md`.

- [ ] **Step 5: Commit**

Run:

```bash
git add install/links.sh scripts/test-install.sh AGENTS.md
git commit -m "fix(install): validate link tables"
```

---

## Task 3: Make Claude Statusline Command Home-Relative

**Files:**
- Modify: `.claude/settings.json`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: existing `.claude/statusline-command.sh` executable script.
- Produces: machine-portable `statusLine.command` in `.claude/settings.json`.

### Intended behavior

Change this:

```json
"command": "bash /Users/sami/.claude/statusline-command.sh"
```

to this:

```json
"command": "bash -c 'exec \"$HOME/.claude/statusline-command.sh\"'"
```

Rationale:

- `bash -c` resolves `$HOME` on macOS and Debian without sourcing login-shell startup files on every statusline render.
- `exec` avoids leaving an extra shell process alive after the statusline command starts.
- The command string remains valid JSON and valid shell.

### Steps

- [ ] **Step 1: Update `.claude/settings.json`**

Change the `statusLine.command` value to:

```json
"bash -c 'exec \"$HOME/.claude/statusline-command.sh\"'"
```

- [ ] **Step 2: Validate JSON**

Run:

```bash
jq -e . .claude/settings.json >/dev/null
```

Expected: exit 0, no output.

- [ ] **Step 3: Verify the command resolves `$HOME` in a fake home**

Run:

```bash
tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT
mkdir -p "$tmp_home/.claude"
cp .claude/statusline-command.sh "$tmp_home/.claude/statusline-command.sh"
chmod +x "$tmp_home/.claude/statusline-command.sh"
printf '%s\n' '{"workspace":{"current_dir":"'"$PWD"'"},"model":{"display_name":"test-model"},"context_window":{"used_percentage":12}}' \
  | HOME="$tmp_home" bash -c 'exec "$HOME/.claude/statusline-command.sh"' \
  | cat -v
```

Expected output contains:

```text
test-model
```

It may also contain ANSI escape markers from color output. That is acceptable.

- [ ] **Step 4: Update AGENTS.md**

Replace the old warning:

```markdown
- `statusLine.command` currently uses an absolute path `/Users/sami/.claude/statusline-command.sh`. If editing for non-sami machines, make this `$HOME`-relative or document the rename.
```

with:

```markdown
- `statusLine.command` uses `bash -c 'exec "$HOME/.claude/statusline-command.sh"'` so the shared settings file works on macOS and Debian home paths without sourcing login-shell startup files on every statusline render. Preserve `$HOME` resolution if editing it.
```

- [ ] **Step 5: Run the committed JSON formatter manually**

Run:

```bash
jq -S . .claude/settings.json > /tmp/claude-settings.sorted.json
mv /tmp/claude-settings.sorted.json .claude/settings.json
jq -e . .claude/settings.json >/dev/null
```

Expected: exit 0. This mirrors the committed pre-commit hook behavior.

- [ ] **Step 6: Run full hardening verification**

Run:

```bash
./scripts/test-install.sh
bash -n .githooks/pre-commit
```

Expected:

```text
./scripts/test-install.sh: exit 0 with ok lines
bash -n .githooks/pre-commit: exit 0, no output
```

- [ ] **Step 7: Commit**

Run:

```bash
git add .claude/settings.json AGENTS.md
git commit -m "fix(claude): use home-relative statusline"
```

---

## Final Verification

Run:

```bash
./scripts/test-install.sh
bash -n install.sh install/*.sh .githooks/pre-commit
zsh -n .zshrc .zsh/*.zsh
git status --short
```

Expected:

```text
./scripts/test-install.sh exits 0 with ok lines
bash -n exits 0 with no output
zsh -n exits 0 with no output when zsh is installed
git status --short prints no tracked changes after commits
```

Do **not** run `./install.sh` as final verification unless the user explicitly wants to apply the installer on the current machine.

---

## Self-Review

- Spec coverage: covers the three high-value improvements: installer test harness, link-table validation, and portable Claude statusline command.
- Placeholder scan: no TODO/TBD/fill-in-later steps remain.
- Type/name consistency: produced interfaces are `./scripts/test-install.sh` and `validate_links`; both are referenced consistently.
- YAGNI check: no external test framework, no new manifest format, no installer flags, no Stow/Nix/Ansible migration.
