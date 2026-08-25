# 🍿 Popcorn Diary

Your movies. Your memories. A personal, visual-first cinema diary.

![Popcorns](assets/images/popcorn-diary-overview.png)

## 🚀 Getting Started

### Requirements

* Flutter 3.44.8+
* Dart 3.12.2+
* Android device or emulator

### Installation

Clone the repository:

```bash
git clone https://github.com/MaswiliK/popcorn-diary.git
cd popcorn-diary
```

Install dependencies:

```bash
flutter pub get
```

### TMDB token for local dev vs. releases

For day-to-day `flutter run`, either pass `--dart-define=TMDB_API_TOKEN=...`
directly, or use a file so you're not retyping it:

1. Create `config/tmdb.json` (already git-ignored — see `config/tmdb.example.json`
   for the shape):
```json
   { "TMDB_API_TOKEN": "your_actual_token_here" }
```
2. Run/build with `--dart-define-from-file` instead:
```bash
   flutter run --dart-define-from-file=config/tmdb.json
   flutter build apk --release --dart-define-from-file=config/tmdb.json
```

**Heads up on release builds:** this bakes the token into the APK. Anyone who decompiles the APK can extract it.

The generated APK can be found under:

```text
build/app/outputs/flutter-apk/app-release.apk
```