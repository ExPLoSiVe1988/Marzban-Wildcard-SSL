#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

readonly VERSION="2.1.1"
readonly PROJECT_NAME="Marzban & PasarGuard Wildcard SSL"
readonly SCRIPT_SOURCE="${BASH_SOURCE[0]}"

readonly CONFIG_DIR="${WSSL_CONFIG_DIR:-/etc/marzban-wildcard-ssl}"
readonly CONFIG_FILE="${WSSL_CONFIG_FILE:-${CONFIG_DIR}/config}"
readonly DATA_DIR="${WSSL_DATA_DIR:-/var/lib/marzban-wildcard-ssl}"
readonly MASTER_CERT_FILE="${WSSL_MASTER_CERT_FILE:-${DATA_DIR}/fullchain.pem}"
readonly MASTER_KEY_FILE="${WSSL_MASTER_KEY_FILE:-${DATA_DIR}/key.pem}"
readonly INSTALLED_SCRIPT="${WSSL_INSTALLED_SCRIPT:-/usr/local/sbin/marzban-wildcard-ssl}"
readonly CRON_FILE="${WSSL_CRON_FILE:-/etc/cron.d/marzban-wildcard-ssl}"
readonly LOGROTATE_FILE="${WSSL_LOGROTATE_FILE:-/etc/logrotate.d/marzban-wildcard-ssl}"
readonly LOG_FILE="${WSSL_LOG_FILE:-/var/log/marzban-wildcard-ssl.log}"
readonly LOCK_FILE="${WSSL_LOCK_FILE:-/run/lock/marzban-wildcard-ssl.lock}"
readonly ACME_HOME="${WSSL_ACME_HOME:-/root/.acme.sh}"
readonly ACME_BIN="${WSSL_ACME_BIN:-${ACME_HOME}/acme.sh}"

readonly MARZBAN_ENV="${WSSL_MARZBAN_ENV:-/opt/marzban/.env}"
readonly MARZBAN_CERT="${WSSL_MARZBAN_CERT:-/var/lib/marzban/certs/fullchain.pem}"
readonly MARZBAN_KEY="${WSSL_MARZBAN_KEY:-/var/lib/marzban/certs/key.pem}"
readonly PASARGUARD_ENV="${WSSL_PASARGUARD_ENV:-/opt/pasarguard/.env}"
readonly PASARGUARD_CERT="${WSSL_PASARGUARD_CERT:-/var/lib/pasarguard/cert.pem}"
readonly PASARGUARD_KEY="${WSSL_PASARGUARD_KEY:-/var/lib/pasarguard/key.pem}"

LANGUAGE="${WSSL_LANGUAGE:-fa}"
PANEL_SELECTION=""
ACME_EMAIL=""
CF_TOKEN=""
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
DOMAINS=()

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  readonly C_RESET=$'\033[0m'
  readonly C_BOLD=$'\033[1m'
  readonly C_DIM=$'\033[2m'
  readonly C_BLUE=$'\033[1;34m'
  readonly C_CYAN=$'\033[1;36m'
  readonly C_GREEN=$'\033[1;32m'
  readonly C_YELLOW=$'\033[1;33m'
  readonly C_RED=$'\033[1;31m'
else
  readonly C_RESET=""
  readonly C_BOLD=""
  readonly C_DIM=""
  readonly C_BLUE=""
  readonly C_CYAN=""
  readonly C_GREEN=""
  readonly C_YELLOW=""
  readonly C_RED=""
fi

