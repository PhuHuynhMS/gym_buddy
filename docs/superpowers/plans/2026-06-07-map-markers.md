# Map Markers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a full-screen Map tab to GymBuddy that fetches nearby gyms and buddies from the backend and renders them as distinct custom circle markers on an OpenStreetMap view, with chip toggles to filter each type.

**Architecture:** Two separate repositories (`GymRepository`, `BuddyRepository`) each receive a `Dio` instance via constructor and call existing backend endpoints. A new `MapScreen` StatefulWidget fetches both in parallel with `Future.wait`, renders gym markers (blue) and buddy markers (orange) on separate `MarkerLayer`s, and exposes chip toggles for client-side filtering. The screen is wired into `HomeScreen` via a `NavigationBar` with two tabs.

**Tech Stack:** Flutter, `flutter_map ^8.3.0`, `latlong2 ^0.9.1`, `geolocator ^14.0.2`, `dio ^5.8.0+1`, `http_mock_adapter ^0.6.1` (dev)

---

## File Map

| Action | Path | Responsibility |
|--------|------|---------------|
| Create | `lib/features/maps/data/models/gym_model.dart` | Parses gym JSON from `/gyms/nearby` |
| Create | `lib/features/maps/data/models/buddy_availability_model.dart` | Parses buddy JSON from `/buddies/nearby` |
| Create | `lib/features/maps/data/gym_repository.dart` | `GET /gyms/nearby` → `List<GymModel>` |
| Create | `lib/features/maps/data/buddy_repository.dart` | `GET /buddies/nearby` → `List<BuddyAvailabilityModel>` |
| Create | `lib/features/maps/presentation/widgets/gym_marker.dart` | Blue circle marker widget |
| Create | `lib/features/maps/presentation/widgets/buddy_marker.dart` | Orange circle marker widget |
| Create | `lib/features/maps/presentation/widgets/map_filter_chips.dart` | Gyms / Buddies toggle chips |
| Create | `lib/features/maps/presentation/map_screen.dart` | Full-screen map with fetch + markers |
| Modify | `lib/app/gym_buddy_app.dart` | Thread `gymRepository`, `buddyRepository` |
| Modify | `lib/app/bootstrap_gate.dart` | Thread repos to `HomeScreen` |
| Modify | `lib/features/home/home_screen.dart` | Add repos + `NavigationBar` |
| Modify | `lib/main.dart` | Instantiate and wire both repos |
| Modify | `test/widget_test.dart` | Add fake repos to `pumpAuthApp` |
| Create | `test/features/maps/data/models/gym_model_test.dart` | Unit tests for `GymModel.fromJson` |
| Create | `test/features/maps/data/models/buddy_availability_model_test.dart` | Unit tests for `BuddyAvailabilityModel.fromJson` |
| Create | `test/features/maps/data/gym_repository_test.dart` | Unit tests for `GymRepository` |
| Create | `test/features/maps/data/buddy_repository_test.dart` | Unit tests for `BuddyRepository` |
| Create | `test/features/maps/presentation/widgets/markers_test.dart` | Widget tests for `GymMarker`, `BuddyMarker` |
| Create | `test/features/maps/presentation/widgets/map_filter_chips_test.dart` | Widget tests for `MapFilterChips` |

All paths are relative to `gym_buddy_app/`.

---

## Task 1: GymModel

**Files:**
- Create: `gym_buddy_app/lib/features/maps/data/models/gym_model.dart`
- Create: `gym_buddy_app/test/features/maps/data/models/gym_model_test.dart`

- [ ] **Step 1.1: Write the failing tests**

Create `gym_buddy_app/test/features/maps/data/models/gym_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/features/maps/data/models/gym_model.dart';

void main() {
  const validJson = {
    '_id': 'gym1',
    'name': 'Iron Gym',
    'address': '123 Main St',
    'location': {
      'type': 'Point',
      'coordinates': [106.7009, 10.7769],
    },
    'distanceKm': 1.5,
  };

  test('fromJson parses all fields correctly', () {
    final gym = GymModel.fromJson(validJson);

    expect(gym.id, 'gym1');
    expect(gym.name, 'Iron Gym');
    expect(gym.address, '123 Main St');
    expect(gym.lng, 106.7009);
    expect(gym.lat, 10.7769);
    expect(gym.distanceKm, 1.5);
  });

  test('fromJson parses integer distanceKm as double', () {
    final json = {...validJson, 'distanceKm': 2};
    final gym = GymModel.fromJson(json);
    expect(gym.distanceKm, 2.0);
  });

  test('fromJson throws FormatException when _id is missing', () {
    final json = Map<String, dynamic>.from(validJson)..remove('_id');
    expect(() => GymModel.fromJson(json), throwsA(isA<FormatException>()));
  });

  test('fromJson throws FormatException when location is missing', () {
    final json = Map<String, dynamic>.from(validJson)..remove('location');
    expect(() => GymModel.fromJson(json), throwsA(isA<FormatException>()));
  });

  test('fromJson throws FormatException when coordinates is malformed', () {
    final json = {
      ...validJson,
      'location': {'type': 'Point', 'coordinates': [106.7009]},
    };
    expect(() => GymModel.fromJson(json), throwsA(isA<FormatException>()));
  });
}
```

- [ ] **Step 1.2: Run tests to verify they fail**

```
cd gym_buddy_app
flutter test test/features/maps/data/models/gym_model_test.dart
```

Expected: error — `gym_model.dart` does not exist.

- [ ] **Step 1.3: Implement GymModel**

Create `gym_buddy_app/lib/features/maps/data/models/gym_model.dart`:

```dart
class GymModel {
  const GymModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.distanceKm,
  });

  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double distanceKm;

  factory GymModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    if (location is! Map<String, dynamic>) {
      throw const FormatException('location is required');
    }
    final coordinates = location['coordinates'];
    if (coordinates is! List || coordinates.length < 2) {
      throw const FormatException(
          'location.coordinates must be [lng, lat] with at least 2 elements');
    }

    return GymModel(
      id: _str(json, '_id'),
      name: _str(json, 'name'),
      address: _str(json, 'address'),
      lng: _num(coordinates[0]),
      lat: _num(coordinates[1]),
      distanceKm: _num(json['distanceKm']),
    );
  }

  static String _str(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is String && v.isNotEmpty) return v;
    throw FormatException('$key is required');
  }

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    throw const FormatException('expected a number');
  }
}
```

