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

# Paths
KEY_FILE="/var/lib/marzban/certs/key.pem"
FULLCHAIN_FILE="/var/lib/marzban/certs/fullchain.pem"
CERT_DIR="/var/lib/marzban/certs"
MARZBAN_ENV="/opt/marzban/.env"
CF_ENV_FILE="/root/.cf_env"
LOG_FILE="/var/log/ssl_renew.log"

# Create certs directory if it doesn't exist
if [ ! -d "$CERT_DIR" ]; then
  echo "⚙️ Creating directory $CERT_DIR ..."
  sudo mkdir -p "$CERT_DIR"
  sudo chown $(whoami):$(whoami) "$CERT_DIR"
fi

if [ ! -d "$CERT_DIR" ]; then
  echo "❌ Failed to create $CERT_DIR. Please check permissions."
  exit 1
fi

# Install socat if missing
if ! command -v socat &> /dev/null; then
  echo "⚙️ Installing socat ..."
  sudo apt update && sudo apt install -y socat
else
  echo "socat is already installed."
fi

# Cloudflare credentials
read -p "☁️ Cloudflare API Token: " CF_Token
read -p "📧 Cloudflare Email: " CF_Email

# Create Cloudflare config file
echo "CF_Token=\"$CF_Token\"" > "$CF_ENV_FILE"
echo "CF_Email=\"$CF_Email\"" >> "$CF_ENV_FILE"
chmod 600 "$CF_ENV_FILE"
echo "✅ $CF_ENV_FILE created."

# Install acme.sh if not present
if ! command -v acme.sh &> /dev/null; then
  echo "⚙️ Installing acme.sh ..."
  curl https://get.acme.sh | sh
  source "$HOME/.bashrc"
else
  echo "acme.sh is already installed."
fi

# Set CA to Let's Encrypt
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

# Domain input
read -p "🧪 How many domains do you want to request wildcard SSL for? " DOMAIN_COUNT

DOMAINS=()
for (( i=1; i<=DOMAIN_COUNT; i++ )); do
  read -p "🌐 Domain #$i: " domain
  DOMAINS+=("$domain")
done

# Telegram info (optional)
read -p "🤖 Telegram Bot Token (optional): " BOT_TOKEN
read -p "💬 Telegram Chat ID (optional): " CHAT_ID

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

log "🚀 Checking existing cert for $MAIN_DOMAIN"

if [[ ! -f "$FULLCHAIN_FILE" ]]; then
  log "📄 Certificate not found. Starting initial issuance."
  send_telegram "📄 گواهی برای دامنه $MAIN_DOMAIN پیدا نشد. صدور اولیه آغاز شد."
else
  EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$FULLCHAIN_FILE" | cut -d= -f2)
  EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
  CURRENT_TIMESTAMP=$(date +%s)
  REMAINING_DAYS=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))
  log "⏳ $REMAINING_DAYS days until cert expiration."
  if (( REMAINING_DAYS > 30 )); then
    log "✅ Certificate is still valid. No renewal needed."
    exit 0
  fi
  log "🔁 Certificate needs renewal."
fi

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

  ~/.acme.sh/acme.sh --install-cert -d "$MAIN_DOMAIN" \
    --key-file "$KEY_FILE" \
    --fullchain-file "$FULLCHAIN_FILE"

  # Update SSL paths in .env (preserve format and indentation)
if [[ -f "$MARZBAN_ENV" ]]; then
  sed -i 's|^#\?\s*UVICORN_SSL_CERTFILE.*|UVICORN_SSL_CERTFILE = "'"$FULLCHAIN_FILE"'"|' "$MARZBAN_ENV"
  sed -i 's|^#\?\s*UVICORN_SSL_KEYFILE.*|UVICORN_SSL_KEYFILE = "'"$KEY_FILE"'"|' "$MARZBAN_ENV"

  # اگر خطی وجود نداشت، اضافه کن
  grep -q "^UVICORN_SSL_CERTFILE" "$MARZBAN_ENV" || echo "UVICORN_SSL_CERTFILE = \"$FULLCHAIN_FILE\"" >> "$MARZBAN_ENV"
  grep -q "^UVICORN_SSL_KEYFILE" "$MARZBAN_ENV" || echo "UVICORN_SSL_KEYFILE = \"$KEY_FILE\"" >> "$MARZBAN_ENV"

  log "✅ SSL paths updated in $MARZBAN_ENV."
  send_telegram "✅ مسیر فایل‌های SSL در فایل تنظیمات .env بروزرسانی شد."
else
  log "⚠️ $MARZBAN_ENV file not found."
  send_telegram "⚠️ فایل .env مرزبان پیدا نشد."
fi

  # Add Cronjob for auto-renewal
  CRON_JOB="0 3 * * * /root/install.sh >> /var/log/ssl_renew.log 2>&1"
  ( crontab -l 2>/dev/null | grep -v -F "/root/install.sh" ; echo "$CRON_JOB" ) | crontab -
  echo "✅ Cronjob added for automatic renewal."
  send_telegram "🕑 از این به بعد گواهی‌ها هر روز ساعت ۳ صبح به‌ صورت خودکار تمدید می‌شوند به شرطی که مهلت گواهی کمتر از 30 روز باشد."

  # Restart Marzban after everything
  if systemctl is-active --quiet marzban; then
    systemctl restart marzban
    log "🔄 Marzban service restarted via systemctl."
    send_telegram "🔄 سرویس Marzban با موفقیت ریستارت شد."
  elif command -v marzban &> /dev/null; then
    marzban restart
    log "🔄 Marzban restarted using CLI."
    send_telegram "🔄 سرویس Marzban با موفقیت با CLI ریستارت شد."
  else
    log "⚠️ Marzban not found or not running."
    send_telegram "⚠️ سرویس Marzban پیدا نشد یا فعال نیست."
  fi

else
  log "❌ Certificate issue/renewal failed."
  send_telegram "❌ خطا در صدور یا تمدید گواهی دامنه‌ها."
  exit 1
fi