tr_text() {
  local key="$1"
  local fa=""
  local en=""

  case "$key" in
    need_root)
      fa="این دستور باید با کاربر root اجرا شود."
      en="This command must be run as root."
      ;;
    info_label)
      fa="اطلاع"
      en="INFO"
      ;;
    ok_label)
      fa="موفق"
      en="OK"
      ;;
    warn_label)
      fa="هشدار"
      en="WARN"
      ;;
    error_label)
      fa="خطا"
      en="ERROR"
      ;;
    unsupported_os)
      fa="نصب خودکار پیش‌نیازها فقط در Debian/Ubuntu پشتیبانی می‌شود."
      en="Automatic dependency installation is supported only on Debian/Ubuntu."
      ;;
    dependency_install)
      fa="در حال نصب پیش‌نیازهای لازم..."
      en="Installing required dependencies..."
      ;;
    acme_install)
      fa="در حال نصب acme.sh..."
      en="Installing acme.sh..."
      ;;
    cert_request)
      fa="در حال بررسی یا صدور گواهی از Let's Encrypt؛ این مرحله ممکن است چند دقیقه طول بکشد..."
      en="Checking or issuing the Let's Encrypt certificate; this may take a few minutes..."
      ;;
    cert_ready)
      fa="گواهی معتبر با موفقیت آماده شد."
      en="A valid certificate is ready."
      ;;
    cert_unchanged)
      fa="گواهی هنوز معتبر است و تغییری نکرد؛ نیازی به ری‌استارت پنل نیست."
      en="The certificate is still valid and unchanged; no panel restart is needed."
      ;;
    config_updated)
      fa="مسیرهای SSL در فایل تنظیمات %s به‌روزرسانی شد."
      en="SSL paths were updated in %s."
      ;;
    panel_restarted)
      fa="پنل %s با موفقیت ری‌استارت شد."
      en="%s was restarted successfully."
      ;;
    restart_failed)
      fa="گواهی نصب شد، اما ری‌استارت %s ناموفق بود. لاگ پنل را بررسی کنید."
      en="The certificate was installed, but %s could not be restarted. Check the panel logs."
      ;;
    cron_installed)
      fa="تمدید خودکار روزانه نصب شد."
      en="The daily automatic renewal job was installed."
      ;;
    setup_complete)
      fa="راه‌اندازی کامل شد. از این پس تمدید گواهی بدون نیاز به ورود اطلاعات انجام می‌شود."
      en="Setup is complete. Future renewals will run without interactive input."
      ;;
    telegram_send_failed)
      fa="ارسال اعلان تلگرام ناموفق بود."
      en="The Telegram notification could not be sent."
      ;;
    another_operation)
      fa="یک عملیات دیگر مربوط به گواهی در حال اجرا است."
      en="Another certificate operation is already running."
      ;;
    cron_start_failed)
      fa="cron نصب شد، اما اجرای خودکار سرویس آن ناموفق بود."
      en="cron was installed, but its service could not be started automatically."
      ;;
    acme_download_failed)
      fa="دانلود acme.sh ناموفق بود. اتصال اینترنت سرور را بررسی کنید."
      en="Could not download acme.sh. Check the server internet connection."
      ;;
    acme_install_failed)
      fa="نصب acme.sh ناموفق بود."
      en="acme.sh installation failed."
      ;;
    detected)
      fa="شناسایی شد"
      en="detected"
      ;;
    not_detected)
      fa="شناسایی نشد"
      en="not detected"
      ;;
    panel_question)
      fa="گواهی برای کدام پنل نصب شود؟"
      en="Which panel should use this certificate?"
      ;;
    both)
      fa="هر دو"
      en="Both"
      ;;
    choice_prompt)
      fa="انتخاب"
      en="Choice"
      ;;
    invalid_panel_choice)
      fa="لطفاً یکی از گزینه‌های ۱، ۲ یا ۳ را انتخاب کنید."
      en="Please select option 1, 2, or 3."
      ;;
    invalid_email)
      fa="آدرس ایمیل معتبر نیست."
      en="The email address is not valid."
      ;;
    cloudflare_token_prompt)
      fa="توکن API کلادفلر (هنگام تایپ نمایش داده نمی‌شود)"
      en="Cloudflare API Token (input is hidden)"
      ;;
    token_too_short)
      fa="توکن واردشده بیش از حد کوتاه است."
      en="The token is too short."
      ;;
    domains_intro)
      fa="فقط دامنه پایه را وارد کنید؛ برای مثال: example.com"
      en="Enter base domains only; for example: example.com"
      ;;
    domains_wildcard_note)
      fa="اسکریپت به‌صورت خودکار example.com و *.example.com را به گواهی اضافه می‌کند."
      en="The script automatically adds both example.com and *.example.com to the certificate."
      ;;
    domain_count_prompt)
      fa="تعداد دامنه‌های پایه"
      en="Number of base domains"
      ;;
    invalid_domain_count)
      fa="عددی بین ۱ تا ۵۰ وارد کنید."
      en="Enter a number from 1 to 50."
      ;;
    duplicate_domain)
      fa="این دامنه قبلاً وارد شده است."
      en="This domain was already entered."
      ;;
    telegram_enable_prompt)
      fa="اعلان تلگرام فعال شود؟ (اختیاری) [y/N]"
      en="Enable optional Telegram notifications? [y/N]"
      ;;
    telegram_token_prompt)
      fa="توکن ربات تلگرام (هنگام تایپ نمایش داده نمی‌شود)"
      en="Telegram Bot Token (input is hidden)"
      ;;
    invalid_telegram_token)
      fa="توکن ربات تلگرام معتبر نیست."
      en="The Telegram Bot Token is not valid."
      ;;
    telegram_chat_prompt)
      fa="شناسه چت تلگرام"
      en="Telegram Chat ID"
      ;;
    invalid_telegram_chat)
      fa="شناسه چت تلگرام معتبر نیست."
      en="The Telegram Chat ID is not valid."
      ;;
    review_title)
      fa="خلاصه تنظیمات را بررسی کنید"
      en="Review the selected settings"
      ;;
    panels_label)
      fa="پنل‌ها"
      en="Panel(s)"
      ;;
    domains_label)
      fa="دامنه‌ها"
      en="Domains"
      ;;
    email_label)
      fa="ایمیل"
      en="Email"
      ;;
    telegram_label)
      fa="تلگرام"
      en="Telegram"
      ;;
    enabled)
      fa="فعال"
      en="enabled"
      ;;
    disabled)
      fa="غیرفعال"
      en="disabled"
      ;;
    installed)
      fa="نصب شده"
      en="installed"
      ;;
    not_installed)
      fa="نصب نشده"
      en="not installed"
      ;;
    continue_prompt)
      fa="ادامه داده شود؟ [Y/n]"
      en="Continue? [Y/n]"
      ;;
    cancelled)
      fa="عملیات توسط کاربر لغو شد."
      en="The operation was cancelled by the user."
      ;;
    config_damaged)
      fa="فایل تنظیمات پشتیبانی نمی‌شود یا آسیب دیده است."
      en="The configuration file is unsupported or damaged."
      ;;
    config_incomplete)
      fa="فایل تنظیمات کامل نیست."
      en="The configuration file is incomplete."
      ;;
    self_copy_failed)
      fa="کپی‌کردن اسکریپت برای تمدید خودکار ناموفق بود."
      en="The running script could not be copied for automatic renewal."
      ;;
    cert_pair_missing)
      fa="هیچ جفت گواهی و کلید معتبری برای نصب وجود ندارد."
      en="No valid certificate and key pair is available to deploy."
      ;;
    cert_domains_missing)
      fa="گواهی شامل همه دامنه‌های پایه و Wildcard تنظیم‌شده نیست."
      en="The certificate does not contain every configured base and wildcard domain."
      ;;
    cert_invalid)
      fa="گواهی و کلید خصوصی دانلودشده معتبر یا منطبق نیستند."
      en="The downloaded certificate and private key are invalid or do not match."
      ;;
    cert_read_failed)
      fa="خواندن گواهی نصب‌شده ناموفق بود."
      en="Could not read the installed certificate."
      ;;
    acme_deploy_failed)
      fa="acme.sh نتوانست گواهی را نصب یا اعمال کند."
      en="acme.sh could not install or deploy the certificate."
      ;;
    acme_missing)
      fa="فایل اجرایی acme.sh پیدا نشد."
      en="The acme.sh executable was not found."
      ;;
    forced_renew_failed)
      fa="تمدید اجباری گواهی ناموفق بود."
      en="Forced certificate renewal failed."
      ;;
    certificate_label)
      fa="گواهی"
      en="Certificate"
      ;;
    renewal_label)
      fa="تمدید خودکار"
      en="Automatic renewal"
      ;;
    backup_label)
      fa="نسخه پشتیبان"
      en="Backup"
      ;;
    section_panels)
      fa="انتخاب پنل"
      en="Panel selection"
      ;;
    section_account)
      fa="حساب Let's Encrypt و کلادفلر"
      en="Let's Encrypt and Cloudflare"
      ;;
    section_domains)
      fa="تنظیم دامنه‌ها"
      en="Domain configuration"
      ;;
    section_notifications)
      fa="اعلان‌های تلگرام"
      en="Telegram notifications"
      ;;
    section_review)
      fa="تأیید نهایی"
      en="Final confirmation"
      ;;
    section_processing)
      fa="شروع عملیات"
      en="Processing"
      ;;
    section_status)
      fa="وضعیت گواهی"
      en="Certificate status"
      ;;
    header_subtitle)
      fa="مدیریت گواهی Marzban و PasarGuard"
      en="Marzban and PasarGuard Certificate Manager"
      ;;
    invalid_language)
      fa="گزینه نامعتبر بود؛ زبان فارسی انتخاب شد."
      en="Invalid choice; Persian was selected."
      ;;
    *)
      fa="$key"
      en="$key"
      ;;
  esac

  if [[ "$LANGUAGE" == "en" ]]; then
    printf '%s' "$en"
  else
    printf '%s' "$fa"
  fi
}

