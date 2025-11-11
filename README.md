# 🧹 Flutter Cleaner for macOS

![App Icon](./FlutterCleaner/Screenshots/app_icon_512.png)

**Flutter Cleaner** is a lightweight macOS utility that scans your
system for Flutter projects and helps you reclaim disk space by cleaning
build artifacts safely.

Built with ❤️ in SwiftUI.

------------------------------------------------------------------------

## ✨ Features

-   🔍 **Auto-detects Flutter projects** in any folder\
-   🧼 **One-click `flutter clean`** for all or individual projects\
-   🧠 **Deep Clean mode** removes `ios/Pods` for extra space\
-   🕒 **Auto-clean scheduler** --- runs every *N* days using macOS
    Launchd\
-   📁 **Reveal in Finder** for quick access to project folders\
-   📊 **Live summary and inline logs** of all cleaning activity\
-   ⚡ **Smart search** to find projects instantly\
-   🧠 **Persistent settings** --- remembers your preferences between
    launches

------------------------------------------------------------------------

## 🖼️ Screenshots

  -------------------------------------------------------------------------------------------------------
  Main Window                         Settings                        Logs
  ----------------------------------- ------------------------------- -----------------------------------
  ![](./FlutterCleaner/Screenshots/cleaner_main.png)   ![](./FlutterCleaner/Screenshots/settings.png)   ![](./FlutterCleaner/Screenshots/logs_preview.png)

  -------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

## 🔐 Permissions

Flutter Cleaner requires **Full Disk Access** to scan your home directory.
Grant access via:

> System Settings → Privacy & Security → Full Disk Access → Add "Flutter Cleaner"

## 🧩 How It Works

Flutter Cleaner scans folders recursively to find any project containing
a `pubspec.yaml` file with a `flutter:` section.\
When cleaning, it runs:

``` bash
flutter clean
```

Optionally, if **Deep Clean** is enabled, it also removes:

    ios/Pods

------------------------------------------------------------------------

## ⚙️ Build Instructions

### 1️⃣ Clone the project

``` bash
git clone https://github.com/mrowl/flutter-cleaner.git
cd FlutterCleaner
```

### 2️⃣ Open in Xcode

``` bash
open FlutterCleaner.xcodeproj
```

### 3️⃣ Build and run

Select the **"My Mac"** target and hit ▶️ Run.

------------------------------------------------------------------------

## 🧠 Developer Features

-   Settings are stored using `@AppStorage` (per-user persistence)
-   Logging via `~/Library/Logs/FlutterCleaner.log`
-   Auto-clean scheduling uses **Launchd agents**
-   Optional notifications via `UserNotifications.framework`
-   Supports custom schedule intervals (every N days)

------------------------------------------------------------------------

## 📦 Folder Structure

    FlutterCleaner/
    ├── FlutterCleaner.xcodeproj
    ├── FlutterCleaner/          # App source (SwiftUI)
    │   ├── Models/
    │   ├── Views/
    │   ├── Helpers/
    │   └── FlutterCleanerApp.swift
    ├── Screenshots/
    ├── Assets/
    ├── README.md
    └── LICENSE

------------------------------------------------------------------------

## 💡 Notes

-   Compatible with macOS 13 Ventura and later
-   Requires Flutter installed and accessible via your PATH

------------------------------------------------------------------------


