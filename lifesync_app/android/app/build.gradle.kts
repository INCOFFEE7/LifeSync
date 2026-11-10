import com.android.build.gradle.internal.api.ApkVariantOutputImpl
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.lifesync_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        resValues = true
    }

    defaultConfig {
        applicationId = "com.example.lifesync_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = "2026.11.06.01.02"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    flavorDimensions += "brand"

    productFlavors {
        create("lifesync") {
            dimension = "brand"
            applicationId = "com.example.lifesync_app"
        }
        create("beebee") {
            dimension = "brand"
            applicationId = "com.example.lifesync_beebee"
        }
    }

    applicationVariants.all {
        val variant = this
        outputs.all {
            val output = this as? ApkVariantOutputImpl
            if (output != null) {
                val appTitle = if (variant.flavorName == "beebee") "BeeHappy" else "WhatToDo"
                val fixedVersion = variant.versionName
                val abi = output.getFilter("ABI")
                val abiSuffix = if (abi != null) "-${abi}" else ""
                output.outputFileName = "${appTitle}_v${fixedVersion}${abiSuffix}.apk"
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
