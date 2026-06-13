# Map Detail Sheets Design

**Date:** 2026-06-13
**Track:** maps-geospatial (Task 6–7)
**Scope:** Bottom sheet detail views triggered by tapping gym or buddy markers on the map.

## Goal

When a user taps a gym or buddy marker on the map, a bottom sheet slides up showing relevant details and a contextual action button — without leaving the map.

## Architecture

### Tap Handling

`GymMarker` and `BuddyMarker` widgets are wrapped in a `GestureDetector` at the `Marker.child` level inside `MapScreen`. Taps call two private methods on `_MapScreenState`:

- `_onGymTap(GymModel)` — calls `showModalBottomSheet` with `GymDetailSheet`
- `_onBuddyTap(BuddyAvailabilityModel)` — calls `showModalBottomSheet` with `BuddyDetailSheet`

No new state is added to `_MapScreenState`. The bottom sheet manages its own lifecycle.

### GymDetailSheet

Receives a `GymModel`. Displays:

- Gym name (headline style)
- Address (body text, max 2 lines)
- Distance (e.g. "1.2 km away")
- "Get Directions" button — launches `geo:lat,lng?q=name` via `url_launcher`

### BuddyDetailSheet

Receives a `BuddyAvailabilityModel`. Displays:

- Workout types as a chip row (e.g. "Strength", "Cardio")
- Availability window (e.g. "Available until 6:00 PM")
- Distance (e.g. "0.8 km away")
- "Send Match Request" button — `ElevatedButton` with `onPressed: null` (disabled) and a `Tooltip("Coming soon")`

Both sheets use a `DragHandle` at the top, `padding: EdgeInsets.all(16)`, and are non-scrollable (data volume is small).

## Dependencies

- Add `url_launcher` to `pubspec.yaml`
- Add `<queries>` intent filter for `geo:` scheme in `AndroidManifest.xml`

## Testing

- `GymDetailSheet` widget test: name/address/distance render correctly; "Get Directions" triggers launcher
- `BuddyDetailSheet` widget test: workout chips render; available time formats correctly; match request button is disabled; tooltip appears on long-press

No new integration tests needed — no business logic beyond UI + url_launcher.

## Out of Scope

- Match request backend API (tracked in realtime-chat Task 1–2)
- Full buddy profile screen
- Gym verification status or ratings
