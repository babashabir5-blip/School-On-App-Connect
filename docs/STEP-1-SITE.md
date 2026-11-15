# Step 1 — Make schoolonapp.in a PWA

This step has to happen on the server before the Android app will lose its URL
bar. It takes about 15 minutes in cPanel File Manager.

## 1.1 Upload the PWA files

Upload from `C:\Users\user\schoolonapp-connect\site\` to the **web root** (the
folder that contains `index.php`, `application/`, `assets/`, `uploads/`):

| Local file | Server path |
|---|---|
| `manifest.json` | `/manifest.json` |
| `sw.js` | `/sw.js` |
| `offline.html` | `/offline.html` |
| `icons/icon-192.png` | `/icons/icon-192.png` |
| `icons/icon-512.png` | `/icons/icon-512.png` |
| `icons/icon-maskable-512.png` | `/icons/icon-maskable-512.png` |

**Do not upload `assetlinks.json` yet** — it needs the real SHA-256 fingerprint
from Step 2. A placeholder file is harmless but it will not verify.

cPanel → File Manager → make sure "Show Hidden Files" is on (for `.well-known`).

## 1.2 Append the .htaccess rules

Open the **root** `.htaccess` (the one with the CodeIgniter `RewriteRule`).
Append the contents of `site/.htaccess-append.txt` at the end. Do not replace the
existing rules.

Then confirm these exist:
- `/manifest.json` returns JSON (not a redirect to `/authentication`)
- `/sw.js` returns JavaScript, not HTML

## 1.3 Add the manifest link + service worker to the login page

Edit `application/views/authentication/login.php`.

**a)** Directly after this line:

```php
<link rel="shortcut icon" href="<?php echo base_url('assets/images/favicon.png');?>">
```

insert:

```php
	<link rel="manifest" href="<?php echo base_url('manifest.json'); ?>">
	<meta name="theme-color" content="#5061AB">
	<link rel="apple-touch-icon" href="<?php echo base_url('icons/icon-192.png'); ?>">
```

**b)** Just before `</body>`, insert:

```html
	<script>
	if ('serviceWorker' in navigator) {
		window.addEventListener('load', function () {
			navigator.serviceWorker.register('<?php echo base_url('sw.js'); ?>');
		});
	}
	</script>
```

> Why this file? The login page is the first thing Chrome loads, and it is
> standalone (no shared layout header), so the manifest link must be added here.
> Record this edit — Ramom's System Update can overwrite the file.

## 1.4 Verify

From this machine:

```powershell
pwsh -File C:\Users\user\schoolonapp-connect\docs\verify-site.ps1
```

Expected after Step 1: everything PASS except `assetlinks.json`
(`PLACEHOLDER` until Step 2).

You can also check manually in Chrome on a phone:
menu → **Install app** should appear on schoolonapp.in. That proves the manifest
and service worker are valid.

## 1.5 If something fails

| Symptom | Cause | Fix |
|---|---|---|
| `/manifest.json` 307 → `/authentication` | file not uploaded, or uploaded inside a subfolder | upload to the folder containing `index.php` |
| `/sw.js` returns HTML | same as above | same |
| `manifest.json` returns HTML content-type | MIME mapping missing | the `.htaccess` `AddType` lines; in LiteSpeed you can also add the MIME in cPanel → MIME Types |
| `Install app` missing in Chrome | manifest invalid or SW not registering | check Chrome DevTools → Application → Manifest / Service Workers |
| Icons 404 | `icons/` uploaded to the wrong level | must be `/icons/icon-192.png` |
