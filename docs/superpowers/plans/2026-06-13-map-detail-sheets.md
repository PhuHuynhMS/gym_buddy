# Map Detail Sheets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a bottom sheet with gym/buddy details and action buttons when a user taps a marker on the map.

**Architecture:** Wrap each `GymMarker`/`BuddyMarker` in a `GestureDetector` inside `MapScreen`; tap calls `showModalBottomSheet` with `GymDetailSheet` or `BuddyDetailSheet`. Both sheets are pure display widgets — `GymDetailSheet` accepts an `onGetDirections` callback (injected for testability), `BuddyDetailSheet` has a permanently-disabled match button.

**Tech Stack:** Flutter, `url_launcher ^6.3.0`, `flutter_test`

---

## File Map

| Action | Path |
|--------|------|
| Modify | `gym_buddy_app/pubspec.yaml` |
| Modify | `gym_buddy_app/android/app/src/main/AndroidManifest.xml` |
| Create | `gym_buddy_app/lib/features/maps/presentation/widgets/gym_detail_sheet.dart` |
| Create | `gym_buddy_app/lib/features/maps/presentation/widgets/buddy_detail_sheet.dart` |
| Modify | `gym_buddy_app/lib/features/maps/presentation/map_screen.dart` |
| Create | `gym_buddy_app/test/features/maps/presentation/widgets/gym_detail_sheet_test.dart` |
| Create | `gym_buddy_app/test/features/maps/presentation/widgets/buddy_detail_sheet_test.dart` |

---

## Task 1: Add `url_launcher` dependency and Android `geo:` query intent

**Files:**
- Modify: `gym_buddy_app/pubspec.yaml`
- Modify: `gym_buddy_app/android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add `url_launcher` to pubspec.yaml**

In `pubspec.yaml`, under `dependencies:`, add after `path_provider`:

```yaml
  url_launcher: ^6.3.0
```

- [ ] **Step 2: Add `geo:` query intent to AndroidManifest.xml**

In `android/app/src/main/AndroidManifest.xml`, add a second `<intent>` inside the existing `<queries>` block (after the `PROCESS_TEXT` intent):

```xml
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="geo"/>
        </intent>
    </queries>
```

- [ ] **Step 3: Fetch packages**

```bash
cd gym_buddy_app && flutter pub get
```

Expected: resolves `url_launcher` with no errors.

- [ ] **Step 4: Commit**

```bash
git add gym_buddy_app/pubspec.yaml gym_buddy_app/pubspec.lock gym_buddy_app/android/app/src/main/AndroidManifest.xml
git commit -m "chore(maps): add url_launcher and geo intent query"
```

---

## Task 2: GymDetailSheet widget (TDD)

**Files:**
- Create: `gym_buddy_app/lib/features/maps/presentation/widgets/gym_detail_sheet.dart`
- Create: `gym_buddy_app/test/features/maps/presentation/widgets/gym_detail_sheet_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `gym_buddy_app/test/features/maps/presentation/widgets/gym_detail_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/features/maps/data/models/gym_model.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/gym_detail_sheet.dart';

GymModel _gym() => GymModel(
      id: '1',
      name: 'Iron Paradise',
      address: '123 Main St, Ho Chi Minh City',
      lat: 10.7769,
      lng: 106.7009,
      distanceKm: 1.2,
    );

void main() {
  group('GymDetailSheet', () {
    testWidgets('shows gym name', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: GymDetailSheet(gym: _gym())),
      ));
      expect(find.text('Iron Paradise'), findsOneWidget);
    });

    testWidgets('shows address', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: GymDetailSheet(gym: _gym())),
      ));
      expect(find.text('123 Main St, Ho Chi Minh City'), findsOneWidget);
    });

    testWidgets('shows formatted distance', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: GymDetailSheet(gym: _gym())),
      ));
      expect(find.text('1.2 km away'), findsOneWidget);
    });

    testWidgets('Get Directions button calls onGetDirections', (tester) async {
      var called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GymDetailSheet(
            gym: _gym(),
            onGetDirections: () => called = true,
          ),
        ),
      ));
      await tester.tap(find.text('Get Directions'));
      expect(called, isTrue);
    });

    testWidgets('drag handle is present', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: GymDetailSheet(gym: _gym())),
      ));
      expect(find.byType(DragHandle), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd gym_buddy_app && flutter test test/features/maps/presentation/widgets/gym_detail_sheet_test.dart
```