- [ ] **Step 1.4: Run tests to verify they pass**

```
cd gym_buddy_app
flutter test test/features/maps/data/models/gym_model_test.dart
```

Expected: all 5 tests pass.

- [ ] **Step 1.5: Commit**

```
git add gym_buddy_app/lib/features/maps/data/models/gym_model.dart \
        gym_buddy_app/test/features/maps/data/models/gym_model_test.dart
git commit -m "feat(maps): add GymModel with fromJson parsing"
```

---

## Task 2: BuddyAvailabilityModel

**Files:**
- Create: `gym_buddy_app/lib/features/maps/data/models/buddy_availability_model.dart`
- Create: `gym_buddy_app/test/features/maps/data/models/buddy_availability_model_test.dart`

- [ ] **Step 2.1: Write the failing tests**

Create `gym_buddy_app/test/features/maps/data/models/buddy_availability_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/features/maps/data/models/buddy_availability_model.dart';

void main() {
  const validJson = {
    '_id': 'buddy1',
    'userId': 'user42',
    'location': {
      'type': 'Point',
      'coordinates': [106.7009, 10.7769],
    },
    'distanceKm': 0.8,
    'workoutTypes': ['strength', 'cardio'],
    'availableUntil': '2026-06-07T15:00:00.000Z',
  };

  test('fromJson parses all fields correctly', () {
    final buddy = BuddyAvailabilityModel.fromJson(validJson);

    expect(buddy.id, 'buddy1');
    expect(buddy.userId, 'user42');
    expect(buddy.lng, 106.7009);
    expect(buddy.lat, 10.7769);
    expect(buddy.distanceKm, 0.8);
    expect(buddy.workoutTypes, ['strength', 'cardio']);
    expect(buddy.availableUntil, DateTime.parse('2026-06-07T15:00:00.000Z'));
  });

  test('fromJson defaults workoutTypes to empty list when missing', () {
    final json = Map<String, dynamic>.from(validJson)..remove('workoutTypes');
    final buddy = BuddyAvailabilityModel.fromJson(json);
    expect(buddy.workoutTypes, isEmpty);
  });

  test('fromJson throws FormatException when _id is missing', () {
    final json = Map<String, dynamic>.from(validJson)..remove('_id');
    expect(
      () => BuddyAvailabilityModel.fromJson(json),
      throwsA(isA<FormatException>()),
    );
  });

  test('fromJson throws FormatException when availableUntil is missing', () {
    final json = Map<String, dynamic>.from(validJson)..remove('availableUntil');
    expect(
      () => BuddyAvailabilityModel.fromJson(json),
      throwsA(isA<FormatException>()),
    );
  });

  test('fromJson throws FormatException when availableUntil is not a valid date', () {
    final json = {...validJson, 'availableUntil': 'not-a-date'};
    expect(
      () => BuddyAvailabilityModel.fromJson(json),
      throwsA(isA<FormatException>()),
    );
  });

  test('fromJson throws FormatException when location is missing', () {
    final json = Map<String, dynamic>.from(validJson)..remove('location');
    expect(
      () => BuddyAvailabilityModel.fromJson(json),
      throwsA(isA<FormatException>()),
    );
  });
}
```

- [ ] **Step 2.2: Run tests to verify they fail**

```
cd gym_buddy_app
flutter test test/features/maps/data/models/buddy_availability_model_test.dart
```

Expected: error — `buddy_availability_model.dart` does not exist.

- [ ] **Step 2.3: Implement BuddyAvailabilityModel**

Create `gym_buddy_app/lib/features/maps/data/models/buddy_availability_model.dart`:

```dart
class BuddyAvailabilityModel {
  const BuddyAvailabilityModel({
    required this.id,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    required this.workoutTypes,
    required this.availableUntil,
  });

  final String id;
  final String userId;
  final double lat;
  final double lng;
  final double distanceKm;
  final List<String> workoutTypes;
  final DateTime availableUntil;

  factory BuddyAvailabilityModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    if (location is! Map<String, dynamic>) {
      throw const FormatException('location is required');
    }
    final coordinates = location['coordinates'];
    if (coordinates is! List || coordinates.length < 2) {
      throw const FormatException(
          'location.coordinates must be [lng, lat] with at least 2 elements');
    }

    final workoutTypesRaw = json['workoutTypes'];
    final workoutTypes =
        workoutTypesRaw is List ? workoutTypesRaw.cast<String>() : <String>[];

    final availableUntilRaw = json['availableUntil'];
    if (availableUntilRaw is! String) {
      throw const FormatException('availableUntil is required');
    }
    final availableUntil = DateTime.tryParse(availableUntilRaw);
    if (availableUntil == null) {
      throw const FormatException('availableUntil must be a valid ISO date');
    }

    return BuddyAvailabilityModel(
      id: _str(json, '_id'),
      userId: _str(json, 'userId'),
      lng: _num(coordinates[0]),
      lat: _num(coordinates[1]),
      distanceKm: _num(json['distanceKm']),
      workoutTypes: workoutTypes,
      availableUntil: availableUntil,
    );
  }

  static String _str(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is String && v.isNotEmpty) return v;
    throw FormatException('$key is required');
  }

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    throw const FormatException('expected a number');
  }
}
```

- [ ] **Step 2.4: Run tests to verify they pass**

```
cd gym_buddy_app
flutter test test/features/maps/data/models/buddy_availability_model_test.dart
```

Expected: all 6 tests pass.

- [ ] **Step 2.5: Commit**

```
git add gym_buddy_app/lib/features/maps/data/models/buddy_availability_model.dart \
        gym_buddy_app/test/features/maps/data/models/buddy_availability_model_test.dart
git commit -m "feat(maps): add BuddyAvailabilityModel with fromJson parsing"
```

---

## Task 3: GymRepository

**Files:**
- Modify: `gym_buddy_app/pubspec.yaml`
- Create: `gym_buddy_app/lib/features/maps/data/gym_repository.dart`
- Create: `gym_buddy_app/test/features/maps/data/gym_repository_test.dart`

- [ ] **Step 3.1: Add http_mock_adapter dev dependency**

