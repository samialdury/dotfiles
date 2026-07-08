# Troubleshooting

## GitHub SSH authentication fails

Make sure the machine has its own SSH key and that the public key is registered with GitHub.

```sh
ssh -T git@github.com
```

If Git picks the wrong identity, add an explicit host entry:

```ssh-config
Host github.com
  User git
  HostName github.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/id_ed25519
```

## Commits fail because signing is unavailable

`.config/git/config` enables SSH commit signing with `id_ed25519.pub`. On a new machine, commits can fail until the signing key exists and Git can find it.

Check:

```sh
git config --get commit.gpgsign
git config --get gpg.format
git config --get user.signingkey
ls ~/.ssh/id_ed25519.pub
```

Fix by creating/restoring the machine-local SSH key and ensuring the public key path in Git config exists.

## `./install.sh` says Bash 4+ is required

The installer uses Bash 4+ features. On macOS, `/bin/bash` is too old. The script bootstraps Homebrew Bash when possible, then re-execs under `/opt/homebrew/bin/bash`.

Install Homebrew first, then rerun:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
cd ~/dotfiles
./install.sh
```

## Old Bash symlinks still exist after pulling this repo

Legacy interactive Bash files were removed from the repo. The current installer will not create them, but it also will not remove old symlinks created manually or by older versions.

Inspect first:

```sh
for path in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.bash" "$HOME/.inputrc"; do
  if [ -L "$path" ]; then
    target="$(readlink "$path")"
    case "$target" in
      */dotfiles/.bashrc|*/dotfiles/.bash_profile|*/dotfiles/.bash|*/dotfiles/.inputrc)
        printf 'old dotfiles symlink: %s -> %s\n' "$path" "$target"
        ;;
    esac
  fi
done
```

If the output lists only dotfiles-owned legacy symlinks, remove them:

```sh
rm "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.inputrc" 2>/dev/null || true
rm "$HOME/.bash" 2>/dev/null || true
```

Do not remove real non-symlink files without reading them first.

## AeroSpace config is not selected

`~/.config/aerospace/aerospace.toml` is intentionally a per-machine symlink chosen by `install/macos.sh`. Re-run the installer on macOS and choose the appropriate config when prompted:

```sh
cd ~/dotfiles
./install.sh
```

The generated `aerospace.toml` symlink is gitignored.

## Structure check fails on legacy Bash config

`./scripts/test-install.sh` rejects these tracked paths:

```text
.bashrc
.bash_profile
.bash
.inputrc
```

Remove the legacy file or directory from the repo. Bash should remain only as installer/tooling code.
