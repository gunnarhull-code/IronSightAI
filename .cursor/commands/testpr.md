# testpr

Test GitHub PR #<PR_NUMBER> locally.

Perform these actions:

1. Verify the current working tree is clean.
2. If uncommitted changes exist, stop and show them. Do not discard anything.
3. Fetch the PR:
   `git fetch origin pull/<PR_NUMBER>/head`
4. Check out FETCH_HEAD in detached mode:
   `git switch --detach FETCH_HEAD`
5. Run:
   ```bash
   flutter clean
   flutter pub get
   dart format --output=none --set-exit-if-changed .
   dart run tool/verify_sprint_registry.dart
   flutter analyze
   flutter test
   ```
6. Compare the PR against `origin/main` and report whether it contains files under:
   `supabase/migrations/`
7. Do not apply migrations.
8. Launch the app using the correct host environment:

   **Windows (founder machine — Brave):**
   ```powershell
   $env:CHROME_EXECUTABLE="C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
   flutter run -d chrome
   ```

   **Linux / Cursor Cloud Agent:**
   Do **not** use the Windows Brave path. Prefer:
   ```bash
   flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
   ```
   If a local Chrome device is available and a remote desktop view is intended, `flutter run -d chrome` is acceptable, but `web-server` is preferred so the app is reachable at `http://0.0.0.0:8080` / forwarded port 8080.

9. Stop if formatting, sprint-registry validation, `flutter analyze`, or `flutter test` fails.

After launch, report:

- Current commit
- Formatting result
- Sprint-registry result
- flutter analyze result
- flutter test result
- Whether Supabase migrations exist
- Files changed compared with main
- A manual testing checklist specific to this PR
- Any blocking problems
- Which launch mode was used (`Brave/chrome` vs `web-server`) and the URL/port

Do not commit, push, merge, modify code, extract credentials, or access production.
