# Cricket Scorer App (Flutter)

A local Flutter app for scoring a full cricket match ball-by-ball.
 
## Features
- Match setup with team names and up to 11 players per team.
- Toss winner and toss decision (batting/bowling).
- Overs selection per innings.
- Live scoring with:
  - striker / non-striker / bowler selectors
  - runs off bat
  - extras (wide, no-ball, bye, leg-bye)
  - wickets and dismissal type
- Live score feed with per-ball event history.
- Match summary with:
  - innings scores
  - batting and bowling cards
  - run rate
  - over history with every ball
- Export/share match summary as PDF.
 
 ## Build Instructions
1. Install Flutter SDK.
2. Run `flutter pub get`.
3. Run `flutter run` for local testing.
4. Run `flutter build apk --release` to build APK.
 
 ## GitHub Actions
This repository includes workflows to build artifacts on push to `main` and `work` branches.

## APK Build (when local SDK setup is unavailable)
If you cannot install Flutter/Android SDK locally, push this repo to GitHub and run the **Build Flutter APK** workflow from the **Actions** tab. The generated APK is available in workflow artifacts and release assets.
