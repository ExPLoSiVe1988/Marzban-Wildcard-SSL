<div align="center">

[**فارسی**](./README.md) | [**English**](./README-en.md)

# دریافت Wildcard SSL برای Marzban و PasarGuard

صدور، نصب و تمدید خودکار یک گواهی چنددامنه‌ای با `acme.sh`، Let's Encrypt و Cloudflare DNS

</div>

---

<div align="center">
  <a href="https://www.youtube.com/watch?v=5-RiZ1qNT90" target="_blank">
    <img src="https://img.youtube.com/vi/5-RiZ1qNT90/hqdefault.jpg" alt="ویدیوی آموزش کامل" width="320">
  </a>
  <p><strong>برای مشاهده ویدیوی کامل آموزش، روی تصویر بالا کلیک کنید</strong></p>
</div>

## این اسکریپت چه کاری انجام می‌دهد؟

این پروژه برای کاربران Marzban و PasarGuard ساخته شده است. شما فقط دامنه‌های پایه مثل `example.com` را وارد می‌کنید و اسکریپت به‌صورت خودکار هر دو نام زیر را به گواهی اضافه می‌کند:

```text
example.com
*.example.com
```

پس از صدور گواهی، مسیرهای SSL در فایل `.env` پنل به‌روزرسانی می‌شوند، پنل ری‌استارت می‌شود و تمدید روزانه بدون نیاز به ورود دوباره اطلاعات نصب خواهد شد.

## امکانات

- پشتیبانی از نصب رسمی **Marzban**
- پشتیبانی از نصب رسمی **PasarGuard**
- امکان نصب گواهی روی هر دو پنل به‌صورت هم‌زمان
- شناسایی خودکار پنل نصب‌شده
- پشتیبانی از چند دامنه پایه در یک گواهی
- ساخت خودکار نام پایه و wildcard هر دامنه
- دریافت امن Cloudflare API Token؛ توکن هنگام تایپ نمایش داده نمی‌شود
- ذخیره تنظیمات محرمانه با دسترسی `600`
- تهیه بکاپ از `.env` پیش از هر تغییر
- ویرایش بدون تکرار متغیرهای `UVICORN_SSL_*`
- بررسی تطابق گواهی و کلید خصوصی
- تمدید کاملاً غیرتعاملی با cron و reload hook استاندارد `acme.sh`
- جلوگیری از اجرای هم‌زمان چند عملیات SSL
- اعلان اختیاری تلگرام
- لاگ و دستور مشاهده وضعیت

## پیش‌نیازها

- Ubuntu یا Debian
- دسترسی `root` یا `sudo`
- نصب رسمی Marzban، PasarGuard یا هر دو
- قرار داشتن DNS همه دامنه‌ها روی Cloudflare
- یک Cloudflare API Token که به تمام دامنه‌های واردشده دسترسی داشته باشد

> اگر دامنه‌ها در چند حساب جداگانه Cloudflare هستند، یک توکن باید به همه آن‌ها دسترسی داشته باشد؛ در غیر این صورت آن دامنه‌ها را نمی‌توان داخل یک گواهی مشترک صادر کرد.

## ساخت Cloudflare API Token

1. وارد صفحه [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens) شوید.
2. روی `Create Token` کلیک کنید.
3. قالب `Edit zone DNS` را انتخاب کنید یا این دسترسی‌ها را بدهید:
   - `Zone > DNS > Edit`
   - `Zone > Zone > Read`
4. در قسمت Zone Resources، دامنه‌های مورد نظر یا `All zones` را انتخاب کنید.
5. توکن را کپی و در محل امن نگهداری کنید.

> توکن Cloudflare، توکن تلگرام، کلید خصوصی و فایل `/etc/marzban-wildcard-ssl/config` را برای هیچ‌کس ارسال نکنید.

## نصب سریع

دستورهای زیر را با کاربری اجرا کنید که دسترسی `sudo` دارد:

```bash
curl -fsSL https://raw.githubusercontent.com/ExPLoSiVe1988/Marzban-Wildcard-SSL/main/install.sh -o install.sh
sudo bash install.sh
```

اسکریپت مرحله‌به‌مرحله این موارد را می‌پرسد:

1. زبان
2. پنل مقصد: Marzban، PasarGuard یا هر دو
3. ایمیل حساب Let's Encrypt
4. Cloudflare API Token
5. تعداد و نام دامنه‌های پایه
6. اطلاعات اختیاری ربات تلگرام
7. تأیید نهایی پیش از ایجاد تغییر

### مثال ورود دامنه

اگر این دامنه‌ها را دارید:

```text
example.com
example.net
```

تعداد را `2` وارد کنید و فقط همین دو دامنه پایه را بنویسید. اسکریپت گواهی را برای این چهار نام می‌گیرد:

```text
example.com
*.example.com
example.net
*.example.net
```

نیازی به وارد کردن `https://`، پورت، مسیر یا `*.` نیست.

## مسیرهای استفاده‌شده