Expected: compilation error — `GymDetailSheet` not defined.

- [ ] **Step 3: Implement GymDetailSheet**

Create `gym_buddy_app/lib/features/maps/presentation/widgets/gym_detail_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gym_buddy_app/features/maps/data/models/gym_model.dart';

class GymDetailSheet extends StatelessWidget {
  const GymDetailSheet({
    required this.gym,
    this.onGetDirections,
    super.key,
  });

  final GymModel gym;
  final VoidCallback? onGetDirections;

  Future<void> _launchDirections() async {
    final uri = Uri(
      scheme: 'geo',
      path: '${gym.lat},${gym.lng}',
      queryParameters: {'q': gym.name},
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: DragHandle()),
          const SizedBox(height: 12),
          Text(
            gym.name,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            gym.address,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${gym.distanceKm.toStringAsFixed(1)} km away',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onGetDirections ?? _launchDirections,
              icon: const Icon(Icons.directions),
              label: const Text('Get Directions'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd gym_buddy_app && flutter test test/features/maps/presentation/widgets/gym_detail_sheet_test.dart
```

Expected: all 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add gym_buddy_app/lib/features/maps/presentation/widgets/gym_detail_sheet.dart \
        gym_buddy_app/test/features/maps/presentation/widgets/gym_detail_sheet_test.dart
git commit -m "feat(maps): add GymDetailSheet with directions action"
```

---

## Task 3: BuddyDetailSheet widget (TDD)

**Files:**
- Create: `gym_buddy_app/lib/features/maps/presentation/widgets/buddy_detail_sheet.dart`
- Create: `gym_buddy_app/test/features/maps/presentation/widgets/buddy_detail_sheet_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `gym_buddy_app/test/features/maps/presentation/widgets/buddy_detail_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/features/maps/data/models/buddy_availability_model.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/buddy_detail_sheet.dart';

BuddyAvailabilityModel _buddy() => BuddyAvailabilityModel(
      id: 'b1',
      userId: 'u1',
      lat: 10.7769,
      lng: 106.7009,
      distanceKm: 0.8,
      workoutTypes: ['Strength', 'Cardio'],
      availableUntil: DateTime(2026, 6, 13, 18, 0),
    );

void main() {
  group('BuddyDetailSheet', () {
    testWidgets('shows each workout type as a chip', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BuddyDetailSheet(buddy: _buddy())),
      ));
      expect(find.widgetWithText(Chip, 'Strength'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Cardio'), findsOneWidget);
    });

    testWidgets('shows formatted available until time', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BuddyDetailSheet(buddy: _buddy())),
      ));
      expect(find.text('Available until 6:00 PM'), findsOneWidget);
    });

    testWidgets('shows formatted distance', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BuddyDetailSheet(buddy: _buddy())),
      ));
      expect(find.text('0.8 km away'), findsOneWidget);
    });

    testWidgets('Send Match Request button is disabled', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BuddyDetailSheet(buddy: _buddy())),
      ));
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('tooltip shows Coming soon on long-press', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BuddyDetailSheet(buddy: _buddy())),
      ));
      await tester.longPress(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Coming soon'), findsOneWidget);
    });

    testWidgets('drag handle is present', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BuddyDetailSheet(buddy: _buddy())),
      ));
      expect(find.byType(DragHandle), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd gym_buddy_app && flutter test test/features/maps/presentation/widgets/buddy_detail_sheet_test.dart
```

Expected: compilation error — `BuddyDetailSheet` not defined.

- [ ] **Step 3: Implement BuddyDetailSheet**

Create `gym_buddy_app/lib/features/maps/presentation/widgets/buddy_detail_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:gym_buddy_app/features/maps/data/models/buddy_availability_model.dart';

class BuddyDetailSheet extends StatelessWidget {
  const BuddyDetailSheet({required this.buddy, super.key});

  final BuddyAvailabilityModel buddy;

  String _formatTime(DateTime dt) {
    final time = TimeOfDay.fromDateTime(dt);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: DragHandle()),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: buddy.workoutTypes
                .map((type) => Chip(label: Text(type)))
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Available until ${_formatTime(buddy.availableUntil)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${buddy.distanceKm.toStringAsFixed(1)} km away',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Tooltip(
            message: 'Coming soon',
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.person_add),
                label: const Text('Send Match Request'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd gym_buddy_app && flutter test test/features/maps/presentation/widgets/buddy_detail_sheet_test.dart
```

