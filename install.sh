#!/bin/bash

print_header() {
  clear
  echo "############################################################"
  echo "##                                                        ##"
  echo " ##           WELCOME TO Marzban Wildcard SSL Bot        ##"
  echo "  ##             Script Executed Successfully            ##"
  echo " ##         Powered by @H_ExPLoSiVe (ExPLoSiVe1988)      ##"
  echo "##                                                        ##"
  echo "############################################################"
  echo ""
}

print_header

set -e

echo "=== Marzban Wildcard SSL All-in-One Installer ==="

# Fixed certificate file paths
KEY_FILE="/var/lib/marzban/certs/key.pem"
FULLCHAIN_FILE="/var/lib/marzban/certs/fullchain.pem"
MARZBAN_ENV="/opt/marzban/.env"
CF_ENV_FILE="/root/.cf_env"
LOG_FILE="/var/log/ssl_renew.log"

# Install socat if not available
if ! command -v socat &> /dev/null; then
  echo "⚙️ Installing socat ..."
  sudo apt update && sudo apt install -y socat
else
  echo "socat is already installed."
fi

# Get Cloudflare API Token and Email
read -p "☁️ Enter your Cloudflare API Token: " CF_Token
read -p "📧 Enter your Cloudflare Email: " CF_Email

# Create .cf_env file
echo "CF_Token=\"$CF_Token\"" > "$CF_ENV_FILE"
echo "CF_Email=\"$CF_Email\"" >> "$CF_ENV_FILE"
chmod 600 "$CF_ENV_FILE"
echo "✅ Created $CF_ENV_FILE file."

# Install acme.sh if not installed
if ! command -v acme.sh &> /dev/null; then
  echo "⚙️ Installing acme.sh ..."
  curl https://get.acme.sh | sh
  source ~/.bashrc
else
  echo "acme.sh is already installed."
fi

# Set default CA to Let's Encrypt
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

# Get domain count and domains
read -p "🧪 How many domains do you want to get SSL certs for? " DOMAIN_COUNT

DOMAINS=()
for (( i=1; i<=DOMAIN_COUNT; i++ )); do
  read -p "🌐 Domain #$i: " domain
  DOMAINS+=("$domain")
done

# Optional: Telegram bot token and chat ID
read -p "🤖 Telegram bot token (leave blank if not used): " BOT_TOKEN
read -p "💬 Telegram chat ID (leave blank if not used): " CHAT_ID

send_telegram() {
  if [[ -n "$BOT_TOKEN" && -n "$CHAT_ID" ]]; then
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
      -d chat_id="$CHAT_ID" \
      -d text="$1" > /dev/null
  fi
}

log() {
  echo "$(date): $1" | tee -a "$LOG_FILE"
}

MAIN_DOMAIN="${DOMAINS[0]}"

log "🚀 Starting certificate check for $MAIN_DOMAIN"

if [[ ! -f "$FULLCHAIN_FILE" ]]; then
  log "📄 No existing certificate found. Starting initial issuance."
  send_telegram "📄 گواهی برای دامنه $MAIN_DOMAIN پیدا نشد. صدور اولیه آغاز شد."
else
  EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$FULLCHAIN_FILE" | cut -d= -f2)
  EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
  CURRENT_TIMESTAMP=$(date +%s)
  REMAINING_DAYS=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))
  log "⏳ $REMAINING_DAYS days remaining until certificate expiration."
  if (( REMAINING_DAYS > 30 )); then
    log "✅ Certificate is valid. No renewal needed."
    exit 0
  fi
  log "🔁 Certificate needs renewal."
fi

# Load CF credentials
source "$CF_ENV_FILE"
export CF_Token
export CF_Email

ACME_CMD=(~/.acme.sh/acme.sh --issue --force --dns dns_cf)
for d in "${DOMAINS[@]}"; do
  ACME_CMD+=(-d "$d")
done
ACME_CMD+=(--key-file "$KEY_FILE" --fullchain-file "$FULLCHAIN_FILE")

if "${ACME_CMD[@]}"; then
  log "✅ Certificate issue/renewal succeeded."
  send_telegram "✅ گواهی دامنه‌ها با موفقیت صادر یا تمدید شد."

  # Create certs directory if not exists (with sudo)
if ! [ -d "/var/lib/marzban/certs" ]; then
  echo "⚙️ Creating directory /var/lib/marzban/certs ..."
  sudo mkdir -p /var/lib/marzban/certs/
  sudo chown $(whoami):$(whoami) /var/lib/marzban/certs/
fi

  # Install certificate and key
  ~/.acme.sh/acme.sh --install-cert -d "$MAIN_DOMAIN" \
    --key-file "$KEY_FILE" \
    --fullchain-file "$FULLCHAIN_FILE"

  # Update SSL paths in Marzban .env file
  if [[ -f "$MARZBAN_ENV" ]]; then
    # Remove any existing lines (commented or uncommented) for key and cert
    sed -i '/^#\?UVICORN_SSL_KEYFILE=/d' "$MARZBAN_ENV"
    sed -i '/^#\?UVICORN_SSL_CERTFILE=/d' "$MARZBAN_ENV"

    # Add new active lines with updated paths
    echo "UVICORN_SSL_KEYFILE=$KEY_FILE" >> "$MARZBAN_ENV"
    echo "UVICORN_SSL_CERTFILE=$FULLCHAIN_FILE" >> "$MARZBAN_ENV"

    log "✅ SSL file paths updated in $MARZBAN_ENV."
    send_telegram "✅ مسیر فایل‌های SSL در $MARZBAN_ENV با موفقیت بروزرسانی شد."
  else
    log "⚠️ $MARZBAN_ENV file not found, SSL paths not updated."
    send_telegram "⚠️ فایل .env جهت تغییرات یافت نشد."
  fi


  # Restart Marzban service
  if systemctl is-active --quiet marzban; then
    systemctl restart marzban
    log "🔄 Marzban service restarted."
    send_telegram "🔄 سرویس مرزبان با موفقیت ریستارت شد."
  else
    log "⚠️ Marzban service is not active or has a different name."
    send_telegram "⚠️ سرویس Marzban فعال نیست یا نامش متفاوت است."
  fi

else
  log "❌ Certificate issue/renewal failed."
  send_telegram "❌ خطا در صدور یا تمدید گواهی برای دامنه‌ها."
  exit 1
fi

# Set cronjob for auto renewal
CRON_JOB="0 3 * * * /root/install.sh >> /var/log/ssl_renew.log 2>&1"
( crontab -l 2>/dev/null | grep -v -F "/root/install.sh" ; echo "$CRON_JOB" ) | crontab -
echo "✅ Cronjob added for automatic renewal."

echo "🎉 Certificate installation and issuance completed successfully."
echo "🕑 From now on, certificates will auto-renew daily at 3 AM."
    send_telegram "🕑 از این پس گواهی‌ها هر روز ساعت ۳ بامداد به‌صورت خودکار تمدید می‌شوند."
