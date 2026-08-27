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
`PEACE_SSH_HOST` (server host).

## One-time server setup (run as root)

```bash
# 1. The repo belongs to the 'peace' user, which also signs it.
chown -R peace:peace /var/www/peace-repo

# 2. Give the 'peace' user the repository GPG key (currently in root's
#    keyring).
gpg --export-secret-keys 59114321298910073BF2AE8440F7E0F08D39A768 \
  | sudo -u peace gpg --import

# 3. Install the ingest script (content: tool/server/peace-ingest in the
#    app repository).
install -m 755 peace-ingest /usr/local/bin/peace-ingest

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
cat some-package.deb | ssh -i peace_ci_key peace@peace.dbase.in.rs
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