tr_format() {
  local key="$1"
  shift

  case "${LANGUAGE}:${key}" in
    en:fatal) printf 'Operation stopped: %s' "$1" ;;
    fa:fatal) printf 'عملیات متوقف شد: %s' "$1" ;;
    en:unexpected_error) printf 'Unexpected error on line %s (exit code %s).' "$1" "$2" ;;
    fa:unexpected_error) printf 'خطای پیش‌بینی‌نشده در خط %s (کد خروج %s).' "$1" "$2" ;;
    en:missing_panel) printf '%s configuration file was not found: %s' "$1" "$2" ;;
    fa:missing_panel) printf 'فایل تنظیمات %s پیدا نشد: %s' "$1" "$2" ;;
    en:invalid_domain) printf "'%s' is not valid. Enter only a base domain such as example.com." "$1" ;;
    fa:invalid_domain) printf 'دامنه «%s» معتبر نیست. فقط دامنه پایه مثل example.com را وارد کنید.' "$1" ;;
    en:panel_restarted) printf '%s was restarted successfully.' "$1" ;;
    fa:panel_restarted) printf 'پنل %s با موفقیت ری‌استارت شد.' "$1" ;;
    en:restart_failed) printf 'The certificate was installed, but %s could not be restarted. Check the panel logs.' "$1" ;;
    fa:restart_failed) printf 'گواهی نصب شد، اما ری‌استارت %s ناموفق بود. لاگ پنل را بررسی کنید.' "$1" ;;
    en:config_updated) printf 'SSL paths were updated in %s.' "$1" ;;
    fa:config_updated) printf 'مسیرهای SSL در فایل تنظیمات %s به‌روزرسانی شد.' "$1" ;;
    en:missing_packages) printf '%s Missing packages: %s' "$(tr_text unsupported_os)" "$1" ;;
    fa:missing_packages) printf '%s بسته‌های زیر موجود نیستند: %s' "$(tr_text unsupported_os)" "$1" ;;
    en:unknown_panel) printf 'Unknown panel in configuration: %s' "$1" ;;
    fa:unknown_panel) printf 'پنل ناشناخته در تنظیمات: %s' "$1" ;;
    en:domain_prompt) printf 'Base domain #%s' "$1" ;;
    fa:domain_prompt) printf 'دامنه پایه شماره %s' "$1" ;;
    en:invalid_newline) printf 'Invalid newline in %s.' "$1" ;;
    fa:invalid_newline) printf 'مقدار %s شامل خط جدید نامعتبر است.' "$1" ;;
    en:config_not_found) printf 'Configuration was not found: %s. Run interactive setup first.' "$1" ;;
    fa:config_not_found) printf 'فایل تنظیمات پیدا نشد: %s. ابتدا راه‌اندازی تعاملی را اجرا کنید.' "$1" ;;
    en:invalid_domain_config) printf 'Invalid domain in configuration: %s' "$1" ;;
    fa:invalid_domain_config) printf 'دامنه نامعتبر در فایل تنظیمات: %s' "$1" ;;
    en:legacy_removed) printf 'The old interactive cron entry was removed. Backup: %s' "$1" ;;
    fa:legacy_removed) printf 'وظیفه cron قدیمی حذف شد. نسخه پشتیبان: %s' "$1" ;;
    en:acme_issue_failed) printf 'acme.sh failed with exit code %s. Review %s and the output above.' "$1" "$2" ;;
    fa:acme_issue_failed) printf 'اجرای acme.sh با کد %s ناموفق بود. فایل %s و خروجی بالا را بررسی کنید.' "$1" "$2" ;;
    en:backup_path) printf '%s: %s' "$(tr_text backup_label)" "$1" ;;
    fa:backup_path) printf '%s: %s' "$(tr_text backup_label)" "$1" ;;
    en:deploy_failures) printf '%s panel deployment or restart operation(s) need attention.' "$1" ;;
    fa:deploy_failures) printf '%s عملیات نصب یا ری‌استارت پنل نیاز به بررسی دارد.' "$1" ;;
    en:certificate_path) printf '%s: %s' "$(tr_text certificate_label)" "$1" ;;
    fa:certificate_path) printf '%s: %s' "$(tr_text certificate_label)" "$1" ;;
    en:renew_failed) printf 'acme.sh renewal failed with exit code %s.' "$1" ;;
    fa:renew_failed) printf 'تمدید گواهی توسط acme.sh با کد %s ناموفق بود.' "$1" ;;
    en:unknown_option) printf 'Unknown option: %s' "$1" ;;
    fa:unknown_option) printf 'گزینه ناشناخته: %s' "$1" ;;
    en:telegram_setup_complete) printf 'Certificate setup completed for %s.' "$1" ;;
    fa:telegram_setup_complete) printf 'راه‌اندازی گواهی برای %s کامل شد.' "$1" ;;
    *) printf '%s' "$key" ;;
  esac
}

write_log() {
  local level="$1"
  shift
  local message="$*"
  local log_dir
  log_dir="$(dirname "$LOG_FILE")"

  if [[ ${EUID:-$(id -u)} -eq 0 && "${WSSL_CRON_RUN:-0}" != "1" ]]; then
    mkdir -p "$log_dir" 2>/dev/null || true
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$message" >> "$LOG_FILE" 2>/dev/null || true
  fi
}

info() {
  printf '%s[%s]%s %s\n' "$C_BLUE" "$(tr_text info_label)" "$C_RESET" "$*"
  write_log "INFO" "$*"
}

success() {
  printf '%s[%s]%s %s\n' "$C_GREEN" "$(tr_text ok_label)" "$C_RESET" "$*"
  write_log "OK" "$*"
}

warn() {
  printf '%s[%s]%s %s\n' "$C_YELLOW" "$(tr_text warn_label)" "$C_RESET" "$*" >&2
  write_log "WARN" "$*"
}

error() {
  printf '%s[%s]%s %s\n' "$C_RED" "$(tr_text error_label)" "$C_RESET" "$*" >&2
  write_log "ERROR" "$*"
}

send_telegram() {
  local message="$1"
  local api_url=""

  [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]] || return 0
  command -v curl >/dev/null 2>&1 || return 0
  api_url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"

  printf 'url = "%s"\n' "$api_url" |
    curl --config - --silent --show-error --fail \
      --connect-timeout 10 --max-time 20 \
      --request POST \
      --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
      --data-urlencode "text=${message}" >/dev/null 2>&1 || {
      warn "$(tr_text telegram_send_failed)"
      return 0
    }
}

die() {
  local message="$*"
  error "$(tr_format fatal "$message")"
  send_telegram "❌ ${PROJECT_NAME}: ${message}"
  exit 1
}

on_unexpected_error() {
  local rc="$1"
  local line="$2"
  trap - ERR
  set +e
  error "$(tr_format unexpected_error "$line" "$rc")"
  send_telegram "❌ ${PROJECT_NAME}: $(tr_format unexpected_error "$line" "$rc")"
  exit "$rc"
}

