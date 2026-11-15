# School On App Connect — TWA wrapper for schoolonapp.in

Everything needed to ship `schoolonapp.in` as an Android app, with no URL bar,
using a Trusted Web Activity.

```
schoolonapp-connect/
├── site/                         → upload these to the web root of schoolonapp.in
│   ├── manifest.json             /manifest.json
│   ├── sw.js                     /sw.js
│   ├── offline.html              /offline.html
│   ├── icons/                    /icons/
│   ├── .well-known/assetlinks.json   /.well-known/
│   └── .htaccess-append.txt      append to the existing root .htaccess
├── android/SchoolOnAppConnect/   → open this folder in Android Studio
├── brand/                        → logo + icon renderer
└── docs/                         → step-by-step instructions
```

## Order of work

1. **`docs/STEP-1-SITE.md`** — upload the PWA files, add the manifest link to the
   login page, append the .htaccess rules, verify with `docs/verify-site.ps1`.
2. **`docs/STEP-2-ANDROID.md`** — install Android Studio, open the project,
   create the signing key, paste the SHA-256 into `assetlinks.json`, build the APK.
3. **`docs/CHECKLIST.md`** — what to test on a real phone before handing it out.

## Facts baked into this project

| Item | Value |
|---|---|
| Start URL | `https://schoolonapp.in/` |
| Package / applicationId | `in.schoolonapp.connect` |
| App name | School On App Connect |
| Launcher label | School On App Connect |
| Brand colour | `#5061AB` (from the site's login CSS) |
| minSdk / targetSdk | 23 / 36 |
| AGP / Gradle | 8.13.0 / 8.13 |
| TWA library | `com.google.androidbrowserhelper:androidbrowserhelper:2.7.4` |

## What this app is (and is not)

- It renders your existing web app inside Chrome as a Trusted Web Activity.
  Login, fees, homework, results — all identical to the site.
- It is **not** a native app: no push notifications, no offline data, no app-side
  caching of student records (intentional — shared phones must not leak data).
- If Digital Asset Links verification fails, it falls back to a Custom Tab with a
  URL bar instead of crashing. That is the signal to fix `assetlinks.json`.

## Icons

The current `brand/source-logo.png` is the 124×124 placeholder from your site, so
the renderer generated a clean "SOA" letter mark instead of shipping a broken
placeholder. To use the real logo:

```powershell
pwsh -File .\brand\render-icons.ps1 -Source C:\path\to\your-logo.png
```

Then rebuild the app. A square logo of at least 512×512 works best.
