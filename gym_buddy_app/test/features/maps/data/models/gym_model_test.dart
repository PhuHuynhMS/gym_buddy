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