clear_screen() {
  if [[ -t 1 && "${TERM:-dumb}" != "dumb" && -z "${NO_CLEAR:-}" ]]; then
    printf '\033[2J\033[H'
  fi
}

print_language_screen() {
  printf '%s\n' "$C_BLUE"
  printf '  ╔════════════════════════════════════════════════════════════╗\n'
  printf '  ║                    WILDCARD SSL                            ║\n'
  printf '  ║              Marzban + PasarGuard                         ║\n'
  printf '  ╚════════════════════════════════════════════════════════════╝\n'
  printf '%s\n' "$C_RESET"
}

print_section() {
  local step="$1"
  local total="$2"
  local title="$3"
  local counter=""

  if [[ -n "$step" && -n "$total" ]]; then
    counter="[${step}/${total}] "
  fi
  printf '\n%s╭─ %s%s%s\n' "$C_CYAN" "$counter" "$title" "$C_RESET"
  printf '%s╰──────────────────────────────────────────────────────────────%s\n' "$C_DIM" "$C_RESET"
}

print_header() {
  printf '\n%s' "$C_BLUE"
  if ((${COLUMNS:-80} >= 72)); then
    cat <<'EOF'
██╗    ██╗██╗██╗     ██████╗  ██████╗ █████╗ ██████╗ ██████╗
██║    ██║██║██║     ██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗
██║ █╗ ██║██║██║     ██║  ██║██║     ███████║██████╔╝██║  ██║
██║███╗██║██║██║     ██║  ██║██║     ██╔══██║██╔══██╗██║  ██║
╚███╔███╔╝██║███████╗██████╔╝╚██████╗██║  ██║██║  ██║██████╔╝
 ╚══╝╚══╝ ╚═╝╚══════╝╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝

               ███████╗███████╗██╗
               ██╔════╝██╔════╝██║
               ███████╗███████╗██║
               ╚════██║╚════██║██║
               ███████║███████║███████╗
               ╚══════╝╚══════╝╚══════╝
EOF
  else
    printf '  WILDCARD SSL\n'
  fi
  printf '%s' "$C_RESET"
  printf '        %s%s%s\n' "$C_BOLD" "$(tr_text header_subtitle)" "$C_RESET"
  printf '        Cloudflare DNS • Let'\''s Encrypt • acme.sh • v%s\n' "$VERSION"
  printf '        Powered by @H_ExPLoSiVe (ExPLoSiVe1988)\n'
  printf '        GitHub: github.com/ExPLoSiVe1988 • Channel: @Botgineer\n'
  printf '%s%s%s\n' "$C_DIM" '──────────────────────────────────────────────────────────────────────' "$C_RESET"
}

print_help() {
  if [[ "$LANGUAGE" == "fa" ]]; then
    cat <<'EOF'
Marzban & PasarGuard Wildcard SSL

روش استفاده:
  sudo bash install.sh                 راه‌اندازی یا تنظیم مجدد
  sudo marzban-wildcard-ssl --renew    بررسی تمدید گواهی
  sudo marzban-wildcard-ssl --deploy   نصب مجدد گواهی فعلی
  sudo marzban-wildcard-ssl --status   نمایش تنظیمات و وضعیت گواهی
  marzban-wildcard-ssl --help          نمایش راهنما

راه‌اندازی تعاملی:
  1. پنل‌های Marzban و PasarGuard را شناسایی می‌کند.
  2. دامنه‌های پایه مانند example.com را دریافت می‌کند.
  3. دامنه پایه و Wildcard آن را به گواهی اضافه می‌کند.
  4. گواهی را با اعتبارسنجی DNS کلادفلر صادر می‌کند.
  5. پنل‌های انتخاب‌شده و تمدید خودکار را تنظیم می‌کند.

تنظیمات: /etc/marzban-wildcard-ssl/config
لاگ:     /var/log/marzban-wildcard-ssl.log
EOF
  else
    cat <<'EOF'
Marzban & PasarGuard Wildcard SSL

Usage:
  sudo bash install.sh              Interactive setup or reconfiguration
  sudo marzban-wildcard-ssl --renew Run a non-interactive renewal check
  sudo marzban-wildcard-ssl --deploy Re-deploy the current certificate
  sudo marzban-wildcard-ssl --status Show configuration and certificate status
  marzban-wildcard-ssl --help       Show this help

The interactive setup:
  1. Detects Marzban and PasarGuard.
  2. Requests base domains such as example.com.
  3. Automatically includes both example.com and *.example.com.
  4. Issues one certificate with Cloudflare DNS validation.
  5. Updates the selected panel(s) and installs automatic renewal.

Configuration: /etc/marzban-wildcard-ssl/config
Log:           /var/log/marzban-wildcard-ssl.log
EOF
  fi
}

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    error "$(tr_text need_root)"
    printf 'sudo bash %q\n' "$SCRIPT_SOURCE" >&2
    exit 1
  fi
}

acquire_lock() {
  mkdir -p "$(dirname "$LOCK_FILE")"

  if command -v flock >/dev/null 2>&1; then
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
      die "$(tr_text another_operation)"
    fi
  fi
}

choose_language() {
  local choice=""

  printf '%sSelect language / زبان را انتخاب کنید%s\n\n' "$C_BOLD" "$C_RESET"
  printf '    1) فارسی\n'
  printf '    2) English\n\n'
  read -r -p 'Choice / انتخاب [1]: ' choice

  case "${choice:-1}" in
    1) LANGUAGE="fa" ;;
    2) LANGUAGE="en" ;;
    *)
      LANGUAGE="fa"
      warn "$(tr_text invalid_language)"
      ;;
  esac
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

