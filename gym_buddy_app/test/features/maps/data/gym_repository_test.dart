import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/core/errors/app_failure.dart';
import 'package:gym_buddy_app/features/maps/data/gym_repository.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late GymRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
    adapter = DioAdapter(dio: dio);
    repository = GymRepository(dio);
  });

  const lat = 10.7769;
  const lng = 106.7009;

  final gymJson = {
    '_id': 'gym1',
    'name': 'Iron Gym',
    'address': '123 Main St',
    'location': {
      'type': 'Point',
      'coordinates': [lng, lat],
    },
    'distanceKm': 1.5,
  };

  test('getNearby returns list of GymModel on success', () async {
    adapter.onGet(
      '/gyms/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radius': 5.0, 'limit': 20},
      (server) => server.reply(200, {
        'success': true,
        'data': [gymJson],
      }),
    );

    final gyms = await repository.getNearby(lat: lat, lng: lng);

    expect(gyms, hasLength(1));
    expect(gyms.first.id, 'gym1');
    expect(gyms.first.name, 'Iron Gym');
  });

  test('getNearby returns empty list when data is empty', () async {
    adapter.onGet(
      '/gyms/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radius': 5.0, 'limit': 20},
      (server) => server.reply(200, {'success': true, 'data': []}),
    );

    final gyms = await repository.getNearby(lat: lat, lng: lng);

    expect(gyms, isEmpty);
  });

  test('getNearby throws AppFailure on 4xx error', () async {
    adapter.onGet(
      '/gyms/nearby',
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
      '/gyms/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radius': 5.0, 'limit': 20},
      (server) => server.throws(
        0,
        DioException(
          requestOptions: RequestOptions(path: '/gyms/nearby'),
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
      '/gyms/nearby',
      queryParameters: {'lat': lat, 'lng': lng, 'radius': 10.0, 'limit': 5},
      (server) => server.reply(200, {'success': true, 'data': []}),
    );

    final gyms = await repository.getNearby(
        lat: lat, lng: lng, radiusKm: 10.0, limit: 5);

    expect(gyms, isEmpty);
  });
}
