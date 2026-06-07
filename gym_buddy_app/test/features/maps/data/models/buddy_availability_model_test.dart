import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/features/maps/data/models/buddy_availability_model.dart';

void main() {
  final validJson = {
    '_id': 'buddy1',
    'userId': 'user1',
    'location': {
      'type': 'Point',
      'coordinates': [106.7009, 10.7769],
    },
    'distanceKm': 2.3,
    'workoutTypes': ['cardio', 'strength'],
    'availableUntil': '2026-06-07T10:00:00.000Z',
  };

  test('fromJson parses all fields correctly', () {
    final buddy = BuddyAvailabilityModel.fromJson(validJson);

    expect(buddy.id, 'buddy1');
    expect(buddy.userId, 'user1');
    expect(buddy.lng, 106.7009);
    expect(buddy.lat, 10.7769);
    expect(buddy.distanceKm, 2.3);
    expect(buddy.workoutTypes, ['cardio', 'strength']);
    expect(buddy.availableUntil, DateTime.parse('2026-06-07T10:00:00.000Z'));
  });

  test('fromJson parses integer distanceKm as double', () {
    final json = {...validJson, 'distanceKm': 1};
    final buddy = BuddyAvailabilityModel.fromJson(json);
    expect(buddy.distanceKm, 1.0);
  });

  test('fromJson parses empty workoutTypes list', () {
    final json = {...validJson, 'workoutTypes': <String>[]};
    final buddy = BuddyAvailabilityModel.fromJson(json);
    expect(buddy.workoutTypes, isEmpty);
  });

  test('fromJson throws FormatException when _id is missing', () {
    final json = Map<String, dynamic>.from(validJson)..remove('_id');
    expect(() => BuddyAvailabilityModel.fromJson(json), throwsA(isA<FormatException>()));
  });

  test('fromJson throws FormatException when location is missing', () {
    final json = Map<String, dynamic>.from(validJson)..remove('location');
    expect(() => BuddyAvailabilityModel.fromJson(json), throwsA(isA<FormatException>()));
  });

  test('fromJson throws FormatException when coordinates is malformed', () {
    final json = {
      ...validJson,
      'location': {'type': 'Point', 'coordinates': [106.7009]},
    };
    expect(() => BuddyAvailabilityModel.fromJson(json), throwsA(isA<FormatException>()));
  });

  test('fromJson throws FormatException when availableUntil is missing', () {
    final json = Map<String, dynamic>.from(validJson)..remove('availableUntil');
    expect(() => BuddyAvailabilityModel.fromJson(json), throwsA(isA<FormatException>()));
  });

  test('fromJson throws FormatException when availableUntil is invalid date', () {
    final json = {...validJson, 'availableUntil': 'not-a-date'};
    expect(() => BuddyAvailabilityModel.fromJson(json), throwsA(isA<FormatException>()));
  });
}
