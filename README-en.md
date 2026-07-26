<div align="center">

[**فارسی**](./README.md) | [**English**](./README-en.md)

# Wildcard SSL for Marzban and PasarGuard

Issue, deploy, and automatically renew a multi-domain certificate with `acme.sh`, Let's Encrypt, and Cloudflare DNS.

</div>

---

<div align="center">
  <a href="https://www.youtube.com/watch?v=5-RiZ1qNT90" target="_blank">
    <img src="https://img.youtube.com/vi/5-RiZ1qNT90/hqdefault.jpg" alt="Watch the complete video tutorial" width="320">
  </a>
  <p><strong>Click the image above to watch the complete video tutorial</strong></p>
</div>

## What does this script do?

This project is designed for Marzban and PasarGuard users. You enter base domains such as `example.com`, and the script automatically includes both names below:

```text
example.com
*.example.com
```

After issuance, it updates the panel's SSL paths, restarts the panel, and installs a fully non-interactive daily renewal check.

## Features

- Official-install support for **Marzban**
- Official-install support for **PasarGuard**
- Deploy to either panel or both panels
- Automatic panel detection
- Multiple base domains in one certificate
- Automatic apex and wildcard SAN creation
- Hidden Cloudflare API Token input
- Secrets stored with `600` permissions
- Automatic `.env` backup before changes
- Idempotent `UVICORN_SSL_*` updates without duplicate entries
- Certificate/private-key match validation
- Non-interactive renewal using cron and the standard `acme.sh` reload hook
- Concurrent-run protection
- Optional Telegram notifications
- Status and log commands

## Requirements

- Ubuntu or Debian
- `root` or `sudo` access
- An official Marzban and/or PasarGuard installation
- Cloudflare DNS for every domain
- One Cloudflare API Token with access to every entered zone

> All domains in one certificate must be accessible through the same token. If zones belong to separate Cloudflare accounts and no single token can access them, they cannot be issued together by this setup.

## Create a Cloudflare API Token

1. Open [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens).
2. Select `Create Token`.
3. Use the `Edit zone DNS` template or grant:
   - `Zone > DNS > Edit`
   - `Zone > Zone > Read`
4. Select the required zones or `All zones`.
5. Copy the token and keep it private.

> Never share the Cloudflare token, Telegram token, private key, or `/etc/marzban-wildcard-ssl/config`.

## Quick install

Run:

```bash
curl -fsSL https://raw.githubusercontent.com/ExPLoSiVe1988/Marzban-Wildcard-SSL/main/install.sh -o install.sh
sudo bash install.sh
```

The setup asks for:

1. Language
2. Target panel: Marzban, PasarGuard, or both
3. Let's Encrypt account email
4. Cloudflare API Token
5. Base domains
6. Optional Telegram details
7. Final confirmation

### Domain example

For:

```text
example.com
example.net
```

Enter `2`, followed by those two base domains. The certificate will contain:

```text
example.com
*.example.com
example.net
*.example.net
```

Do not enter `https://`, a port, a path, or `*.`.

## Paths

| Purpose | Path |
|---|---|
| Secure project configuration | `/etc/marzban-wildcard-ssl/config` |
| Installed command | `/usr/local/sbin/marzban-wildcard-ssl` |
| Managed full chain | `/var/lib/marzban-wildcard-ssl/fullchain.pem` |
| Managed private key | `/var/lib/marzban-wildcard-ssl/key.pem` |
| Log | `/var/log/marzban-wildcard-ssl.log` |
| Cron definition | `/etc/cron.d/marzban-wildcard-ssl` |
| Log rotation | `/etc/logrotate.d/marzban-wildcard-ssl` |
| Marzban environment | `/opt/marzban/.env` |
| Marzban full chain | `/var/lib/marzban/certs/fullchain.pem` |
| Marzban private key | `/var/lib/marzban/certs/key.pem` |
| PasarGuard environment | `/opt/pasarguard/.env` |
| PasarGuard certificate | `/var/lib/pasarguard/cert.pem` |
| PasarGuard private key | `/var/lib/pasarguard/key.pem` |

The PasarGuard paths match its [official configuration documentation](https://docs.pasarguard.org/en/panel/configuration/).

## Management commands

```bash
sudo marzban-wildcard-ssl --status

sudo marzban-wildcard-ssl --renew

sudo marzban-wildcard-ssl --force-renew

sudo marzban-wildcard-ssl --deploy

sudo marzban-wildcard-ssl --setup

marzban-wildcard-ssl --help
```

## Automatic renewal

At `03:17` each day, the script checks this project's certificate. When `acme.sh` determines that renewal is due, it:

1. Creates temporary Cloudflare DNS validation records.
2. Obtains the new certificate from Let's Encrypt.
3. Installs it in the managed path.
4. Runs the deployment hook for the selected panels.
5. Verifies `.env` and restarts the panels.

Panels are not restarted when the certificate has not changed.

## Upgrade from version 1

Download and run the current installer again:

```bash
curl -fsSL https://raw.githubusercontent.com/ExPLoSiVe1988/Marzban-Wildcard-SSL/main/install.sh -o install.sh
sudo bash install.sh
```

The new version uses a secure, non-interactive configuration file. Re-enter the Cloudflare token during migration.

The installer automatically detects and removes only the version 1 cron entry containing both `/root/install.sh` and `/var/log/ssl_renew.log`. It saves a backup under `/etc/marzban-wildcard-ssl/` and leaves unrelated cron entries unchanged.

## Troubleshooting

### Panel `.env` not found

Install the panel with its official installer first. Expected paths:

```text
/opt/marzban/.env
/opt/pasarguard/.env
```

### Certificate issuance failed

- Confirm that the domain uses Cloudflare nameservers.
- Check the API Token permissions.
- Confirm that the token can access every entered zone.
- Check the server time.
- Read the log:

```bash
sudo tail -n 100 /var/log/marzban-wildcard-ssl.log
```

### The panel does not open after deployment

Check the applicable panel:

```bash
marzban status
marzban logs

pasarguard status
pasarguard logs
```

A timestamped backup is created next to each `.env` file before modification.

## Security

- The configuration contains the Cloudflare API Token and is root-readable only.
- A limited API Token is safer than the Cloudflare Global API Key.
- Private keys are installed with `600` permissions.
- Do not publish complete configuration files or sensitive logs.
- Create a least-privilege token for each server.

## Developer

- GitHub: [@ExPLoSiVe1988](https://github.com/ExPLoSiVe1988)
- Telegram: [@H_ExPLoSiVe](https://t.me/H_ExPLoSiVe)
- Channel: [@Botgineer](https://t.me/Botgineer)

## Support

If this project helps you, please consider starring it on GitHub.

| Cryptocurrency | Address |
|:---|:---|
| Ethereum (ETH - ERC20) | `0x157F3Eb423A241ccefb2Ddc120eF152ce4a736eF` |
| Tron (TRX - TRC20) | `TEdu5VsNNvwjCRJpJJ7zhjXni8Y6W5qAqk` |
| Tether (USDT - BEP20) | `0x78C406B501c4895627CC22F6653AD66163294D60` |

Iranian rial payments are also available through [Reymit](https://reymit.ir/botgineer).
