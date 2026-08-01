# BiteWise

BiteWise is a visual, suggestion-first Flutter app for learning about common bug-bite patterns, basic aftercare, and community experiences. It does **not** diagnose bites or replace professional medical care.

## What is included

- Image-led visual guides for common bites and insects
- Symptom and context filters that return possible matches
- Recovery guidance and clear urgent-care signals
- Optional community posts with a safety-first sharing flow
- Local sign-in/sign-up prototype and saved-guide state
- Material 3 design with accessible touch targets and adaptive Flutter layouts

## Safety boundary

BiteWise intentionally uses language such as “possible match” and “general suggestion.” It must not make a clinical diagnosis, assess poisoning, or delay urgent care. The app directs people to emergency care for severe allergic reactions, breathing trouble, rapidly worsening symptoms, or other urgent warning signs.

## Run locally

Install a current stable Flutter SDK, then run:

```bash
flutter pub get
flutter run
```

For the available Android emulator or device:

```bash
flutter devices
flutter run -d <device-id>
```

## Project layout

```text
lib/
  app/          Routing and app shell
  core/         Theme, reusable UI components, and platform services
  data/         Models and seeded visual guide content
  features/     Auth, home, explore, filter, community, and profile screens
  state/        Riverpod application state
assets/images/  Curated visual-guide artwork
test/           Widget smoke tests
```

## Production integration notes

- Keep the mobile client free of AI/API secrets. Send image analysis requests through an authenticated backend that owns rate limits, moderation, audit logs, model selection, and safety policies.
- Require consent before uploading user photos. Strip EXIF metadata, use short retention, and provide deletion controls.
- Add server-side authentication, persistence, moderation/reporting, and a medical-safety escalation policy before public launch.
- Treat community submissions as unverified user-generated content; show reporting and moderation states in production.
- The included Android gallery bridge downsizes a selected image in memory for the current local post. Before public launch, upload through a reviewed backend that strips metadata, moderates content, and supports deletion.

## Android release checklist

- Replace the starter Android application ID (`com.example.project_bugbite`) with a reverse-DNS identifier owned by your organization before creating a Play Store listing.
- Configure a secure release signing key and CI-managed signing credentials. The starter debug signing configuration is for development only.
- Set the production version in `pubspec.yaml`, verify Android adaptive icons and launch screens, and complete Google Play Data safety disclosures.
- Run the quality gates below before each release.

## Quality gates

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build appbundle --release
```