Expected: all 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add gym_buddy_app/lib/features/maps/presentation/widgets/buddy_detail_sheet.dart \
        gym_buddy_app/test/features/maps/presentation/widgets/buddy_detail_sheet_test.dart
git commit -m "feat(maps): add BuddyDetailSheet with disabled match request"
```

---

## Task 4: Wire tap handlers in MapScreen

**Files:**
- Modify: `gym_buddy_app/lib/features/maps/presentation/map_screen.dart`

- [ ] **Step 1: Add imports and tap handler methods**

At the top of `map_screen.dart`, add the two new imports after the existing widget imports:

```dart
import 'package:gym_buddy_app/features/maps/presentation/widgets/buddy_detail_sheet.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/gym_detail_sheet.dart';
```

Add these two methods to `_MapScreenState` (after the `_load` method, before `build`):

```dart
void _onGymTap(GymModel gym) {
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => GymDetailSheet(gym: gym),
  );
}

void _onBuddyTap(BuddyAvailabilityModel buddy) {
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => BuddyDetailSheet(buddy: buddy),
  );
}
```

- [ ] **Step 2: Wrap GymMarker with GestureDetector**

In `_MapScreenState.build`, locate the `MarkerLayer` for gyms (the one guarded by `if (_showGyms)`). Replace the `child: const GymMarker()` with a tappable version:

```dart
if (_showGyms)
  MarkerLayer(
    markers: _gyms
        .map(
          (gym) => Marker(
            point: LatLng(gym.lat, gym.lng),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _onGymTap(gym),
              child: const GymMarker(),
            ),
          ),
        )
        .toList(),
  ),
```

- [ ] **Step 3: Wrap BuddyMarker with GestureDetector**

Locate the `MarkerLayer` for buddies (guarded by `if (_showBuddies)`). Replace `child: const BuddyMarker()`:

```dart
if (_showBuddies)
  MarkerLayer(
    markers: _buddies
        .map(
          (buddy) => Marker(
            point: LatLng(buddy.lat, buddy.lng),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () => _onBuddyTap(buddy),
              child: const BuddyMarker(),
            ),
          ),
        )
        .toList(),
  ),
```

- [ ] **Step 4: Run the full test suite**

```bash
cd gym_buddy_app && flutter test
```

Expected: all tests pass (no regressions).

- [ ] **Step 5: Commit**

```bash
git add gym_buddy_app/lib/features/maps/presentation/map_screen.dart
git commit -m "feat(maps): wire tap handlers to show gym and buddy detail sheets"
```

---

## Task 5: Update conductor track

**Files:**
- Modify: `conductor/tracks/maps-geospatial/plan.md`

- [ ] **Step 1: Mark Tasks 6 and 7 complete**

In `conductor/tracks/maps-geospatial/plan.md`, update:

```markdown
- [x] Task 6: Render custom markers for gyms and buddies in Flutter.
- [x] Task 7: Build gym and buddy detail views from map selections.
```

- [ ] **Step 2: Update track metadata status**

In `conductor/tracks/maps-geospatial/metadata.json`, update `status` and `updated`:

```json
{
  "id": "maps-geospatial",
  "type": "feature",
  "status": "complete",
  "created": "2026-05-03",
  "updated": "2026-06-13",
  "owner": "backend-and-flutter"
}
```

- [ ] **Step 3: Mark track complete in tracks.md**

In `conductor/tracks.md`, update the maps-geospatial line:

```markdown
- [x] maps-geospatial - Location permissions, maps UI, and nearby gym/buddy APIs.
```

- [ ] **Step 4: Commit**

```bash
git add conductor/tracks/maps-geospatial/plan.md \
        conductor/tracks/maps-geospatial/metadata.json \
        conductor/tracks.md
git commit -m "chore(conductor): mark maps-geospatial track complete"
```
