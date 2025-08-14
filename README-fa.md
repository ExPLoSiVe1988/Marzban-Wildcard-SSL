<div align="center">

[**English**](./README.md) | [**فارسی (Persian)**](./README-fa.md)

</div>

---

# Marzban-Wildcard-SSL

این پروژه یک اسکریپت مادر برای گرفتن و تمدید خودکار گواهی Wildcard SSL برای دامنه‌های متعدد با استفاده از `acme.sh` و DNS کلودفلر است. همچنین فایل‌های لازم را برای پروژه مرزبان بروزرسانی می‌کند و اطلاع‌رسانی از طریق ربات تلگرام را پشتیبانی می‌کند.

<div align="center">
  <a href="https://www.youtube.com/watch?v=5-RiZ1qNT90" target="_blank">
    <img src="https://img.youtube.com/vi/5-RiZ1qNT90/hqdefault.jpg" alt="ویدیوی آموزش کامل" width="320">
  </a>
  <p><strong>برای مشاهده ویدیوی کامل آموزش، روی تصویر بالا کلیک کنید</strong></p>
</div>

<div align="center">
  <h3>💖 حمایت از پروژه</h3>
  <p>اگر این پروژه برایتان مفید بوده، لطفاً با ستاره دادن در گیت‌هاب حمایت خود را نشان دهید!</p>
  <a href="https://github.com/ExPLoSiVe1988/marzban-wildcard-ssl/stargazers">
    <img src="https://img.shields.io/github/stars/ExPLoSiVe1988/marzban-wildcard-ssl?style=for-the-badge&logo=github&color=FFDD00&logoColor=black" alt="به پروژه در گیت‌هاب ستاره دهید">
  </a>
</div>

## 🚀 نصب و استفاده

1. ابتدا اسکریپت نصب را اجرا کنید:
   ```bash
   bash <(curl -s https://raw.githubusercontent.com/ExPLoSiVe1988/marzban-wildcard-ssl/main/install.sh)
   ```
2. هنگام اجرا اطلاعات توکن کلودفلر و ایمیل کلودفلر را وارد کنید.
3. سپس از اسکریپت به صورت تعاملی تعداد دامنه‌ها و سپس دامنه‌ها را یکی یکی وارد کنید.
4. اسکریپت به صورت خودکار گواهی‌ها را صادر/تمدید می‌کند و مسیرها را در فایل مرزبان به‌روزرسانی می‌کند.
5. اطلاع‌رسانی از طریق تلگرام (اختیاری) انجام می‌شود.
6. کرون‌جاب تمدید خودکار اگر سرتیفیکیت دامنه کمتر از 30 روز مانده باشد، به صورت خودکار گرفته شده و پیام آن در ربات تلگرامی که وارد کرده‌اید ارسال می‌شود.

## ✅ لیست تغییرات انجام‌شده

| ویژگی | وضعیت |
|---|---|
| نصب `socat` در صورت نبودن | ✅ انجام شده |
| دریافت تعداد و اسامی دامنه‌ها به‌صورت تعاملی | ✅ انجام شده |
| پشتیبانی از چند دامنه برای گواهی Wildcard | ✅ انجام شده |
| ارسال پیام به ربات تلگرام (شروع، موفق، خطا، ریستارت) | ✅ انجام شده |
| ساخت دایرکتوری `/var/lib/marzban/certs` در صورت نبود | ✅ انجام شده |
| اجرای `acme.sh` با DNS Cloudflare | ✅ انجام شده |
| نصب گواهی‌ها و کلیدها در مسیر سفارشی | ✅ انجام شده |
| حذف یا جایگزینی خطوط فعال/کامنت `UVICORN_SSL_*` در `.env` | ✅ انجام شده |
| بررسی و ریستارت سرویس `marzban` در صورت فعال بودن | ✅ انجام شده |
| ساخت `cronjob` برای تمدید خودکار گواهی | ✅ انجام شده |
| ذخیره لاگ‌ها در `/var/log/ssl_renew.log` | ✅ انجام شده |

### ایجاد API Token در Cloudflare
| گام | توضیحات |
|:---|:---|
| ۱ | وارد حساب Cloudflare خود شوید: https://dash.cloudflare.com/profile/api-tokens |
| ۲ | روی `Create Token` کلیک کنید. |
| ۳ | از قالب آماده‌ی `Edit zone DNS` استفاده کنید یا توکن سفارشی با دسترسی‌های زیر بسازید: <br> • **Permissions:** Zone > DNS > Edit <br> • **Zone Resources:** Include > All zones یا فقط دامنه‌های مورد نظر |
| ۴ | API Token تولیدشده را کپی کرده و در جایی امن ذخیره کنید. |

### پیام‌های سیستمی

بعد از نصب یا آپدیت موفق، ربات پیام زیر را به ادمین تلگرام ارسال می‌کند:

| پیام | زمان ارسال | توضیح |
|---|---|---|
| `📄 گواهی برای DOMAIN پیدا نشد. صدور اولیه آغاز شد.` | زمانی که فایل گواهی در مسیر `/var/lib/marzban/certs/fullchain.pem` پیدا نمی‌شود. | آغاز فرایند صدور اولیه SSL |
| `✅ گواهی دامنه‌ها با موفقیت صادر یا تمدید شد` | پس از اجرای موفق دستور `acme.sh --issue ...` | موفقیت در صدور یا تمدید گواهی |
| `🔄 سرویس Marzban ریستارت شد.` | در صورتی که سرویس `marzban` فعال بوده و با موفقیت ری‌استارت شود. | پایان عملیات SSL و اعمال تغییرات |
| `❌ خطا در صدور یا تمدید گواهی برای دامنه‌ها.` | اگر دستور `acme.sh` برای صدور یا تمدید گواهی شکست بخورد. | پیام هشدار برای بررسی خطا |
| `⚠️ سرویس Marzban فعال نیست یا نامش متفاوت است.` | اگر `systemctl` نتواند وضعیت `marzban` را تأیید کند. | هشدار بابت نامعتبر بودن یا غیرفعال بودن سرویس |

-----

### 👨‍💻 توسعه‌دهنده

* GitHub: [@ExPLoSiVe1988](https://github.com/ExPLoSiVe1988)
* Telegram: [@H_ExPLoSiVe](https://t.me/H_ExPLoSiVe)
* Channel: [@Botgineer](https://t.me/Botgineer)

-----

### 💖 Support / Donate

If you find this project useful, please consider supporting me by donating to one of the wallets below:

| Cryptocurrency | Address |
|:---|:---|
| 🟣 **Ethereum (ETH - ERC20)** | `0x157F3Eb423A241ccefb2Ddc120eF152ce4a736eF` |
| 🔵 **Tron (TRX - TRC20)** | `TEdu5VsNNvwjCRJpJJ7zhjXni8Y6W5qAqk` |
| 🟢 **Tether (USDT - TRC20)** | `TN3cg5RM5JLEbnTgK5CU95uLQaukybPhtR` |
