# Pre-release checklist

## On the server (Step 1)

- [ ] `/manifest.json` → 200, `application/json`, parses, has `name`, `start_url`, 192 + 512 icons
- [ ] `/sw.js` → 200, JavaScript, `Service-Worker-Allowed: /`
- [ ] `/offline.html` → 200, HTML
- [ ] `/icons/icon-192.png`, `/icons/icon-512.png`, `/icons/icon-maskable-512.png` → 200, `image/png`
- [ ] `/.well-known/assetlinks.json` → 200, `application/json`, real SHA-256 values
- [ ] Login page source contains `<link rel="manifest"` and the service worker registration
- [ ] Chrome on a phone offers **Install app** on `schoolonapp.in`
- [ ] `pwsh docs/verify-site.ps1` → all PASS

## On the APK (Step 2)

- [ ] App opens to the login page **with no URL bar**
- [ ] Google Digital Asset Links checker → **Success**
- [ ] Correct app name and icon on the launcher
- [ ] Splash screen shows the brand colour + logo

## Functional pass (real phone, real account)

- [ ] Login works (student, parent, and one staff account)
- [ ] Force-close the app → reopen → still logged in
- [ ] Logout works
- [ ] Dashboard loads
- [ ] Attendance page loads
- [ ] Results / report card opens; PDF download works and opens in a PDF viewer
- [ ] Fee invoice PDF downloads
- [ ] Homework page: attach a file → Android file picker opens → upload succeeds
- [ ] Notices/events load
- [ ] Back button walks history, then exits the app
- [ ] Airplane mode → offline page appears → disable airplane mode → **Try again** works
- [ ] WhatsApp / Zoom / Google Meet links open the real app, not inside the wrapper
- [ ] Rotate the phone → layout survives
- [ ] Android 14/15 device: no crash on launch, predictive back OK

## Device coverage

- [ ] One cheap Android 9/10 device with 2 GB RAM (the realistic worst case)
- [ ] One current Android 15/16 device
- [ ] One device where Chrome is disabled → app should open in a Custom Tab instead of crashing

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| URL bar visible | assetlinks not verified | wrong SHA-256, wrong package, file returns HTML, or a redirect |
| App opens browser tab, not full screen | Chrome missing/disabled → `customtabs` fallback | enable Chrome, or accept the fallback |
| White screen | start URL unreachable or blocked | check `launch_url`, open it in Chrome |
| Login lost on every launch | cookies cleared on app kill | make sure the app is not being "force stopped" by a battery optimizer |
| File picker does nothing | site input not standard `<input type=file>` | test the same page in Chrome; report which page |
| PDF doesn't download | download intercepted by the site | open the invoice URL in Chrome to compare |
| App icon is the "SOA" letters | placeholder logo was used | replace `brand/source-logo.png`, re-run renderer, rebuild |

## Before distributing

- [ ] Keystore backed up in two places, passwords stored safely
- [ ] `versionCode` / `versionName` recorded somewhere you will find them
- [ ] APK uploaded to a stable URL (or Play internal testing track)
- [ ] Short "how to install" message prepared for parents
- [ ] Uninstall instructions for parents (Settings → Apps → School On App Connect → Uninstall)
