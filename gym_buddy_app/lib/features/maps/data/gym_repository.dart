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
      final data = response.data?['data'];
      if (data is! List) throw const AppFailure('Invalid response format');
      return data
          .cast<Map<String, dynamic>>()
          .map(GymModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw AppFailure(
          parseApiErrorMessage(e.response?.data) ??
              'Failed to fetch nearby gyms');
    } on FormatException catch (e) {
      throw AppFailure(e.message);
    } on AppFailure {
      rethrow;
    }
  }
}
