package in.schoolonapp.connect;

/**
 * School On App Connect - Trusted Web Activity launcher.
 *
 * This is the entire "app": AndroidBrowserHelper's LauncherActivity opens
 * https://schoolonapp.in/ inside Chrome as a Trusted Web Activity, which
 * removes the URL bar once Digital Asset Links verification succeeds.
 *
 * Verification file:
 *   https://schoolonapp.in/.well-known/assetlinks.json
 * It must list this package name (in.schoolonapp.connect) together with the
 * SHA-256 fingerprint of the certificate this APK was signed with.
 *
 * The web side lives in /site of this repository:
 *   manifest.json, sw.js, offline.html, icons/, .well-known/assetlinks.json
 */
public final class LauncherActivity
        extends com.google.androidbrowserhelper.trusted.LauncherActivity {
}
