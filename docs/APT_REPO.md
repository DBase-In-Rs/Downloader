# APT Repository Publishing (peace.dbase.in.rs)

The release workflow publishes the Debian package to the maintainer's apt
repository so Linux users install and update through `apt`.

## How it works

1. CI builds `dbase-downloader-vX.Y.Z-linux-amd64.deb` (Linux job).
2. On tag builds, CI pipes the .deb over SSH to the server. The deploy key
   is locked to a forced command (`peace-ingest`), so it can only ingest
   packages - no shell, no other files.
3. `peace-ingest` validates the package, drops it into `pool/main`,
   regenerates `Packages`/`Packages.gz` per architecture, rebuilds
   `Release`, and signs `Release.gpg` + `InRelease` with the repository GPG
   key.

GitHub secrets used: `PEACE_SSH_KEY` (private deploy key),
`PEACE_SSH_HOST` (SSH host: `eu.dbase.in.rs`; the repo is *served* at
https://peace.dbase.in.rs).

## One-time server setup (run as root)

Steps 1 and 4 (ownership, authorized_keys) were completed on 2026-08-27.

```bash
# 1. The repo belongs to the 'peace' user, which also signs it.
chown -R peace:peace /var/www/peace-repo

# 2. Move the repository GPG key from root to the 'peace' user. Piping
#    through sudo fails ("Inappropriate ioctl") because gpg needs a
#    terminal for the passphrase - export to a file with a tty instead:
export GPG_TTY=$(tty)
gpg --export-secret-keys 59114321298910073BF2AE8440F7E0F08D39A768 \
  > /tmp/repo-key.gpg          # prompts for the key passphrase
chown peace:peace /tmp/repo-key.gpg
su - peace -c 'export GPG_TTY=$(tty); gpg --import /tmp/repo-key.gpg'
rm -f /tmp/repo-key.gpg
sudo -u peace gpg --list-secret-keys   # must show "sec" for the key

# 2b. Only if the key HAS a passphrase: store it so the ingest script can
#     sign non-interactively (the script picks this file up automatically).
sudo -u peace bash -c \
  'read -rs -p "Repo key passphrase: " P; echo; \
   printf "%s" "$P" > ~/.gnupg/repo-passphrase; chmod 600 ~/.gnupg/repo-passphrase'

# 3. Install the ingest script straight from the app repository.
curl -fsSL https://raw.githubusercontent.com/DBase-In-Rs/Downloader/main/tool/server/peace-ingest \
  -o /usr/local/bin/peace-ingest
chmod 755 /usr/local/bin/peace-ingest

# 4. Authorize the CI deploy key, locked to the ingest command only.
mkdir -p /home/peace/.ssh && chmod 700 /home/peace/.ssh
cat >> /home/peace/.ssh/authorized_keys <<'EOF'
command="/usr/local/bin/peace-ingest",no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-pty ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFp/NaavT4hVO+JzrzmQNtu3tuVWkQN64lCmaJOtMQig dbase-downloader-ci
EOF
chmod 600 /home/peace/.ssh/authorized_keys
chown -R peace:peace /home/peace/.ssh
```

Test from any machine with the private key:

```bash
cat some-package.deb | ssh -i peace_ci_key peace@eu.dbase.in.rs
```

## User instructions (goes in README once live)

```bash
sudo install -d -m 755 /etc/apt/keyrings
curl -fsSL https://peace.dbase.in.rs/public.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/peace.gpg
echo "deb [signed-by=/etc/apt/keyrings/peace.gpg] https://peace.dbase.in.rs stable main" \
  | sudo tee /etc/apt/sources.list.d/peace.list
sudo apt update
sudo apt install dbase-downloader
```

Updates then arrive through normal `sudo apt upgrade`.

Note: the old `apt-key add` flow is deprecated on modern Debian/Ubuntu; the
keyring file above is the supported approach.