| مورد | مسیر |
|---|---|
| تنظیمات امن اسکریپت | `/etc/marzban-wildcard-ssl/config` |
| نسخه نصب‌شده اسکریپت | `/usr/local/sbin/marzban-wildcard-ssl` |
| گواهی اصلی مدیریت‌شده | `/var/lib/marzban-wildcard-ssl/fullchain.pem` |
| کلید اصلی مدیریت‌شده | `/var/lib/marzban-wildcard-ssl/key.pem` |
| لاگ | `/var/log/marzban-wildcard-ssl.log` |
| cron | `/etc/cron.d/marzban-wildcard-ssl` |
| تنظیم چرخش لاگ | `/etc/logrotate.d/marzban-wildcard-ssl` |
| فایل تنظیمات Marzban | `/opt/marzban/.env` |
| گواهی Marzban | `/var/lib/marzban/certs/fullchain.pem` |
| کلید Marzban | `/var/lib/marzban/certs/key.pem` |
| فایل تنظیمات PasarGuard | `/opt/pasarguard/.env` |
| گواهی PasarGuard | `/var/lib/pasarguard/cert.pem` |
| کلید PasarGuard | `/var/lib/pasarguard/key.pem` |

مسیرهای PasarGuard مطابق [مستندات رسمی PasarGuard](https://docs.pasarguard.org/fa/panel/configuration/) هستند.

## دستورات مدیریت

```bash
sudo marzban-wildcard-ssl --status

sudo marzban-wildcard-ssl --renew

sudo marzban-wildcard-ssl --force-renew

sudo marzban-wildcard-ssl --deploy

sudo marzban-wildcard-ssl --setup

marzban-wildcard-ssl --help
```

## تمدید خودکار چگونه کار می‌کند؟

هر روز ساعت `03:17`، اسکریپت فقط وضعیت گواهی همین پروژه را بررسی می‌کند. اگر `acme.sh` تشخیص دهد زمان تمدید رسیده است:

1. رکورد DNS موقت را با Cloudflare ایجاد می‌کند.
2. گواهی جدید را از Let's Encrypt می‌گیرد.
3. گواهی را در مسیر اصلی نصب می‌کند.
4. hook استقرار، گواهی را روی پنل‌های انتخاب‌شده کپی می‌کند.
5. فایل `.env` بررسی و پنل ری‌استارت می‌شود.

اگر گواهی هنوز معتبر باشد، پنل ری‌استارت نمی‌شود.

## ارتقا از نسخه قدیمی

کافی است نسخه جدید را دانلود و دوباره اجرا کنید:

```bash
curl -fsSL https://raw.githubusercontent.com/ExPLoSiVe1988/Marzban-Wildcard-SSL/main/install.sh -o install.sh
sudo bash install.sh
```

نسخه جدید اطلاعات را در مسیر امن جدید ذخیره می‌کند. برای امنیت، توکن Cloudflare را دوباره وارد کنید. cron قدیمی همین پروژه که `/root/install.sh` و `/var/log/ssl_renew.log` را اجرا می‌کرد، به‌صورت خودکار شناسایی و حذف می‌شود. پیش از حذف نیز یک بکاپ در `/etc/marzban-wildcard-ssl/` ساخته خواهد شد؛ سایر cronها تغییر نمی‌کنند.

## رفع اشکال

### فایل `.env` پیدا نشد

ابتدا پنل را با اسکریپت رسمی خودش نصب کنید. مسیرهای مورد انتظار:

```text
/opt/marzban/.env
/opt/pasarguard/.env
```

### صدور گواهی ناموفق بود

- مطمئن شوید Nameserver دامنه روی Cloudflare است.
- دسترسی‌های API Token را بررسی کنید.
- مطمئن شوید توکن به همه Zoneهای واردشده دسترسی دارد.
- ساعت و تاریخ سرور را بررسی کنید.
- لاگ را ببینید:

```bash
sudo tail -n 100 /var/log/marzban-wildcard-ssl.log
```

### پنل بعد از نصب گواهی باز نمی‌شود

وضعیت و لاگ پنل را بررسی کنید:

```bash
marzban status
marzban logs

pasarguard status
pasarguard logs
```

قبل از تغییر `.env` یک فایل بکاپ کنار همان فایل ساخته می‌شود؛ نام آن شامل تاریخ و ساعت است.

## نکات امنیتی

- فایل تنظیمات اسکریپت شامل Cloudflare API Token است و فقط root باید آن را بخواند.
- API Token محدود بهتر از Cloudflare Global API Key است.
- کلید خصوصی با دسترسی `600` نصب می‌شود.
- از انتشار خروجی کامل فایل تنظیمات یا لاگ‌های حاوی اطلاعات محرمانه خودداری کنید.
- برای هر سرور، توکنی با کمترین دسترسی لازم بسازید.

## توسعه‌دهنده

- GitHub: [@ExPLoSiVe1988](https://github.com/ExPLoSiVe1988)
- Telegram: [@H_ExPLoSiVe](https://t.me/H_ExPLoSiVe)
- Channel: [@Botgineer](https://t.me/Botgineer)

## حمایت از پروژه

اگر پروژه برایتان مفید بوده است، با دادن ستاره در GitHub یا حمایت مالی به توسعهٔ آن کمک کنید.

### پرداخت ریالی

[حمایت از پروژه با پرداخت ریالی در Reymit](https://reymit.ir/botgineer)

### رمزارز

| رمزارز | آدرس |
|:---|:---|
| 🟣 **اتریوم (ETH - ERC20)** | `0x157F3Eb423A241ccefb2Ddc120eF152ce4a736eF` |
| 🔵 **ترون (TRX - TRC20)** | `TEdu5VsNNvwjCRJpJJ7zhjXni8Y6W5qAqk` |
| 🟢 **تتر (USDT - BEP20)** | `0x78C406B501c4895627CC22F6653AD66163294D60` |