In `gym_buddy_app/pubspec.yaml`, add under `dev_dependencies`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  http_mock_adapter: ^0.6.1
```

Then run:

```
cd gym_buddy_app
flutter pub get
```

Expected: resolves without error.

- [ ] **Step 3.2: Write the failing tests**

Create `gym_buddy_app/test/features/maps/data/gym_repository_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/core/errors/app_failure.dart';
import 'package:gym_buddy_app/features/maps/data/gym_repository.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late GymRepository repo;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://test.local/api/v1'));
    adapter = DioAdapter(dio: dio);
    repo = GymRepository(dio);
  });

  test('getNearby returns parsed list on 200', () async {
    adapter.onGet(
      '/gyms/nearby',
      (server) => server.reply(200, {
        'success': true,
        'data': [
          {
            '_id': 'gym1',
            'name': 'Iron Gym',
            'address': '1 Main St',
            'location': {
              'type': 'Point',
              'coordinates': [106.7009, 10.7769],
            },
            'distanceKm': 1.5,
          },
        ],
        'pagination': {'limit': 20, 'offset': 0, 'hasMore': false},
      }),
    );

    final gyms = await repo.getNearby(lat: 10.7769, lng: 106.7009);

    expect(gyms.length, 1);
    expect(gyms.first.id, 'gym1');
    expect(gyms.first.name, 'Iron Gym');
    expect(gyms.first.lat, 10.7769);
    expect(gyms.first.lng, 106.7009);
    expect(gyms.first.distanceKm, 1.5);
  });

  test('getNearby returns empty list when data is empty', () async {
    adapter.onGet(
      '/gyms/nearby',
      (server) => server.reply(200, {
        'success': true,
        'data': [],
        'pagination': {'limit': 20, 'offset': 0, 'hasMore': false},
      }),
    );

    final gyms = await repo.getNearby(lat: 10.7769, lng: 106.7009);
    expect(gyms, isEmpty);
  });

  test('getNearby throws AppFailure on 500', () async {
    adapter.onGet(
      '/gyms/nearby',
      (server) => server.reply(500, {
        'success': false,
        'message': 'Internal server error',
      }),
    );

    expect(
      () => repo.getNearby(lat: 10.7769, lng: 106.7009),
      throwsA(isA<AppFailure>()),
    );
  });
}
```

- [ ] **Step 3.3: Run tests to verify they fail**

```
cd gym_buddy_app
flutter test test/features/maps/data/gym_repository_test.dart
```

Expected: error — `gym_repository.dart` does not exist.

- [ ] **Step 3.4: Implement GymRepository**

Create `gym_buddy_app/lib/features/maps/data/gym_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:gym_buddy_app/core/errors/app_failure.dart';
import 'package:gym_buddy_app/core/network/api_error_parser.dart';
import 'package:gym_buddy_app/features/maps/data/models/gym_model.dart';

class GymRepository {
  GymRepository(this._dio);
  final Dio _dio;

  Future<List<GymModel>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/gyms/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radiusKm,
          'limit': limit,
        },
      );
      final data = response.data;
      if (data == null) throw const AppFailure('Empty response from server.');
      final items = data['data'];
      if (items is! List) throw const FormatException('Expected a list in data.');
      return items
          .cast<Map<String, dynamic>>()
          .map(GymModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw AppFailure(
        parseApiErrorMessage(e.response?.data) ??
            'Failed to load nearby gyms.',
      );
    } on FormatException catch (e) {
      throw AppFailure(e.message);
    } on AppFailure {
      rethrow;
    }
  }
}
```

- [ ] **Step 3.5: Run tests to verify they pass**

```
cd gym_buddy_app
flutter test test/features/maps/data/gym_repository_test.dart
```

Expected: all 3 tests pass.

- [ ] **Step 3.6: Commit**

```
git add gym_buddy_app/pubspec.yaml gym_buddy_app/pubspec.lock \
        gym_buddy_app/lib/features/maps/data/gym_repository.dart \
        gym_buddy_app/test/features/maps/data/gym_repository_test.dart
git commit -m "feat(maps): add GymRepository with getNearby"
```

---

## Task 4: BuddyRepository

**Files:**
- Create: `gym_buddy_app/lib/features/maps/data/buddy_repository.dart`
- Create: `gym_buddy_app/test/features/maps/data/buddy_repository_test.dart`

- [ ] **Step 4.1: Write the failing tests**

Create `gym_buddy_app/test/features/maps/data/buddy_repository_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/core/errors/app_failure.dart';
import 'package:gym_buddy_app/features/maps/data/buddy_repository.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late BuddyRepository repo;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://test.local/api/v1'));
    adapter = DioAdapter(dio: dio);
    repo = BuddyRepository(dio);
  });

  test('getNearby returns parsed list on 200', () async {
    adapter.onGet(
      '/buddies/nearby',
      (server) => server.reply(200, {
        'success': true,
        'data': [
          {
            '_id': 'buddy1',
            'userId': 'user42',
            'location': {
              'type': 'Point',
              'coordinates': [106.7009, 10.7769],
            },
            'distanceKm': 0.8,
            'workoutTypes': ['strength'],
            'availableUntil': '2026-06-07T15:00:00.000Z',
          },
        ],
        'pagination': {'limit': 20, 'offset': 0, 'hasMore': false},
      }),
    );

    final buddies = await repo.getNearby(lat: 10.7769, lng: 106.7009);

    expect(buddies.length, 1);
    expect(buddies.first.id, 'buddy1');
    expect(buddies.first.userId, 'user42');
    expect(buddies.first.lat, 10.7769);
    expect(buddies.first.lng, 106.7009);
    expect(buddies.first.distanceKm, 0.8);
    expect(buddies.first.workoutTypes, ['strength']);
  });

  test('getNearby returns empty list when data is empty', () async {
    adapter.onGet(
      '/buddies/nearby',
      (server) => server.reply(200, {
        'success': true,
        'data': [],
        'pagination': {'limit': 20, 'offset': 0, 'hasMore': false},
      }),
    );

    final buddies = await repo.getNearby(lat: 10.7769, lng: 106.7009);
    expect(buddies, isEmpty);
  });

  test('getNearby throws AppFailure on 500', () async {
    adapter.onGet(
      '/buddies/nearby',
      (server) => server.reply(500, {
        'success': false,
        'message': 'Internal server error',
      }),
    );

    expect(
      () => repo.getNearby(lat: 10.7769, lng: 106.7009),
      throwsA(isA<AppFailure>()),
    );
  });
}
```

- [ ] **Step 4.2: Run tests to verify they fail**

```
cd gym_buddy_app
flutter test test/features/maps/data/buddy_repository_test.dart
```

Expected: error — `buddy_repository.dart` does not exist.

- [ ] **Step 4.3: Implement BuddyRepository**

Create `gym_buddy_app/lib/features/maps/data/buddy_repository.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:gym_buddy_app/core/errors/app_failure.dart';
import 'package:gym_buddy_app/core/network/api_error_parser.dart';
import 'package:gym_buddy_app/features/maps/data/models/buddy_availability_model.dart';

