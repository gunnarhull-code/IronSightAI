---
name: ironsight-windows-run
description: >-
  Launch IronSight on Windows with Brave via CHROME_EXECUTABLE, or use web-server
  on Cloud/Linux. Use when running the app on Windows, Brave, Chrome device, or web-server.
---

# IronSight Windows / Brave run

Canonical detail: `docs/DEVELOPER_WORKFLOW.md` → Windows development + Brave browser launch.

## Windows (founder machine)

```powershell
git checkout <branch-name>
git pull
flutter clean
flutter pub get
$env:CHROME_EXECUTABLE="C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
flutter run -d chrome
```

Adjust Brave path if installed elsewhere.

## Cloud Agent / Linux

Prefer:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

First Flutter web debug load may be blank for ~15–30s; wait or refresh once.
