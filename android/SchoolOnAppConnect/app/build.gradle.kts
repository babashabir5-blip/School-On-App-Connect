plugins {
    id("com.android.application")
}

android {
    namespace = "in.schoolonapp.connect"
    compileSdk = 36

    defaultConfig {
        applicationId = "in.schoolonapp.connect"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        buildConfig = false
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // TWA launcher (LauncherActivity, splash, asset-link handling).
    implementation("com.google.androidbrowserhelper:androidbrowserhelper:2.7.4")

    // LauncherActivity extends AppCompatActivity, so the theme must be an
    // AppCompat theme. Declared explicitly instead of relying on the
    // transitive dependency, so a future browserhelper update cannot
    // silently change the AppCompat version.
    implementation("androidx.appcompat:appcompat:1.7.0")
}