class BuddyRepository {
  BuddyRepository(this._dio);
  final Dio _dio;

  Future<List<BuddyAvailabilityModel>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/buddies/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radiusKm,
          'limit': limit,
        },
      );
      final data = response.data;
      if (data == null) throw const AppFailure('Empty response from server.');
      final items = data['data'];
      if (items is! List) throw const FormatException('Expected a list in data.');
      return items
          .cast<Map<String, dynamic>>()
          .map(BuddyAvailabilityModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw AppFailure(
        parseApiErrorMessage(e.response?.data) ??
            'Failed to load nearby buddies.',
      );
    } on FormatException catch (e) {
      throw AppFailure(e.message);
    } on AppFailure {
      rethrow;
    }
  }
}
```

- [ ] **Step 4.4: Run tests to verify they pass**

```
cd gym_buddy_app
flutter test test/features/maps/data/buddy_repository_test.dart
```

Expected: all 3 tests pass.

- [ ] **Step 4.5: Commit**

```
git add gym_buddy_app/lib/features/maps/data/buddy_repository.dart \
        gym_buddy_app/test/features/maps/data/buddy_repository_test.dart
git commit -m "feat(maps): add BuddyRepository with getNearby"
```

---

## Task 5: GymMarker and BuddyMarker Widgets

**Files:**
- Create: `gym_buddy_app/lib/features/maps/presentation/widgets/gym_marker.dart`
- Create: `gym_buddy_app/lib/features/maps/presentation/widgets/buddy_marker.dart`
- Create: `gym_buddy_app/test/features/maps/presentation/widgets/markers_test.dart`

- [ ] **Step 5.1: Write the failing tests**

Create `gym_buddy_app/test/features/maps/presentation/widgets/markers_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/buddy_marker.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/gym_marker.dart';

void main() {
  testWidgets('GymMarker renders with fitness_center icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: GymMarker()))),
    );

    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
  });

  testWidgets('GymMarker icon is white', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: GymMarker()))),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.fitness_center));
    expect(icon.color, Colors.white);
  });

  testWidgets('BuddyMarker renders with people icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: BuddyMarker()))),
    );

    expect(find.byIcon(Icons.people), findsOneWidget);
  });

  testWidgets('BuddyMarker icon is white', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: BuddyMarker()))),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.people));
    expect(icon.color, Colors.white);
  });
}
```

- [ ] **Step 5.2: Run tests to verify they fail**

```
cd gym_buddy_app
flutter test test/features/maps/presentation/widgets/markers_test.dart
```

Expected: error — marker files do not exist.

- [ ] **Step 5.3: Implement GymMarker**

Create `gym_buddy_app/lib/features/maps/presentation/widgets/gym_marker.dart`:

```dart
import 'package:flutter/material.dart';

class GymMarker extends StatelessWidget {
  const GymMarker({super.key});

  static const _color = Color(0xFF4F8EF7);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x404F8EF7),
            blurRadius: 0,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.fitness_center, color: Colors.white, size: 20),
    );
  }
}
```

- [ ] **Step 5.4: Implement BuddyMarker**

Create `gym_buddy_app/lib/features/maps/presentation/widgets/buddy_marker.dart`:

```dart
import 'package:flutter/material.dart';

class BuddyMarker extends StatelessWidget {
  const BuddyMarker({super.key});

  static const _color = Color(0xFFF76F4F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x40F76F4F),
            blurRadius: 0,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.people, color: Colors.white, size: 20),
    );
  }
}
```

- [ ] **Step 5.5: Run tests to verify they pass**

```
cd gym_buddy_app
flutter test test/features/maps/presentation/widgets/markers_test.dart
```

Expected: all 4 tests pass.

- [ ] **Step 5.6: Commit**

```
git add gym_buddy_app/lib/features/maps/presentation/widgets/gym_marker.dart \
        gym_buddy_app/lib/features/maps/presentation/widgets/buddy_marker.dart \
        gym_buddy_app/test/features/maps/presentation/widgets/markers_test.dart
git commit -m "feat(maps): add GymMarker and BuddyMarker circle widgets"
```

---

## Task 6: MapFilterChips Widget

**Files:**
- Create: `gym_buddy_app/lib/features/maps/presentation/widgets/map_filter_chips.dart`
- Create: `gym_buddy_app/test/features/maps/presentation/widgets/map_filter_chips_test.dart`

- [ ] **Step 6.1: Write the failing tests**

Create `gym_buddy_app/test/features/maps/presentation/widgets/map_filter_chips_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/map_filter_chips.dart';

