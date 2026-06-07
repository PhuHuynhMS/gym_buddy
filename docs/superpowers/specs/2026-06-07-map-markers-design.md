# Map Markers Design — Task 6: Render Custom Markers for Gyms and Buddies

**Date:** 2026-06-07  
**Track:** maps-geospatial  
**Scope:** Flutter data layer + full-screen map with gym and buddy markers

---

## Overview

Add a dedicated Map tab to the app that fetches nearby gyms and buddy availabilities and renders them as custom circle markers on a full-screen OpenStreetMap view. Users can toggle each marker type independently via chip filters.

---

## Architecture

### Directory Structure

```
gym_buddy_app/lib/features/maps/
├── data/
│   ├── models/
│   │   ├── gym_model.dart
│   │   └── buddy_availability_model.dart
│   ├── gym_repository.dart
│   └── buddy_repository.dart
└── presentation/
    ├── map_screen.dart
    ├── map_preview_panel.dart         (unchanged)
    └── widgets/
        ├── gym_marker.dart
        ├── buddy_marker.dart
        └── map_filter_chips.dart
```

`MapPreviewPanel` remains in the Home tab unchanged. `MapScreen` is the new full-screen map that powers the Map tab.

---

## Data Layer

### Models

**GymModel** — maps from `GET /api/v1/gyms/nearby` response item:

| Field | Type | Source |
|---|---|---|
| `id` | `String` | `_id` |
| `name` | `String` | `name` |
| `address` | `String` | `address` |
| `lat` | `double` | `location.coordinates[1]` |
| `lng` | `double` | `location.coordinates[0]` |
| `distanceKm` | `double` | `distanceKm` |

**BuddyAvailabilityModel** — maps from `GET /api/v1/buddies/nearby` response item:

| Field | Type | Source |
|---|---|---|
| `id` | `String` | `_id` |
| `userId` | `String` | `userId` |
| `lat` | `double` | `location.coordinates[1]` |
| `lng` | `double` | `location.coordinates[0]` |
| `distanceKm` | `double` | `distanceKm` |
| `workoutTypes` | `List<String>` | `workoutTypes` |
| `availableUntil` | `DateTime` | `availableUntil` |

### Repositories

Both repositories receive a `Dio` instance via constructor for testability.

```dart
class GymRepository {
  GymRepository(this._dio);
  final Dio _dio;

  Future<List<GymModel>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limit = 20,
  });
}

class BuddyRepository {
  BuddyRepository(this._dio);
  final Dio _dio;

  Future<List<BuddyAvailabilityModel>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limit = 20,
  });
}
```

Default fetch parameters: **5km radius, 20 results**.

---

## UI Layer

### MapScreen State

```dart
List<GymModel> _gyms = [];
List<BuddyAvailabilityModel> _buddies = [];
bool _showGyms = true;
bool _showBuddies = true;
bool _isLoading = false;
String? _errorMessage;
```

### Data Fetching

On location available and on manual refresh, fetch both in parallel:

```dart
final results = await Future.wait([
  _gymRepository.getNearby(lat: lat, lng: lng),
  _buddyRepository.getNearby(lat: lat, lng: lng),
]);
```

If one fails, the other's results still display. Error shown in non-blocking status bar.

### Marker Widgets

**GymMarker** — 40×40px circle, fill `#4F8EF7` (blue), icon `Icons.fitness_center` white 20px, glow ring 5px opacity 25%.

**BuddyMarker** — 40×40px circle, fill `#F76F4F` (orange), icon `Icons.people` white 20px, same glow ring.

**User location marker** — reuses existing `Icons.my_location` from `MapPreviewPanel`.

### Filter Chips

Positioned at top-center over the map. Two chips: **Gyms** and **Buddies**.

- Active: filled with marker color, white label
- Inactive: outlined, muted label
- Tap toggles `_showGyms` / `_showBuddies` via `setState` — no refetch

### flutter_map Layer Order

```
FlutterMap children:
  1. TileLayer          — OSM tiles
  2. MarkerLayer        — gym markers (if _showGyms)
  3. MarkerLayer        — buddy markers (if _showBuddies)
  4. MarkerLayer        — user location (always visible)
```

### Navigation

`HomeScreen` gains a `BottomNavigationBar` with two tabs:

| Index | Label | Content |
|---|---|---|
| 0 | Home | Existing content with `MapPreviewPanel` |
| 1 | Map | `MapScreen` (full-screen) |

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Location unavailable | Fallback center (HCMC), fetch disabled, message shown |
| Gyms API fails | Show buddy markers only, error in status bar |
| Buddies API fails | Show gym markers only, error in status bar |
| Both APIs fail | Empty map, error message, Refresh button |

---

## Out of Scope (Task 7)

- Tap marker → detail bottom sheet
- Navigation to gym/buddy profile screen
