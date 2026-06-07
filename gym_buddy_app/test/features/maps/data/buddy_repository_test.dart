import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/core/errors/app_failure.dart';
import 'package:gym_buddy_app/features/maps/data/buddy_repository.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late BuddyRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    adapter = DioAdapter(dio: dio);
    repository = BuddyRepository(dio);
  });

  const lat = 10.7769;
  const lng = 106.7009;

  final buddyJson = {
    '_id': 'buddy1',
    'userId': 'user1',
    'location': {
      'type': 'Point',
      'coordinates': [lng, lat],
    },
    'distanceKm': 2.3,
    'workoutTypes': ['cardio'],
    'availableUntil': '2026-06-07T10:00:00.000Z',
  };

  test('getNearby returns list of BuddyAvailabilityModel on success', () async {
    adapter.onGet(
      '/buddies/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radius': 5.0, 'limit': 20},
      (server) => server.reply(200, {
        'success': true,
        'data': [buddyJson],
      }),
    );

    final buddies = await repository.getNearby(lat: lat, lng: lng);

    expect(buddies, hasLength(1));
    expect(buddies.first.id, 'buddy1');
    expect(buddies.first.userId, 'user1');
    expect(buddies.first.workoutTypes, ['cardio']);
  });

  test('getNearby returns empty list when data is empty', () async {
    adapter.onGet(
      '/buddies/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radius': 5.0, 'limit': 20},
      (server) => server.reply(200, {'success': true, 'data': []}),
    );

    final buddies = await repository.getNearby(lat: lat, lng: lng);

    expect(buddies, isEmpty);
  });

  test('getNearby throws AppFailure on 4xx error', () async {
    adapter.onGet(
      '/buddies/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radius': 5.0, 'limit': 20},
      (server) => server.reply(400, {
        'success': false,
        'message': 'Bad request',
      }),
    );

    expect(
      () => repository.getNearby(lat: lat, lng: lng),
      throwsA(isA<AppFailure>()),
    );
  });

  test('getNearby throws AppFailure on network error', () async {
    adapter.onGet(
      '/buddies/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radius': 5.0, 'limit': 20},
      (server) => server.throws(
        0,
        DioException(
          requestOptions: RequestOptions(path: '/buddies/nearby'),
          type: DioExceptionType.connectionError,
          message: 'Connection refused',
        ),
      ),
    );

    expect(
      () => repository.getNearby(lat: lat, lng: lng),
      throwsA(isA<AppFailure>()),
    );
  });

  test('getNearby uses custom radiusKm and limit', () async {
    adapter.onGet(
      '/buddies/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radius': 10.0, 'limit': 5},
      (server) => server.reply(200, {'success': true, 'data': []}),
    );

    final buddies = await repository.getNearby(
        lat: lat, lng: lng, radiusKm: 10.0, limit: 5);

    expect(buddies, isEmpty);
  });
}
