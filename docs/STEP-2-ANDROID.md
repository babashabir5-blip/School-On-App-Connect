# Step 2 — Build the APK in Android Studio

## 2.1 Install Android Studio

1. Download the latest stable Android Studio and install it with default options.
   It brings its own JDK 17 — your existing Java 8 is not used.
2. On first launch, accept the SDK setup and let it install **Android SDK
   Platform 36** (Android 16), **build-tools** and **platform-tools**.

## 2.2 Open the project

1. **File → Open** → `C:\Users\user\schoolonapp-connect\android\SchoolOnAppConnect`
2. Trust the project when asked.
3. Wait for **Gradle sync**. First sync downloads Gradle 8.13, AGP 8.13.0 and
   `androidbrowserhelper:2.7.4` (a few minutes, needs internet).

> The project ships `gradle/wrapper/gradle-wrapper.properties` but not the
> wrapper `.jar` (binary). Android Studio downloads the distribution and
> regenerates it on first sync. If sync complains about the wrapper, open
> **Settings → Build, Execution, Deployment → Build Tools → Gradle**, set
> *Gradle distribution* to the bundled version, sync once, then run
> `gradle wrapper` in the Studio terminal.

## 2.3 Create the signing key (do this once, keep it forever)

1. **Build → Generate Signed App Bundle / APK…**
2. Choose **APK** → **Next**
3. **Create new…**
   - Key store path: `C:\Users\user\schoolonapp-connect\keys\schoolonapp-connect.jks`
     (outside the project folder)
   - Password / key alias: `schoolonapp` / `schoolonapp`
   - Validity: **25 years** minimum
   - Fill in at least one certificate field (name is enough)
4. **Next** → build variant **release** → **Create**.

Output: `app/release/app-release.apk`.

> Back up `schoolonapp-connect.jks` and both passwords somewhere safe (two
> locations). If you lose it you can never publish an update under the same
> package name — you would have to ship a brand-new app.

## 2.4 Get the SHA-256 fingerprints

**Release key:**

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" `
  -list -v -keystore "C:\Users\user\schoolonapp-connect\keys\schoolonapp-connect.jks" `
  -alias schoolonapp
```

Copy the **SHA256:** line (colon-separated hex).

**Debug key** (needed only while testing debug builds):

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" `
  -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -alias androiddebugkey -storepass android -keypass android
```

In Studio you can also use **Gradle panel → app → Tasks → android → signingReport**.

## 2.5 Publish the fingerprints

Edit `site/.well-known/assetlinks.json`, replacing:

- `PASTE_RELEASE_SHA256_HERE` with the release SHA-256
- `PASTE_DEBUG_SHA256_HERE` with the debug SHA-256 (or delete that line)

Upload it to `/.well-known/assetlinks.json`.

Check it:

```
https://schoolonapp.in/.well-known/assetlinks.json
```

must return `application/json` with your fingerprints — not HTML, not a redirect.

Validate with Google's tool:
<https://developers.google.com/digital-asset-links/tools/generator>
It must print **Success** for `in.schoolonapp.connect`.

## 2.6 Install and verify

1. Copy `app-release.apk` to the phone (USB, Google Drive, WhatsApp to yourself).
2. Allow "install unknown apps" for the source app, install.
3. Open the app.

**The URL bar must be gone.** If a URL bar is visible, Digital Asset Links did
not verify — see the troubleshooting table in `CHECKLIST.md`.

## 2.7 Changing the start URL or branding later

| What | Where |
|---|---|
| Site URL | `app/src/main/res/values/strings.xml` → `launch_url` |
| App name | `strings.xml` → `app_name` |
| Colours | `res/values/colors.xml` |
| Icons | `brand/render-icons.ps1`, then rebuild |
| Package name | `app/build.gradle.kts` → `applicationId`, **also** the assetlinks entry. Changing it creates a different app. |

Version bumps for updates: increment `versionCode` (integer) and `versionName`
(string) in `app/build.gradle.kts`, rebuild with the **same** keystore.
