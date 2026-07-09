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

## AeroSpace config is not selected

`~/.config/aerospace/aerospace.toml` is intentionally a per-machine symlink chosen by `install/macos.sh`. Re-run the installer on macOS and choose the appropriate config when prompted:

```sh
cd ~/dotfiles
./install.sh
```

The generated `aerospace.toml` symlink is gitignored.
