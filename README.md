# Ganga Agri Genetics procurement app

A first-stage offline-first crop procurement and weighment app for Android, built with Flutter and Dart. It includes a Telugu/English interface, mobile-number farmer lookup, manual bag-by-bag weighing, slip photo capture, offline saving, and CSV export.

## Free tools and current setup

- Flutter and Dart for the mobile app.
- SQLite on Android and browser storage for the web preview.
- ASP.NET Core on .NET 10 for the planned sync API.
- Microsoft SQL Server 2022 is the local database target; the API project includes the Microsoft SQL Server driver.
- Open-source packages are restored from pub.dev and NuGet.

The Android SDK, Java, Flutter SDK, .NET SDK, Gradle cache, and other downloaded build tools are stored in the local `.tools/` folder and are intentionally excluded from GitHub. No farmer records or APK build outputs are included in this repository.

## Current limitations

- Weighments are saved on the device. The pending-sync label is local only; API sync is not implemented yet.
- The API is still a starter scaffold. SQL Server schema, connection setup, batch sync, and the office web view are not implemented yet.
- Worker login and individual worker identity are not implemented.
- Commercial deductions, rates, and payment rules are intentionally not implemented.

## Run the web preview

Open PowerShell in `ganga_procurement` and run:

```powershell
..\.tools\flutter\bin\flutter.bat run -d chrome
```

## Build the Android debug APK

From the app folder, use the Flutter SDK in `.tools/` and the Android SDK configured for this computer. The generated APK is written under `ganga_procurement/build/app/outputs/flutter-apk/`; that build output is excluded from GitHub.

## Repository contents

- `ganga_procurement/` — Flutter app and tests.
- `backend/GangaAgri.Api/` — ASP.NET Core API starter project.
- `.tools/` — local tools and caches; not tracked.
