apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'

android {
    namespace "com.example.my_webapp"
    compileSdk = 35
    ndkVersion = "27.0.12077973" // Optional unless using native C/C++

    defaultConfig {
        applicationId = "com.example.my_webapp"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    signingConfigs {
        debug {
            storeFile file("../debug.keystore")
            storePassword "android"
            keyAlias "androiddebugkey"
            keyPassword "android"
        }
        release {
            // Use the debug key for release as a placeholder (NOT RECOMMENDED FOR PROD)
            storeFile file("../debug.keystore")
            storePassword "android"
            keyAlias "androiddebugkey"
            keyPassword "android"
        }
    }

    buildTypes {
        debug {
            signingConfig signingConfigs.debug
        }
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            shrinkResources false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
