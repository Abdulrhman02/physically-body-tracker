# Body Tracker

A Flutter app to track body composition (circumference measurements, weight,
InBody 270 scans) and **export an LLM-ready prompt** containing all your
data + your goal, so any LLM (Claude, ChatGPT, Gemini, Llama, local models)
can act as your coach.

## Features

### 📐 Body tab
Custom-painted silhouette with 13 tappable measurement points (neck,
shoulders, chest, biceps, forearms, waist, hips, thighs, calves). Tap any
label to log a new value; you'll see that part's full history chart inline
and a list of recent entries with delete. Latest value + delta-vs-previous
are rendered right next to the body, aktiBODY-style. Summary tiles below
show current weight, muscle mass, body fat %, and BMI.

### ⚖️ Weight tab
Fast weight logging, headline current-weight card with delta since first
entry, full-history line chart, timeline of all entries.

### 📊 InBody tab
One-tap CSV import for the standard InBody 270 export (the
`Date,Measurement device.,Weight(kg),Skeletal Muscle Mass(kg),Body Fat Mass(kg),BMI(kg/m²),...`
format, 44 columns). Each scan is deduplicated by timestamp. Imported
weights are also seeded into the Weight log automatically.

Displays: latest scan stat-grid (weight, muscle, fat, PBF, BMI, BMR,
visceral fat, TBW, InBody score, WHR) + trend charts for each core
metric + full list of all scans with delete.

### 🤖 Prompt tab (the headline feature)
Builds a structured Markdown prompt that packages:
- Your profile (age, sex, height, activity level, notes)
- Your goal + target weight / body fat / date
- Last N InBody scans as a Markdown table
- Period deltas (how weight, muscle, fat, etc. changed)
- Latest segmental lean/fat breakdown (arms, trunk, legs)
- Recent weight log
- All circumferences with latest value, change-since-previous, and
  change-since-first entries
- An explicit 5-point set of questions for the LLM

Then:
- **Live preview** with character count
- **Copy to clipboard** → paste into any chat LLM
- **Share** → send via any app (Mail, Telegram, WhatsApp, Drafts, etc.)
- Controls: how many recent scans / weights to include, whether to include
  segmental breakdown and circumferences (to keep prompt small or verbose)

### ⚙️ Settings tab
Profile editor (name, age, sex, height, activity level, notes for the
coach) + destructive "delete all tracked data" option.

## Setup

```bash
cd body_tracker
flutter create . --project-name body_tracker --org com.example
flutter pub get
flutter run
```

On first run:
1. Go to **Settings** → fill in profile (height + age at minimum).
2. Go to **InBody** → tap *Import InBody CSV* → pick your export.
3. Go to **Prompt** → tap *Edit* on the Goal card → set your goal and
   targets.
4. Tap *Copy* and paste into any LLM.

## Architecture

- **Persistence:** SQLite via `sqflite` for measurements, weights, InBody
  scans. `SharedPreferences` for the user profile / goal. Everything is
  on-device.
- **CSV parsing:** `csv` package; handles the InBody timestamp format
  `YYYYMMDDhhmmss` and the `-` / `Etc` null sentinels.
- **Charts:** `fl_chart`.
- **Prompt builder:** pure Dart service (`services/prompt_builder.dart`)
  that produces Markdown. Testable, LLM-agnostic.
- **Sharing:** `share_plus` + `Clipboard`.

## File map

```
lib/
├── main.dart
├── theme/app_theme.dart
├── models/models.dart              BodyPart, Measurement, WeightEntry, InBodyScan, UserProfile
├── services/
│   ├── database_service.dart       sqflite CRUD
│   ├── profile_service.dart        prefs-backed profile
│   ├── csv_import_service.dart     InBody CSV -> DB
│   └── prompt_builder.dart         data -> Markdown LLM prompt
├── screens/
│   ├── body_screen.dart
│   ├── weight_screen.dart
│   ├── inbody_screen.dart
│   ├── prompt_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── body_diagram.dart           CustomPainter silhouette with anchors
    └── trend_chart.dart            fl_chart wrapper
```

## Example exported prompt (abridged)

```
You are an expert body-composition and fitness coach.
I will share my profile, my goal, and a snapshot of my body composition
history (from InBody 270 scans), my weight log, and my circumference
measurements. Please:
  1. Summarize the trends you see...
  2. Tell me whether I am on track...
  3. Recommend a concrete plan...
  4. Flag any concerning patterns...
  5. Tell me what to track next...

## My profile
- Age: 34
- Sex: male
- Height: 178 cm

## My goal
- Primary goal: Lose body fat while preserving muscle
- Target weight: 82 kg
- Target body fat: 18%
- Target date: 2026-09-01

## InBody composition history (last 10 scans, spanning 158 days)
| Date | Weight kg | SMM kg | BFM kg | PBF % | BMI | Visc | TBW L | Score |
|------|-----------|--------|--------|-------|-----|------|-------|-------|
| 2025-11-29 | 84.1 | 34.8 | 23.2 | 27.5 | 29.1 | 9 | 44.7 | 74 |
| 2026-02-02 | 88.0 | 34.6 | 27.1 | 30.8 | 30.4 | 11 | 44.7 | 71 |
...

### Change across this period
- Weight: 84.1 → 92.0 kg (+7.9 kg)
- Skeletal Muscle Mass: 34.8 → 35.2 kg (+0.4 kg)
- Body Fat Mass: 23.2 → 30.3 kg (+7.1 kg)
...

## Body circumference measurements (cm)
| Body part | Latest | Previous | Change | First | Total change |
...

## My question for you
Please analyze the data above and respond following the 5 points I listed
at the top...
```

The point: the LLM sees numbers, not handwaving — so its advice is grounded
in your actual trajectory.
