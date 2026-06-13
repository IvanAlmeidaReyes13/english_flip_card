# Flip Card Learn

Flutter app for practicing English vocabulary with swipeable flashcards.

Production: [https://web-chi-nine-90.vercel.app](https://web-chi-nine-90.vercel.app)

## What It Does

Flip Card Learn is a small local-first vocabulary app:

- Create English/Spanish flashcards manually.
- Practice cards with Tinder-style swipes.
- Tap a card to flip it.
- Swipe right when you know it.
- Swipe left when you need to review it.
- Track a simple knowledge percentage per card.
- Import AI-generated vocabulary from JSON.
- Copy an AI prompt template to generate valid import JSON.

The app stores data locally with Hive. On web, Hive uses browser storage, so cards are saved in that browser and domain.

## Practice Flow

The practice screen shows one card at a time.

- Front side: prompt text.
- Back side: answer text, notes, and knowledge level.
- `Lo sé`: increases knowledge.
- `Repasar`: decreases knowledge.
- Once every card has appeared once, the session ends.

Cards with `knowledgeLevel >= 50` and `< 100` are shown in reverse mode:

- Normal mode: English -> Spanish.
- Reverse mode: Spanish -> English.
- Reverse cards show a small `ES -> EN` badge.

This makes stronger cards harder by asking you to produce the English answer instead of only recognizing it.

## Card Vault

The `Mis Tarjetas` screen lets you:

- See all saved cards.
- Add a new card.
- Edit an existing card.
- Delete a card.
- Copy the AI import template.
- Import JSON from the clipboard.

## AI JSON Import

The app does not call an AI provider directly. Instead:

1. Open `Mis Tarjetas`.
2. Open the three-dot menu.
3. Tap `Copy AI template`.
4. Paste that prompt into ChatGPT, Codex, or another AI tool with your notes, screenshots, vocabulary list, or source text.
5. Copy the JSON response.
6. Return to the app.
7. Open `Mis Tarjetas` -> three-dot menu.
8. Tap `Import JSON from clipboard`.

Expected JSON format:

```json
{
  "version": 1,
  "source": "ai-generated",
  "cards": [
    {
      "english": "show up",
      "meaning": "aparecer / presentarse",
      "example": "My teacher didn't show up.",
      "notes": "Common phrasal verb."
    }
  ]
}
```

Import rules:

- `cards` must be an array.
- `english` and `meaning` are required.
- `example` and `notes` are optional.
- Unknown fields are ignored.
- Invalid cards are skipped.
- Duplicate cards are skipped.
- Duplicates are detected by normalized English text plus normalized Spanish meaning.

After import, the app shows a summary:

```text
Imported: 24 · Duplicates: 3 · Invalid: 2
```

## Local Storage

The app uses Hive:

- Mobile/desktop: local app storage.
- Web: browser storage, normally IndexedDB.

Important web behavior:

- Data is local to the browser.
- Data is local to the domain/origin.
- `localhost:8080`, `localhost:8081`, and production are separate storage origins.
- Clearing site data can delete cards.
- There is no sync between devices.

For portability, use JSON import/export-style workflows. Import exists now; export is a natural next feature.

## Development

Install dependencies:

```bash
flutter pub get
```

Run locally:

```bash
flutter run
```

Run on web:

```bash
flutter run -d chrome
```

Analyze:

```bash
flutter analyze
```

Test:

```bash
flutter test
```

Build web:

```bash
flutter build web --release
```

The web build is generated at:

```text
build/web
```

## Deployment

This app is deployed as a static Flutter web build on Vercel.

Current deployment:

[https://web-chi-nine-90.vercel.app](https://web-chi-nine-90.vercel.app)

Manual deployment flow:

```bash
flutter build web --release
vercel deploy --prod build/web --yes
```

The file `web/vercel.json` is copied into `build/web` during Flutter builds and configures Vercel to serve the app as a single-page app:

```json
{
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

## Notes

- The Flutter package name must remain a valid Dart identifier in `pubspec.yaml`.
- The visible app name should be changed in platform config, not by setting a spaced `pubspec.yaml` package name.
- Hive files should not be edited directly. Use app flows or JSON import/export.