ensure_dependencies() {
  local packages=()

  command_exists curl || packages+=("curl")
  command_exists openssl || packages+=("openssl")
  command_exists crontab || packages+=("cron")

  if ((${#packages[@]} == 0)); then
    return 0
  fi

  if ! command_exists apt-get; then
    die "$(tr_format missing_packages "${packages[*]}")"
  fi

  info "$(tr_text dependency_install)"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y ca-certificates "${packages[@]}"

  if [[ " ${packages[*]} " == *" cron "* ]] && command_exists systemctl; then
    systemctl enable --now cron >/dev/null 2>&1 || warn "$(tr_text cron_start_failed)"
  fi
}

install_acme() {
  local installer=""

  if [[ -x "$ACME_BIN" ]]; then
    return 0
  fi

  info "$(tr_text acme_install)"
  installer="$(mktemp)"
  if ! curl --fail --silent --show-error --location https://get.acme.sh -o "$installer"; then
    rm -f "$installer"
    die "$(tr_text acme_download_failed)"
  fi

  sh "$installer" "email=${ACME_EMAIL}" --home "$ACME_HOME" --nocron
  rm -f "$installer"

  [[ -x "$ACME_BIN" ]] || die "$(tr_text acme_install_failed)"
  "$ACME_BIN" --set-default-ca --server letsencrypt
  "$ACME_BIN" --register-account --server letsencrypt -m "$ACME_EMAIL" >/dev/null 2>&1 || true
}

normalize_domain() {
  local domain="$1"

  domain="${domain,,}"
  domain="${domain//$'\r'/}"
  domain="${domain//$'\n'/}"
  domain="${domain#http://}"
  domain="${domain#https://}"
  domain="${domain%%/*}"
  domain="${domain%%:*}"
  domain="${domain#\*.}"
  domain="${domain%.}"

  printf '%s' "$domain"
}

is_valid_domain() {
  local domain="$1"

  ((${#domain} <= 253)) || return 1
  [[ "$domain" == *.* ]] || return 1
  [[ "$domain" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+$ ]]
}

is_valid_email() {
  local email="$1"
  [[ "$email" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]
}

array_contains() {
  local needle="$1"
  shift
  local item=""

  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

detect_panel() {
  local panel="$1"

  case "$panel" in
    marzban)
      [[ -f "$MARZBAN_ENV" ]] || command_exists marzban
      ;;
    pasarguard)
      [[ -f "$PASARGUARD_ENV" ]] || command_exists pasarguard
      ;;
    *)
      return 1
      ;;
  esac
}

panel_detection_label() {
  local panel="$1"

  if detect_panel "$panel"; then
    tr_text detected
  else
    tr_text not_detected
  fi
}

panel_selection_label() {
  case "$PANEL_SELECTION" in
    marzban) printf 'Marzban' ;;
    pasarguard) printf 'PasarGuard' ;;
    marzban,pasarguard) printf 'Marzban + PasarGuard' ;;
    *) printf '%s' "$PANEL_SELECTION" ;;
  esac
}

choose_panels() {
  local choice=""
  local default_choice="1"
  local has_marzban=0
  local has_pasarguard=0

  detect_panel marzban && has_marzban=1
  detect_panel pasarguard && has_pasarguard=1

  if ((has_marzban == 1 && has_pasarguard == 1)); then
    default_choice="3"
  elif ((has_pasarguard == 1)); then
    default_choice="2"
  fi

  printf '%s\n\n' "$(tr_text panel_question)"
  printf '    1) Marzban (%s)\n' "$(panel_detection_label marzban)"
  printf '    2) PasarGuard (%s)\n' "$(panel_detection_label pasarguard)"
  printf '    3) %s\n\n' "$(tr_text both)"

  while true; do
    read -r -p "$(tr_text choice_prompt) [${default_choice}]: " choice
    choice="${choice:-$default_choice}"
    case "$choice" in
      1) PANEL_SELECTION="marzban"; break ;;
      2) PANEL_SELECTION="pasarguard"; break ;;
      3) PANEL_SELECTION="marzban,pasarguard"; break ;;
      *) warn "$(tr_text invalid_panel_choice)" ;;
    esac
  done

  validate_selected_panels
}

validate_selected_panels() {
  local panel=""
  local selected=()
  IFS=',' read -r -a selected <<< "$PANEL_SELECTION"

  for panel in "${selected[@]}"; do
    case "$panel" in
      marzban)
        [[ -f "$MARZBAN_ENV" ]] || die "$(tr_format missing_panel "Marzban" "$MARZBAN_ENV")"
        ;;
      pasarguard)
        [[ -f "$PASARGUARD_ENV" ]] || die "$(tr_format missing_panel "PasarGuard" "$PASARGUARD_ENV")"
        ;;
      *)
        die "$(tr_format unknown_panel "$panel")"
        ;;
    esac
  done
}

prompt_email() {
  while true; do
    if [[ "$LANGUAGE" == "en" ]]; then
      read -r -p "Email for the Let's Encrypt account: " ACME_EMAIL
    else
      read -r -p "ایمیل برای حساب Let's Encrypt: " ACME_EMAIL
    fi

    is_valid_email "$ACME_EMAIL" && break
    warn "$(tr_text invalid_email)"
  done
}

