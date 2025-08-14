<div align="center">

[**English**](./README.md) | [**فارسی (Persian)**](./README-fa.md)

</div>

---

# Marzban-Wildcard-SSL

This project provides a master script for obtaining and automatically renewing Wildcard SSL certificates for multiple domains using `acme.sh` and Cloudflare DNS. It also updates the necessary files for the Marzban project and supports notifications via a Telegram bot.

<div align="center">
  <a href="https://www.youtube.com/watch?v=5-RiZ1qNT90" target="_blank">
    <img src="https://img.youtube.com/vi/5-RiZ1qNT90/hqdefault.jpg" alt="Watch the video tutorial" width="480">
  </a>
  <p><strong>Click the image above to watch the full video tutorial on YouTube</strong></p>
</div>

<div align="center">
  <h3>💖 Show Your Support</h3>
  <p>If this project has been helpful, please give it a star on GitHub to show your appreciation!</p>
  <a href="https://github.com/ExPLoSiVe1988/marzban-wildcard-ssl/stargazers">
    <img src="https://img.shields.io/github/stars/ExPLoSiVe1988/marzban-wildcard-ssl?style=for-the-badge&logo=github&color=FFDD00&logoColor=black" alt="Star the project on GitHub">
  </a>
</div>

## 🚀 Installation and Usage

1.  First, run the installation script:
    ```bash
    bash <(curl -s https://raw.githubusercontent.com/ExPLoSiVe1988/marzban-wildcard-ssl/main/install.sh)
    ```
2.  During execution, enter your Cloudflare API token and email.
3.  The script will then interactively ask for the number of domains, and then for each domain name one by one.
4.  The script will automatically issue/renew the certificates and update the paths in the Marzban configuration file.
5.  Notifications via Telegram (optional) will be sent.
6.  A cronjob will be created for auto-renewal. If a certificate is due to expire in less than 30 days, it will be renewed automatically, and a notification will be sent to your configured Telegram bot.

## ✅ Features

| Feature | Status |
|---|---|
| Install `socat` if not present | ✅ Done |
| Interactively get the number and names of domains | ✅ Done |
| Support for multiple domains for a Wildcard certificate | ✅ Done |
| Send notifications to a Telegram bot (start, success, error, restart) | ✅ Done |
| Create the `/var/lib/marzban/certs` directory if it doesn't exist | ✅ Done |
| Run `acme.sh` with Cloudflare DNS | ✅ Done |
| Install certificates and keys to a custom path | ✅ Done |
| Update (uncomment/replace) `UVICORN_SSL_*` lines in the `.env` file | ✅ Done |
| Check and restart the `marzban` service if active | ✅ Done |
| Create a `cronjob` for automatic certificate renewal | ✅ Done |
| Save logs to `/var/log/ssl_renew.log` | ✅ Done |


### Creating a Cloudflare API Token

| Step | Description |
|:---|:---|
| 1 | Log in to your Cloudflare account: https://dash.cloudflare.com/profile/api-tokens |
| 2 | Click on `Create Token`. |
| 3 | Use the `Edit zone DNS` template or create a custom token with the following permissions: <br> • **Permissions:** Zone > DNS > Edit <br> • **Zone Resources:** Include > All zones or select specific zones. |
| 4 | Copy the generated API Token and store it in a safe place. |

### System Messages

After a successful installation or update, the bot will send the following messages to the Telegram admin:

| Message | When it's sent | Description |
|---|---|---|
| `📄 Certificate for DOMAIN not found. Starting initial issuance.` | When the certificate file at `/var/lib/marzban/certs/fullchain.pem` is not found. | Starts the initial SSL issuance process. |
| `✅ Certificates for the domains were successfully issued or renewed.` | After the `acme.sh --issue ...` command runs successfully. | Success in issuing or renewing the certificate. |
| `🔄 Marzban service has been restarted.` | If the `marzban` service was active and restarted successfully. | SSL operation is complete, and changes are applied. |
| `❌ Error issuing or renewing certificates for the domains.` | If the `acme.sh` command fails to issue or renew the certificate. | A warning message to check for errors. |
| `⚠️ Marzban service is not active or has a different name.` | If `systemctl` cannot verify the status of the `marzban` service. | A warning that the service is invalid or inactive. |

-----

### 👨‍💻 Developer

*   GitHub: [@ExPLoSiVe1988](https://github.com/ExPLoSiVe1988)
*   Telegram: [@H_ExPLoSiVe](https://t.me/H_ExPLoSiVe)
*   Channel: [@Botgineer](https://t.me/Botgineer)

-----

### 💖 Support / Donate

If you find this project useful, please consider supporting me by donating to one of the wallets below:

| Cryptocurrency | Address |
|:---|:---|
| 🟣 **Ethereum (ETH - ERC20)** | `0x157F3Eb423A241ccefb2Ddc120eF152ce4a736eF` |
| 🔵 **Tron (TRX - TRC20)** | `TEdu5VsNNvwjCRJpJJ7zhjXni8Y6W5qAqk` |
| 🟢 **Tether (USDT - TRC20)** | `TN3cg5RM5JLEbnTgK5CU95uLQaukybPhtR` |