Widget _wrap({
  bool showGyms = true,
  bool showBuddies = true,
  ValueChanged<bool>? onToggleGyms,
  ValueChanged<bool>? onToggleBuddies,
}) {
  return MaterialApp(
    home: Scaffold(
      body: MapFilterChips(
        showGyms: showGyms,
        showBuddies: showBuddies,
        onToggleGyms: onToggleGyms ?? (_) {},
        onToggleBuddies: onToggleBuddies ?? (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('renders both chip labels', (tester) async {
    await tester.pumpWidget(_wrap());

    expect(find.text('Gyms'), findsOneWidget);
    expect(find.text('Buddies'), findsOneWidget);
  });

  testWidgets('tapping Gyms chip calls onToggleGyms with false when active',
      (tester) async {
    bool? toggled;
    await tester.pumpWidget(_wrap(
      showGyms: true,
      onToggleGyms: (v) => toggled = v,
    ));

    await tester.tap(find.text('Gyms'));
    expect(toggled, false);
  });

  testWidgets('tapping Gyms chip calls onToggleGyms with true when inactive',
      (tester) async {
    bool? toggled;
    await tester.pumpWidget(_wrap(
      showGyms: false,
      onToggleGyms: (v) => toggled = v,
    ));

    await tester.tap(find.text('Gyms'));
    expect(toggled, true);
  });

  testWidgets('tapping Buddies chip calls onToggleBuddies with false when active',
      (tester) async {
    bool? toggled;
    await tester.pumpWidget(_wrap(
      showBuddies: true,
      onToggleBuddies: (v) => toggled = v,
    ));

    await tester.tap(find.text('Buddies'));
    expect(toggled, false);
  });
}
```

- [ ] **Step 6.2: Run tests to verify they fail**

```
cd gym_buddy_app
flutter test test/features/maps/presentation/widgets/map_filter_chips_test.dart
```

Expected: error — `map_filter_chips.dart` does not exist.

- [ ] **Step 6.3: Implement MapFilterChips**

Create `gym_buddy_app/lib/features/maps/presentation/widgets/map_filter_chips.dart`:

```dart
import 'package:flutter/material.dart';

class MapFilterChips extends StatelessWidget {
  const MapFilterChips({
    required this.showGyms,
    required this.showBuddies,
    required this.onToggleGyms,
    required this.onToggleBuddies,
    super.key,
  });

  final bool showGyms;
  final bool showBuddies;
  final ValueChanged<bool> onToggleGyms;
  final ValueChanged<bool> onToggleBuddies;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Chip(
          label: 'Gyms',
          icon: Icons.fitness_center,
          active: showGyms,
          activeColor: const Color(0xFF4F8EF7),
          onTap: () => onToggleGyms(!showGyms),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'Buddies',
          icon: Icons.people,
          active: showBuddies,
          activeColor: const Color(0xFFF76F4F),
          onTap: () => onToggleBuddies(!showBuddies),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final contentColor = active
        ? Colors.white
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? activeColor : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: contentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6.4: Run tests to verify they pass**

```
cd gym_buddy_app
flutter test test/features/maps/presentation/widgets/map_filter_chips_test.dart
```

Expected: all 4 tests pass.

- [ ] **Step 6.5: Commit**

```
git add gym_buddy_app/lib/features/maps/presentation/widgets/map_filter_chips.dart \
        gym_buddy_app/test/features/maps/presentation/widgets/map_filter_chips_test.dart
git commit -m "feat(maps): add MapFilterChips toggle widget"
```

---

## Task 7: MapScreen

**Files:**
- Create: `gym_buddy_app/lib/features/maps/presentation/map_screen.dart`

> Note: `MapScreen` depends on `Geolocator.getCurrentPosition()` which only works on a real device or emulator. Widget tests for MapScreen are deferred to Task 8 (integration via HomeScreen nav test). Verify manually after wiring in Task 8.

- [ ] **Step 7.1: Implement MapScreen**

Create `gym_buddy_app/lib/features/maps/presentation/map_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gym_buddy_app/features/location/data/location_permission_service.dart';
import 'package:gym_buddy_app/features/location/domain/location_permission_state.dart';
import 'package:gym_buddy_app/features/maps/data/buddy_repository.dart';
import 'package:gym_buddy_app/features/maps/data/gym_repository.dart';
import 'package:gym_buddy_app/features/maps/data/models/buddy_availability_model.dart';
import 'package:gym_buddy_app/features/maps/data/models/gym_model.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/buddy_marker.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/gym_marker.dart';
import 'package:gym_buddy_app/features/maps/presentation/widgets/map_filter_chips.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    required this.gymRepository,
    required this.buddyRepository,
    this.locationPermissionService = const LocationPermissionService(),
    super.key,
  });

  final GymRepository gymRepository;
  final BuddyRepository buddyRepository;
  final LocationPermissionService locationPermissionService;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _fallbackCenter = LatLng(10.7769, 106.7009);
  static const _fallbackZoom = 13.0;
  static const _nearbyZoom = 15.0;

  final MapController _mapController = MapController();

  LatLng _center = _fallbackCenter;
  bool _hasLocation = false;
  List<GymModel> _gyms = [];
  List<BuddyAvailabilityModel> _buddies = [];
  bool _showGyms = true;
  bool _showBuddies = true;
  bool _isLoading = false;
  String _statusMessage = 'Loading map...';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading map...';
    });

    final permission =
        await widget.locationPermissionService.checkPermission();
    if (permission.status != LocationPermissionStatus.granted) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasLocation = false;
        _statusMessage = permission.message;
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      String? errorMessage;

      final results = await Future.wait([
        widget.gymRepository
            .getNearby(lat: lat, lng: lng)
            .catchError((_) {
          errorMessage = 'Gyms unavailable.';
          return <GymModel>[];
        }),
        widget.buddyRepository
            .getNearby(lat: lat, lng: lng)
            .catchError((_) {
          errorMessage = errorMessage != null
              ? 'Gyms and buddies unavailable.'
              : 'Buddies unavailable.';
          return <BuddyAvailabilityModel>[];
        }),
      ]);

      final gyms = results[0] as List<GymModel>;
      final buddies = results[1] as List<BuddyAvailabilityModel>;

      if (!mounted) return;
      setState(() {
        _center = LatLng(lat, lng);
        _hasLocation = true;
        _gyms = gyms;
        _buddies = buddies;
        _isLoading = false;
        _statusMessage = errorMessage ??
            'Showing ${gyms.length} gyms and ${buddies.length} buddies nearby.';
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(_center, _nearbyZoom);
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasLocation = false;
        _statusMessage =
            'Using the default map area until your location is available.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _fallbackCenter,
            initialZoom: _fallbackZoom,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.thienphuhuynh.gym_buddy_app',
            ),
            if (_showGyms)
              MarkerLayer(
                markers: _gyms
                    .map(
                      (gym) => Marker(
                        point: LatLng(gym.lat, gym.lng),
                        width: 50,
                        height: 50,
                        child: const GymMarker(),
                      ),
                    )
                    .toList(),
              ),
            if (_showBuddies)
              MarkerLayer(
                markers: _buddies
                    .map(
                      (buddy) => Marker(
                        point: LatLng(buddy.lat, buddy.lng),
                        width: 50,
                        height: 50,
                        child: const BuddyMarker(),
                      ),
                    )
                    .toList(),
              ),
            MarkerLayer(
              markers: [
                if (_hasLocation)
                  Marker(
                    point: _center,
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.my_location,
                      color: Theme.of(context).colorScheme.primary,
                      size: 36,
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: topPadding + 12,
          left: 12,
          right: 12,
          child: Column(
            children: [
              _StatusBar(
                isLoading: _isLoading,
                message: _statusMessage,
                onRefresh: _load,
              ),
              const SizedBox(height: 8),
              MapFilterChips(
                showGyms: _showGyms,
                showBuddies: _showBuddies,
                onToggleGyms: (v) => setState(() => _showGyms = v),
                onToggleBuddies: (v) => setState(() => _showBuddies = v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.isLoading,
    required this.message,
    required this.onRefresh,
  });

  final bool isLoading;
  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.map_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              tooltip: 'Refresh map',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7.2: Verify it compiles**

```
cd gym_buddy_app
flutter analyze lib/features/maps/presentation/map_screen.dart
```

Expected: no errors.

- [ ] **Step 7.3: Commit**

```
git add gym_buddy_app/lib/features/maps/presentation/map_screen.dart
git commit -m "feat(maps): add MapScreen with parallel fetch and marker layers"
```

---

## Task 8: Navigation Wiring

Thread `GymRepository` and `BuddyRepository` from `main.dart` through `GymBuddyApp` → `BootstrapGate` → `HomeScreen`, and add a `NavigationBar` with Home and Map tabs. Update widget tests to pass fake repos.

**Files:**
- Modify: `gym_buddy_app/lib/app/gym_buddy_app.dart`
- Modify: `gym_buddy_app/lib/app/bootstrap_gate.dart`
- Modify: `gym_buddy_app/lib/features/home/home_screen.dart`
- Modify: `gym_buddy_app/lib/main.dart`
- Modify: `gym_buddy_app/test/widget_test.dart`

- [ ] **Step 8.1: Update GymBuddyApp**

Replace the full content of `gym_buddy_app/lib/app/gym_buddy_app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:gym_buddy_app/app/app_theme.dart';
import 'package:gym_buddy_app/app/bootstrap_gate.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/bootstrap_auth_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/list_sessions_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_all_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/register_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/revoke_session_use_case.dart';
import 'package:gym_buddy_app/features/maps/data/buddy_repository.dart';
import 'package:gym_buddy_app/features/maps/data/gym_repository.dart';

class GymBuddyApp extends StatelessWidget {
  const GymBuddyApp({
    required this.bootstrapAuthUseCase,
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.logoutAllUseCase,
    required this.listSessionsUseCase,
    required this.revokeSessionUseCase,
    required this.gymRepository,
    required this.buddyRepository,
    super.key,
  });

  final BootstrapAuthUseCase bootstrapAuthUseCase;
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final LogoutAllUseCase logoutAllUseCase;
  final ListSessionsUseCase listSessionsUseCase;
  final RevokeSessionUseCase revokeSessionUseCase;
  final GymRepository gymRepository;
  final BuddyRepository buddyRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymBuddy Connect',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: BootstrapGate(
        bootstrapAuthUseCase: bootstrapAuthUseCase,
        loginUseCase: loginUseCase,
        registerUseCase: registerUseCase,
        logoutUseCase: logoutUseCase,
        logoutAllUseCase: logoutAllUseCase,
        listSessionsUseCase: listSessionsUseCase,
        revokeSessionUseCase: revokeSessionUseCase,
        gymRepository: gymRepository,
        buddyRepository: buddyRepository,
      ),
    );
  }
}
```

- [ ] **Step 8.2: Update BootstrapGate**

Replace the full content of `gym_buddy_app/lib/app/bootstrap_gate.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/bootstrap_auth_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/list_sessions_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_all_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/register_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/revoke_session_use_case.dart';
import 'package:gym_buddy_app/features/auth/presentation/auth_screen.dart';
import 'package:gym_buddy_app/features/home/home_screen.dart';
import 'package:gym_buddy_app/features/maps/data/buddy_repository.dart';
import 'package:gym_buddy_app/features/maps/data/gym_repository.dart';

class BootstrapGate extends StatefulWidget {
  const BootstrapGate({
    required this.bootstrapAuthUseCase,
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.logoutAllUseCase,
    required this.listSessionsUseCase,
    required this.revokeSessionUseCase,
    required this.gymRepository,
    required this.buddyRepository,
    super.key,
  });

  final BootstrapAuthUseCase bootstrapAuthUseCase;
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final LogoutAllUseCase logoutAllUseCase;
  final ListSessionsUseCase listSessionsUseCase;
  final RevokeSessionUseCase revokeSessionUseCase;
  final GymRepository gymRepository;
  final BuddyRepository buddyRepository;

  @override
  State<BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<BootstrapGate> {
  late Future<BootstrapAuthResult> _bootstrap;
  AuthUiModel? _authenticatedUser;

  @override
  void initState() {
    super.initState();
    _bootstrap = widget.bootstrapAuthUseCase();
  }

  void _retryBootstrap() {
    setState(() {
      _bootstrap = widget.bootstrapAuthUseCase();
    });
  }

  void _setAuthenticated(AuthUiModel auth) {
    setState(() {
      _authenticatedUser = auth;
    });
  }

  void _setUnauthenticated() {
    setState(() {
      _authenticatedUser = null;
      _bootstrap = Future.value(const BootstrapUnauthenticated());
    });
  }

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = _authenticatedUser;
    if (authenticatedUser != null) {
      return _home(authenticatedUser);
    }

    return FutureBuilder<BootstrapAuthResult>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _BootstrapLoadingScreen();
        }

        final result = snapshot.data ?? const BootstrapUnauthenticated();
        return switch (result) {
          BootstrapAuthenticated(:final auth) => _home(auth),
          BootstrapRecoverableError(:final message) => RetrySessionScreen(
            message: message,
            onRetry: _retryBootstrap,
            onLogout: () async {
              await widget.logoutUseCase();
              _setUnauthenticated();
            },
          ),
          BootstrapUnauthenticated() => _auth(),
        };
      },
    );
  }

  Widget _auth() {
    return AuthScreen(
      loginUseCase: widget.loginUseCase,
      registerUseCase: widget.registerUseCase,
      logoutUseCase: widget.logoutUseCase,
      logoutAllUseCase: widget.logoutAllUseCase,
      listSessionsUseCase: widget.listSessionsUseCase,
      revokeSessionUseCase: widget.revokeSessionUseCase,
      onAuthenticated: _setAuthenticated,
    );
  }

  Widget _home(AuthUiModel auth) {
    return HomeScreen(
      auth: auth,
      logoutUseCase: widget.logoutUseCase,
      logoutAllUseCase: widget.logoutAllUseCase,
      listSessionsUseCase: widget.listSessionsUseCase,
      revokeSessionUseCase: widget.revokeSessionUseCase,
      gymRepository: widget.gymRepository,
      buddyRepository: widget.buddyRepository,
      onSignedOut: _setUnauthenticated,
    );
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// RetrySessionScreen unchanged — keep original implementation below this line.
class RetrySessionScreen extends StatelessWidget {
  const RetrySessionScreen({
    required this.message,
    required this.onRetry,
    required this.onLogout,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.sync_problem,
                  size: 42,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 18),
                Text(
                  'Session check failed',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    await onLogout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 8.3: Update HomeScreen**

Replace the full content of `gym_buddy_app/lib/features/home/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_session_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/list_sessions_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_all_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/revoke_session_use_case.dart';
import 'package:gym_buddy_app/features/location/presentation/location_permission_panel.dart';
import 'package:gym_buddy_app/features/maps/data/buddy_repository.dart';
import 'package:gym_buddy_app/features/maps/data/gym_repository.dart';
import 'package:gym_buddy_app/features/maps/presentation/map_preview_panel.dart';
import 'package:gym_buddy_app/features/maps/presentation/map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.auth,
    required this.logoutUseCase,
    required this.logoutAllUseCase,
    required this.listSessionsUseCase,
    required this.revokeSessionUseCase,
    required this.gymRepository,
    required this.buddyRepository,
    required this.onSignedOut,
    super.key,
  });

  final AuthUiModel auth;
  final LogoutUseCase logoutUseCase;
  final LogoutAllUseCase logoutAllUseCase;
  final ListSessionsUseCase listSessionsUseCase;
  final RevokeSessionUseCase revokeSessionUseCase;
  final GymRepository gymRepository;
  final BuddyRepository buddyRepository;
  final VoidCallback onSignedOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _mapRefreshKey = 0;
  int _selectedTab = 0;

  void _reloadMapPreview() {
    setState(() {
      _mapRefreshKey += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GymBuddy'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsScreen(
                    logoutUseCase: widget.logoutUseCase,
                    logoutAllUseCase: widget.logoutAllUseCase,
                    listSessionsUseCase: widget.listSessionsUseCase,
                    revokeSessionUseCase: widget.revokeSessionUseCase,
                    onSignedOut: widget.onSignedOut,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: _selectedTab == 0 ? _buildHomeTab() : _buildMapTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Welcome, ${widget.auth.displayName}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          widget.auth.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Text(widget.auth.message),
        const SizedBox(height: 24),
        LocationPermissionPanel(onPermissionChanged: _reloadMapPreview),
        const SizedBox(height: 16),
        MapPreviewPanel(key: ValueKey(_mapRefreshKey)),
      ],
    );
  }

  Widget _buildMapTab() {
    return MapScreen(
      gymRepository: widget.gymRepository,
      buddyRepository: widget.buddyRepository,
    );
  }
}

// SettingsScreen and SessionsScreen unchanged below — keep original implementations.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.logoutUseCase,
    required this.logoutAllUseCase,
    required this.listSessionsUseCase,
    required this.revokeSessionUseCase,
    required this.onSignedOut,
    super.key,
  });

  final LogoutUseCase logoutUseCase;
  final LogoutAllUseCase logoutAllUseCase;
  final ListSessionsUseCase listSessionsUseCase;
  final RevokeSessionUseCase revokeSessionUseCase;
  final VoidCallback onSignedOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: const Text('Sessions'),
            subtitle: const Text('Manage devices signed in to GymBuddy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SessionsScreen(
                    logoutAllUseCase: logoutAllUseCase,
                    listSessionsUseCase: listSessionsUseCase,
                    revokeSessionUseCase: revokeSessionUseCase,
                    onSignedOut: onSignedOut,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await logoutUseCase();
              if (context.mounted) {
                onSignedOut();
              }
            },
          ),
        ],
      ),
    );
  }
}

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({
    required this.logoutAllUseCase,
    required this.listSessionsUseCase,
    required this.revokeSessionUseCase,
    required this.onSignedOut,
    super.key,
  });

  final LogoutAllUseCase logoutAllUseCase;
  final ListSessionsUseCase listSessionsUseCase;
  final RevokeSessionUseCase revokeSessionUseCase;
  final VoidCallback onSignedOut;

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  late Future<List<AuthSessionUiModel>> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = widget.listSessionsUseCase();
  }

  void _reload() {
    setState(() {
      _sessions = widget.listSessionsUseCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: FutureBuilder<List<AuthSessionUiModel>>(
        future: _sessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            );
          }

          final sessions = snapshot.data ?? const [];
          return ListView.separated(
            itemCount: sessions.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == sessions.length) {
                return ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout all devices'),
                  onTap: () async {
                    final confirmed = await _confirm(
                      context,
                      'Logout all devices?',
                      'This will sign you out on this device too.',
                    );
                    if (!confirmed) return;
                    await widget.logoutAllUseCase();
                    if (context.mounted) widget.onSignedOut();
                  },
                );
              }

              final session = sessions[index];
              return ListTile(
                leading: Icon(
                  session.isCurrentDevice
                      ? Icons.phone_android
                      : Icons.devices_other,
                ),
                title: Text(session.deviceName),
                subtitle: Text(
                  session.isCurrentDevice
                      ? '${session.platform} - This device'
                      : session.platform,
                ),
                trailing: IconButton(
                  tooltip: 'Revoke session',
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    final confirmed = await _confirm(
                      context,
                      session.isCurrentDevice
                          ? 'Revoke this device?'
                          : 'Revoke session?',
                      session.isCurrentDevice
                          ? 'This will sign you out on this device.'
                          : 'This device will need to log in again.',
                    );
                    if (!confirmed) return;
                    await widget.revokeSessionUseCase(session.id);
                    if (session.isCurrentDevice && context.mounted) {
                      widget.onSignedOut();
                    } else {
                      _reload();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String content,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
```

- [ ] **Step 8.4: Update main.dart**

Replace the full content of `gym_buddy_app/lib/main.dart`:

```dart
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy_app/app/gym_buddy_app.dart';
import 'package:gym_buddy_app/core/config/app_config_loader.dart';
import 'package:gym_buddy_app/core/device/device_info_provider.dart';
import 'package:gym_buddy_app/core/network/dio_client_factory.dart';
import 'package:gym_buddy_app/core/session/auth_token_interceptor.dart';
import 'package:gym_buddy_app/core/session/cookie_store_factory.dart';
import 'package:gym_buddy_app/core/session/secure_session_store.dart';
import 'package:gym_buddy_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:gym_buddy_app/features/auth/data/mappers/auth_ui_model_mapper.dart';
import 'package:gym_buddy_app/features/auth/data/mappers/session_mapper.dart';
import 'package:gym_buddy_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gym_buddy_app/features/auth/data/repositories/session_repository_impl.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/bootstrap_auth_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/list_sessions_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_all_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/register_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/revoke_session_use_case.dart';
import 'package:gym_buddy_app/features/maps/data/buddy_repository.dart';
import 'package:gym_buddy_app/features/maps/data/gym_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await const AppConfigLoader().load();
  final dio = const DioClientFactory().create(config);
  const sessionStore = SecureSessionStore();
  final cookieJar = await const CookieStoreFactory().create();
  dio.interceptors.add(CookieManager(cookieJar));
  final remoteDataSource = AuthRemoteDataSource(
    dio: dio,
    deviceInfoProvider: DeviceInfoProvider(),
  );
  final repository = AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    mapper: const AuthUiModelMapper(),
    sessionStore: sessionStore,
  );
  final sessionRepository = SessionRepositoryImpl(
    remoteDataSource: remoteDataSource,
    sessionStore: sessionStore,
    mapper: const SessionMapper(),
    cookieJar: cookieJar,
  );
  dio.interceptors.add(
    AuthTokenInterceptor(
      dio: dio,
      sessionStore: sessionStore,
      refreshSession: sessionRepository.refresh,
    ),
  );

  runApp(
    GymBuddyApp(
      bootstrapAuthUseCase: BootstrapAuthUseCase(
        sessionStore: sessionStore,
        sessionRepository: sessionRepository,
        authRepository: repository,
      ),
      loginUseCase: LoginUseCase(repository),
      registerUseCase: RegisterUseCase(repository),
      logoutUseCase: LogoutUseCase(sessionRepository),
      logoutAllUseCase: LogoutAllUseCase(sessionRepository),
      listSessionsUseCase: ListSessionsUseCase(sessionRepository),
      revokeSessionUseCase: RevokeSessionUseCase(sessionRepository),
      gymRepository: GymRepository(dio),
      buddyRepository: BuddyRepository(dio),
    ),
  );
}
```

- [ ] **Step 8.5: Update widget_test.dart**

Add fake repo imports and classes, and update `pumpAuthApp` to pass them. Add the two imports at the top of `gym_buddy_app/test/widget_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:gym_buddy_app/features/maps/data/buddy_repository.dart';
import 'package:gym_buddy_app/features/maps/data/gym_repository.dart';
import 'package:gym_buddy_app/features/maps/data/models/buddy_availability_model.dart';
import 'package:gym_buddy_app/features/maps/data/models/gym_model.dart';
```

Update `pumpAuthApp` to accept and pass fake repos:

```dart
Future<void> pumpAuthApp(WidgetTester tester) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  await binding.setSurfaceSize(const Size(430, 900));
  addTearDown(() => binding.setSurfaceSize(null));
  final repository = _FakeAuthRepository();
  final sessionRepository = _FakeSessionRepository();
  await tester.pumpWidget(
    GymBuddyApp(
      bootstrapAuthUseCase: _FakeBootstrapAuthUseCase(),
      loginUseCase: LoginUseCase(repository),
      registerUseCase: RegisterUseCase(repository),
      logoutUseCase: LogoutUseCase(sessionRepository),
      logoutAllUseCase: LogoutAllUseCase(sessionRepository),
      listSessionsUseCase: ListSessionsUseCase(sessionRepository),
      revokeSessionUseCase: RevokeSessionUseCase(sessionRepository),
      gymRepository: _FakeGymRepository(),
      buddyRepository: _FakeBuddyRepository(),
    ),
  );
  await tester.pumpAndSettle();
}
```

Add the fake repo classes at the bottom of `widget_test.dart` (after the existing fake classes):

```dart
class _FakeGymRepository extends GymRepository {
  _FakeGymRepository() : super(Dio());

  @override
  Future<List<GymModel>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limit = 20,
  }) async => const [];
}

class _FakeBuddyRepository extends BuddyRepository {
  _FakeBuddyRepository() : super(Dio());

  @override
  Future<List<BuddyAvailabilityModel>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    int limit = 20,
  }) async => const [];
}
```

- [ ] **Step 8.6: Run all tests**

```
cd gym_buddy_app
flutter test
```

Expected: all tests pass — existing widget tests + all new map tests.

- [ ] **Step 8.7: Type-check the app**

```
cd gym_buddy_app
flutter analyze
```

Expected: no errors.

- [ ] **Step 8.8: Commit**

```
git add gym_buddy_app/lib/app/gym_buddy_app.dart \
        gym_buddy_app/lib/app/bootstrap_gate.dart \
        gym_buddy_app/lib/features/home/home_screen.dart \
        gym_buddy_app/lib/main.dart \
        gym_buddy_app/test/widget_test.dart
git commit -m "feat(maps): wire GymRepository and BuddyRepository into HomeScreen nav tab"
```

---

## Verification

After all tasks are complete:

1. Run on a connected Android device or emulator:
   ```
   cd gym_buddy_app
   flutter run
   ```
2. Log in, then tap the **Map** tab in the bottom navigation bar.
3. Verify the map loads centered on your location with gym markers (blue) and buddy markers (orange).
4. Tap the **Gyms** chip — gym markers should disappear.
5. Tap **Buddies** chip — buddy markers should disappear.
6. Tap the Refresh button — map reloads.
7. Switch back to **Home** tab — existing home content and preview map still work.