prompt_cloudflare_token() {
  while true; do
    printf '%s: ' "$(tr_text cloudflare_token_prompt)"
    IFS= read -r -s CF_TOKEN
    printf '\n'
    CF_TOKEN="${CF_TOKEN//$'\r'/}"
    CF_TOKEN="${CF_TOKEN//$'\n'/}"

    if [[ ${#CF_TOKEN} -ge 20 ]]; then
      break
    fi
    warn "$(tr_text token_too_short)"
  done
}

prompt_domains() {
  local count=""
  local index=0
  local raw_domain=""
  local domain=""

  printf '%s\n' "$(tr_text domains_intro)"
  printf '%s%s%s\n\n' "$C_DIM" "$(tr_text domains_wildcard_note)" "$C_RESET"

  while true; do
    read -r -p "$(tr_text domain_count_prompt) [1]: " count
    count="${count:-1}"
    if [[ "$count" =~ ^[0-9]+$ ]] && ((count >= 1 && count <= 50)); then
      break
    fi
    warn "$(tr_text invalid_domain_count)"
  done

  DOMAINS=()
  for ((index = 1; index <= count; index++)); do
    while true; do
      read -r -p "$(tr_format domain_prompt "$index"): " raw_domain
      domain="$(normalize_domain "$raw_domain")"

      if ! is_valid_domain "$domain"; then
        warn "$(tr_format invalid_domain "$raw_domain")"
        continue
      fi
      if array_contains "$domain" "${DOMAINS[@]}"; then
        warn "$(tr_text duplicate_domain)"
        continue
      fi

      DOMAINS+=("$domain")
      break
    done
  done
}

prompt_telegram() {
  local choice=""

  read -r -p "$(tr_text telegram_enable_prompt): " choice

  case "${choice,,}" in
    y|yes|ب|بله)
      while true; do
        printf '%s: ' "$(tr_text telegram_token_prompt)"
        IFS= read -r -s TELEGRAM_BOT_TOKEN
        printf '\n'
        if [[ "$TELEGRAM_BOT_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
          break
        fi
        warn "$(tr_text invalid_telegram_token)"
      done
      while true; do
        read -r -p "$(tr_text telegram_chat_prompt): " TELEGRAM_CHAT_ID
        if [[ "$TELEGRAM_CHAT_ID" =~ ^-?[0-9]+$ ]]; then
          break
        fi
        warn "$(tr_text invalid_telegram_chat)"
      done
      ;;
    *)
      TELEGRAM_BOT_TOKEN=""
      TELEGRAM_CHAT_ID=""
      ;;
  esac
}

confirm_setup() {
  local choice=""
  local domain=""
  local telegram_status=""

  if [[ -n "$TELEGRAM_BOT_TOKEN" ]]; then
    telegram_status="$(tr_text enabled)"
  else
    telegram_status="$(tr_text disabled)"
  fi

  printf '%s%s%s\n\n' "$C_BOLD" "$(tr_text review_title)" "$C_RESET"
  printf '  %s: %s\n' "$(tr_text panels_label)" "$(panel_selection_label)"
  printf '  %s:\n' "$(tr_text domains_label)"
  for domain in "${DOMAINS[@]}"; do
    printf '    • %s  +  *.%s\n' "$domain" "$domain"
  done
  printf '  %s: %s\n' "$(tr_text email_label)" "$ACME_EMAIL"
  printf '  %s: %s\n\n' "$(tr_text telegram_label)" "$telegram_status"

  read -r -p "$(tr_text continue_prompt): " choice
  case "${choice,,}" in
    n|no|خیر)
      die "$(tr_text cancelled)"
      ;;
  esac
}

validate_config_value() {
  local name="$1"
  local value="$2"
  [[ "$value" != *$'\n'* && "$value" != *$'\r'* ]] || die "$(tr_format invalid_newline "$name")"
}

write_config() {
  local tmp=""
  local domain_csv=""
  local old_backup=""

  domain_csv="$(IFS=','; printf '%s' "${DOMAINS[*]}")"
  validate_config_value "PANEL_SELECTION" "$PANEL_SELECTION"
  validate_config_value "ACME_EMAIL" "$ACME_EMAIL"
  validate_config_value "CF_TOKEN" "$CF_TOKEN"
  validate_config_value "TELEGRAM_BOT_TOKEN" "$TELEGRAM_BOT_TOKEN"
  validate_config_value "TELEGRAM_CHAT_ID" "$TELEGRAM_CHAT_ID"
  validate_config_value "DOMAINS" "$domain_csv"

  mkdir -p "$CONFIG_DIR"
  chmod 700 "$CONFIG_DIR"

  if [[ -f "$CONFIG_FILE" ]]; then
    old_backup="${CONFIG_FILE}.backup.$(date '+%Y%m%d-%H%M%S')"
    cp -a "$CONFIG_FILE" "$old_backup"
  fi

  tmp="$(mktemp "${CONFIG_DIR}/config.tmp.XXXXXX")"
  {
    printf '# Managed by %s v%s. Do not share this file.\n' "$PROJECT_NAME" "$VERSION"
    printf 'CONFIG_VERSION=2\n'
    printf 'LANGUAGE=%s\n' "$LANGUAGE"
    printf 'PANEL_SELECTION=%s\n' "$PANEL_SELECTION"
    printf 'ACME_EMAIL=%s\n' "$ACME_EMAIL"
    printf 'CF_TOKEN=%s\n' "$CF_TOKEN"
    printf 'DOMAINS=%s\n' "$domain_csv"
    printf 'TELEGRAM_BOT_TOKEN=%s\n' "$TELEGRAM_BOT_TOKEN"
    printf 'TELEGRAM_CHAT_ID=%s\n' "$TELEGRAM_CHAT_ID"
  } > "$tmp"
  chmod 600 "$tmp"
  mv -f "$tmp" "$CONFIG_FILE"
}

load_config() {
  local key=""
  local value=""
  local config_version=""
  local domain_csv=""

  [[ -f "$CONFIG_FILE" ]] || die "$(tr_format config_not_found "$CONFIG_FILE")"

  LANGUAGE="fa"
  PANEL_SELECTION=""
  ACME_EMAIL=""
  CF_TOKEN=""
  TELEGRAM_BOT_TOKEN=""
  TELEGRAM_CHAT_ID=""
  DOMAINS=()

  while IFS='=' read -r key value || [[ -n "$key" ]]; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    case "$key" in
      CONFIG_VERSION) config_version="$value" ;;
      LANGUAGE) LANGUAGE="$value" ;;
      PANEL_SELECTION) PANEL_SELECTION="$value" ;;
      ACME_EMAIL) ACME_EMAIL="$value" ;;
      CF_TOKEN) CF_TOKEN="$value" ;;
      DOMAINS) domain_csv="$value" ;;
      TELEGRAM_BOT_TOKEN) TELEGRAM_BOT_TOKEN="$value" ;;
      TELEGRAM_CHAT_ID) TELEGRAM_CHAT_ID="$value" ;;
    esac
  done < "$CONFIG_FILE"

  [[ "$config_version" == "2" ]] || die "$(tr_text config_damaged)"
  [[ "$LANGUAGE" == "fa" || "$LANGUAGE" == "en" ]] || LANGUAGE="fa"
  [[ -n "$PANEL_SELECTION" && -n "$ACME_EMAIL" && -n "$CF_TOKEN" && -n "$domain_csv" ]] ||
    die "$(tr_text config_incomplete)"

  IFS=',' read -r -a DOMAINS <<< "$domain_csv"
  validate_loaded_domains
}

