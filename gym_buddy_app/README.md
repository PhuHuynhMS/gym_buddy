# GymBuddy App

Flutter client for GymBuddy Connect. Android-first.

See the [root README](../README.md) for full project documentation, API reference, and setup instructions.

## Run

```bash
flutter pub get
flutter run
```

## Structure

```
lib/
  app/            # Entry point, theme, bootstrap gate
  core/
    config/       # Environment config
    network/      # Dio factory, HTTPS trust shim
    session/      # Token interceptor, secure store, cookie jar
    device/       # Device info provider
  features/
    auth/         # Login, register, sessions — data/domain/presentation
    location/     # Location permission handling
    maps/         # Map preview panel
    home/         # Home screen
```