validate_loaded_domains() {
  local domain=""
  ((${#DOMAINS[@]} >= 1 && ${#DOMAINS[@]} <= 50)) || die "$(tr_text invalid_domain_count)"

  for domain in "${DOMAINS[@]}"; do
    is_valid_domain "$domain" || die "$(tr_format invalid_domain_config "$domain")"
  done
}

install_self() {
  local source_path="$SCRIPT_SOURCE"

  if [[ "$source_path" != /* ]]; then
    source_path="$(pwd)/$source_path"
  fi
  [[ -r "$source_path" ]] || die "$(tr_text self_copy_failed)"

  install -D -m 0755 "$source_path" "$INSTALLED_SCRIPT"
}

install_cron() {
  local tmp=""
  local cron_dir=""
  cron_dir="$(dirname "$CRON_FILE")"
  mkdir -p "$cron_dir"
  tmp="$(mktemp "${cron_dir}/marzban-wildcard-ssl.tmp.XXXXXX")"

  {
    printf 'SHELL=/bin/bash\n'
    printf 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n'
    printf '17 3 * * * root WSSL_CRON_RUN=1 %s --renew >> %s 2>&1\n' "$INSTALLED_SCRIPT" "$LOG_FILE"
  } > "$tmp"
  chmod 644 "$tmp"
  mv -f "$tmp" "$CRON_FILE"
  success "$(tr_text cron_installed)"
}

remove_legacy_cron() {
  local current=""
  local filtered=""
  local backup=""

  command_exists crontab || return 0
  current="$(mktemp)"
  filtered="$(mktemp)"

  if ! crontab -l > "$current" 2>/dev/null; then
    rm -f "$current" "$filtered"
    return 0
  fi

  if ! awk '
    index($0, "/root/install.sh") && index($0, "/var/log/ssl_renew.log") { found = 1 }
    END { exit !found }
  ' "$current"; then
    rm -f "$current" "$filtered"
    return 0
  fi

  backup="${CONFIG_DIR}/legacy-root-crontab.backup.$(date '+%Y%m%d-%H%M%S')"
  cp "$current" "$backup"
  chmod 600 "$backup"
  awk '!(index($0, "/root/install.sh") && index($0, "/var/log/ssl_renew.log"))' "$current" > "$filtered"
  crontab "$filtered"
  rm -f "$current" "$filtered"
  success "$(tr_format legacy_removed "$backup")"
}

install_log_rotation() {
  local tmp=""
  local logrotate_dir=""
  logrotate_dir="$(dirname "$LOGROTATE_FILE")"
  mkdir -p "$logrotate_dir"
  tmp="$(mktemp "${logrotate_dir}/marzban-wildcard-ssl.tmp.XXXXXX")"

  {
    printf '%s {\n' "$LOG_FILE"
    printf '    weekly\n'
    printf '    rotate 8\n'
    printf '    compress\n'
    printf '    delaycompress\n'
    printf '    missingok\n'
    printf '    notifempty\n'
    printf '    create 0600 root root\n'
    printf '}\n'
  } > "$tmp"
  chmod 644 "$tmp"
  mv -f "$tmp" "$LOGROTATE_FILE"
}

certificate_fingerprint() {
  local cert_file="$1"
  [[ -s "$cert_file" ]] || return 0
  openssl x509 -in "$cert_file" -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2-
}

verify_certificate_and_key() {
  local cert_public=""
  local key_public=""

  [[ -s "$MASTER_CERT_FILE" && -s "$MASTER_KEY_FILE" ]] || return 1
  openssl x509 -in "$MASTER_CERT_FILE" -noout >/dev/null 2>&1 || return 1
  openssl pkey -in "$MASTER_KEY_FILE" -noout >/dev/null 2>&1 || return 1

  cert_public="$(
    openssl x509 -in "$MASTER_CERT_FILE" -pubkey -noout 2>/dev/null |
      openssl pkey -pubin -outform DER 2>/dev/null |
      openssl dgst -sha256 2>/dev/null
  )"
  key_public="$(
    openssl pkey -in "$MASTER_KEY_FILE" -pubout -outform DER 2>/dev/null |
      openssl dgst -sha256 2>/dev/null
  )"

  [[ -n "$cert_public" && "$cert_public" == "$key_public" ]]
}

certificate_has_dns_name() {
  local name="$1"

  openssl x509 -in "$MASTER_CERT_FILE" -noout -ext subjectAltName 2>/dev/null |
    tr ',' '\n' |
    sed -n 's/^[[:space:]]*//; /^DNS:/p' |
    grep -Fqx "DNS:${name}"
}

verify_certificate_domains() {
  local domain=""

  for domain in "${DOMAINS[@]}"; do
    certificate_has_dns_name "$domain" || return 1
    certificate_has_dns_name "*.${domain}" || return 1
  done
}

issue_or_check_certificate() {
  local force="${1:-0}"
  local main_domain="${DOMAINS[0]}"
  local old_fingerprint=""
  local new_fingerprint=""
  local rc=0
  local domain=""
  local acme_args=()
  local reload_command=""

  old_fingerprint="$(certificate_fingerprint "$MASTER_CERT_FILE")"
  export CF_Token="$CF_TOKEN"

  acme_args=(--issue --server letsencrypt --dns dns_cf --keylength ec-256)
  for domain in "${DOMAINS[@]}"; do
    acme_args+=(-d "$domain" -d "*.${domain}")
  done
  ((force == 1)) && acme_args+=(--force)

  info "$(tr_text cert_request)"
  set +e
  "$ACME_BIN" "${acme_args[@]}"
  rc=$?
  set -e

  if ((rc != 0 && rc != 2)); then
    die "$(tr_format acme_issue_failed "$rc" "$LOG_FILE")"
  fi

  mkdir -p "$DATA_DIR"
  printf -v reload_command 'WSSL_SKIP_LOCK=1 %q --deploy' "$INSTALLED_SCRIPT"
  if ! "$ACME_BIN" --install-cert -d "$main_domain" --ecc \
    --key-file "$MASTER_KEY_FILE" \
    --fullchain-file "$MASTER_CERT_FILE" \
    --reloadcmd "$reload_command"; then
    die "$(tr_text acme_deploy_failed)"
  fi
  chmod 600 "$MASTER_KEY_FILE"
  chmod 644 "$MASTER_CERT_FILE"

  verify_certificate_and_key || die "$(tr_text cert_invalid)"
  verify_certificate_domains || die "$(tr_text cert_domains_missing)"
  new_fingerprint="$(certificate_fingerprint "$MASTER_CERT_FILE")"
  [[ -n "$new_fingerprint" ]] || die "$(tr_text cert_read_failed)"

  success "$(tr_text cert_ready)"
  if [[ "$old_fingerprint" == "$new_fingerprint" && -n "$old_fingerprint" ]]; then
    return 10
  fi
  return 0
}

backup_env_file() {
  local env_file="$1"
  local backup_file=""
  backup_file="${env_file}.backup.$(date '+%Y%m%d-%H%M%S')"
  cp -a "$env_file" "$backup_file"
  printf '%s' "$backup_file"
}

update_env_value() {
  local env_file="$1"
  local key="$2"
  local value="$3"
  local temp_file=""

  temp_file="$(mktemp "${env_file}.tmp.XXXXXX")"
  awk -v wanted_key="$key" -v wanted_value="$value" '
    BEGIN { replaced = 0 }
    {
      candidate = $0
      sub(/^[[:space:]]*#[[:space:]]*/, "", candidate)
      if (candidate ~ "^[[:space:]]*" wanted_key "[[:space:]]*=") {
        if (!replaced) {
          print wanted_key " = \"" wanted_value "\""
          replaced = 1
        }
        next
      }
      print
    }
    END {
      if (!replaced) {
        print wanted_key " = \"" wanted_value "\""
      }
    }
  ' "$env_file" > "$temp_file"

  chown --reference="$env_file" "$temp_file"
  chmod --reference="$env_file" "$temp_file"
  mv -f "$temp_file" "$env_file"
}

atomic_copy() {
  local source_file="$1"
  local destination_file="$2"
  local mode="$3"
  local destination_dir=""
  local temp_file=""

  destination_dir="$(dirname "$destination_file")"
  mkdir -p "$destination_dir"
  temp_file="$(mktemp "${destination_dir}/.$(basename "$destination_file").tmp.XXXXXX")"
  install -m "$mode" "$source_file" "$temp_file"
  mv -f "$temp_file" "$destination_file"
}

restart_panel() {
  local panel="$1"
  local label=""

  case "$panel" in
    marzban)
      label="Marzban"
      if command_exists marzban && marzban restart; then
        success "$(tr_format panel_restarted "$label")"
        return 0
      fi
      if command_exists systemctl && systemctl restart marzban; then
        success "$(tr_format panel_restarted "$label")"
        return 0
      fi
      ;;
    pasarguard)
      label="PasarGuard"
      if command_exists pasarguard && pasarguard restart --no-logs; then
        success "$(tr_format panel_restarted "$label")"
        return 0
      fi
      if command_exists systemctl && systemctl restart pasarguard; then
        success "$(tr_format panel_restarted "$label")"
        return 0
      fi
      ;;
  esac

  warn "$(tr_format restart_failed "$label")"
  return 1
}

deploy_to_panel() {
  local panel="$1"
  local env_file=""
  local cert_file=""
  local key_file=""
  local label=""
  local backup_file=""

  case "$panel" in
    marzban)
      label="Marzban"
      env_file="$MARZBAN_ENV"
      cert_file="$MARZBAN_CERT"
      key_file="$MARZBAN_KEY"
      ;;
    pasarguard)
      label="PasarGuard"
      env_file="$PASARGUARD_ENV"
      cert_file="$PASARGUARD_CERT"
      key_file="$PASARGUARD_KEY"
      ;;
    *)
      warn "$(tr_format unknown_panel "$panel")"
      return 1
      ;;
  esac

  if [[ ! -f "$env_file" ]]; then
    warn "$(tr_format missing_panel "$label" "$env_file")"
    return 1
  fi

  atomic_copy "$MASTER_CERT_FILE" "$cert_file" 0644
  atomic_copy "$MASTER_KEY_FILE" "$key_file" 0600

  backup_file="$(backup_env_file "$env_file")"
  update_env_value "$env_file" "UVICORN_SSL_CERTFILE" "$cert_file"
  update_env_value "$env_file" "UVICORN_SSL_KEYFILE" "$key_file"
  success "$(tr_format config_updated "$env_file")"
  info "$(tr_format backup_path "$backup_file")"

  restart_panel "$panel"
}

deploy_selected_panels() {
  local panel=""
  local selected=()
  local failures=0
  IFS=',' read -r -a selected <<< "$PANEL_SELECTION"

  verify_certificate_and_key || die "$(tr_text cert_pair_missing)"
  verify_certificate_domains || die "$(tr_text cert_domains_missing)"

  for panel in "${selected[@]}"; do
    if ! deploy_to_panel "$panel"; then
      failures=$((failures + 1))
    fi
  done

  if ((failures > 0)); then
    warn "$(tr_format deploy_failures "$failures")"
    return 1
  fi
  return 0
}

certificate_status() {
  if [[ ! -s "$MASTER_CERT_FILE" ]]; then
    printf '%s: %s\n' "$(tr_text certificate_label)" "$(tr_text not_installed)"
    return 0
  fi

  printf '%s\n' "$(tr_format certificate_path "$MASTER_CERT_FILE")"
  openssl x509 -in "$MASTER_CERT_FILE" -noout -subject -issuer -dates 2>/dev/null || true
}

show_status() {
  local domain=""
  local renewal_status=""
  local telegram_status=""

  load_config
  clear_screen
  print_header
  print_section "1" "1" "$(tr_text section_status)"
  if [[ -f "$CRON_FILE" ]]; then
    renewal_status="$(tr_text installed)"
  else
    renewal_status="$(tr_text not_installed)"
  fi
  if [[ -n "$TELEGRAM_BOT_TOKEN" ]]; then
    telegram_status="$(tr_text enabled)"
  else
    telegram_status="$(tr_text disabled)"
  fi
  printf '  %s: %s\n' "$(tr_text panels_label)" "$(panel_selection_label)"
  printf '  %s:\n' "$(tr_text domains_label)"
  for domain in "${DOMAINS[@]}"; do
    printf '    • %s  +  *.%s\n' "$domain" "$domain"
  done
  printf '  %s: %s\n' "$(tr_text renewal_label)" "$renewal_status"
  printf '  %s: %s\n\n' "$(tr_text telegram_label)" "$telegram_status"
  certificate_status
}

interactive_setup() {
  clear_screen
  print_language_screen
  choose_language
  clear_screen
  print_header
  print_section "1" "5" "$(tr_text section_panels)"
  choose_panels
  print_section "2" "5" "$(tr_text section_account)"
  prompt_email
  prompt_cloudflare_token
  print_section "3" "5" "$(tr_text section_domains)"
  prompt_domains
  print_section "4" "5" "$(tr_text section_notifications)"
  prompt_telegram
  print_section "5" "5" "$(tr_text section_review)"
  confirm_setup

  print_section "" "" "$(tr_text section_processing)"
  ensure_dependencies
  install_self
  write_config
  install_acme

  if issue_or_check_certificate 0; then
    :
  else
    local rc=$?
    ((rc == 10)) || return "$rc"
  fi

  install_cron
  install_log_rotation
  remove_legacy_cron
  success "$(tr_text setup_complete)"
  send_telegram "✅ ${PROJECT_NAME}: $(tr_format telegram_setup_complete "$(panel_selection_label)")"
  printf '\n'
  certificate_status
}

renew_certificate() {
  local rc=0
  local main_domain=""

  load_config
  [[ -x "$ACME_BIN" ]] || die "$(tr_text acme_missing): ${ACME_BIN}"
  ensure_dependencies
  main_domain="${DOMAINS[0]}"
  export CF_Token="$CF_TOKEN"

  set +e
  "$ACME_BIN" --renew -d "$main_domain" --ecc --server letsencrypt
  rc=$?
  set -e

  if ((rc == 0)); then
    success "$(tr_text cert_ready)"
    return 0
  fi
  if ((rc == 2)); then
    info "$(tr_text cert_unchanged)"
    return 0
  fi
  die "$(tr_format renew_failed "$rc")"
}

force_renew_certificate() {
  local main_domain=""

  load_config
  [[ -x "$ACME_BIN" ]] || die "$(tr_text acme_missing): ${ACME_BIN}"
  ensure_dependencies
  main_domain="${DOMAINS[0]}"
  export CF_Token="$CF_TOKEN"
  "$ACME_BIN" --renew -d "$main_domain" --ecc --server letsencrypt --force ||
    die "$(tr_text forced_renew_failed)"
  success "$(tr_text cert_ready)"
}

main() {
  local command="${1:---setup}"

  case "$command" in
    -h|--help)
      print_help
      return 0
      ;;
  esac

  require_root
  trap 'on_unexpected_error "$?" "$LINENO"' ERR
  if [[ "${WSSL_SKIP_LOCK:-0}" != "1" ]]; then
    acquire_lock
  fi

  case "$command" in
    --setup)
      interactive_setup
      ;;
    --renew)
      renew_certificate
      ;;
    --force-renew)
      force_renew_certificate
      ;;
    --deploy)
      load_config
      if ! deploy_selected_panels; then
        trap - ERR
        return 1
      fi
      ;;
    --status)
      show_status
      ;;
    *)
      print_help
      die "$(tr_format unknown_option "$command")"
      ;;
  esac
}

if [[ "${WSSL_SOURCE_ONLY:-0}" != "1" ]]; then
  main "$@"
fi
