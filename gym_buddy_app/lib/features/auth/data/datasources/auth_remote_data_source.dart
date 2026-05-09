import 'package:dio/dio.dart';
import 'package:gym_buddy_app/core/errors/app_failure.dart';
import 'package:gym_buddy_app/core/network/api_error_parser.dart';
import 'package:gym_buddy_app/features/auth/data/dto/auth_response_dto.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) async {
    return _postAuth(
      path: '/auth/login',
      body: {'email': email, 'password': password},
    );
  }

  Future<AuthResponseDto> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return _postAuth(
      path: '/auth/register',
      body: {'username': username, 'email': email, 'password': password},
    );
  }

  Future<AuthResponseDto> _postAuth({
    required String path,
    required Map<String, String> body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      final data = response.data;
      if (data == null) {
        throw const AppFailure('The server returned an empty response.');
      }

      return AuthResponseDto.fromJson(data);
    } on DioException catch (error) {
      final message = parseApiErrorMessage(error.response?.data);
      if (message != null) {
        throw AppFailure(message);
      }

      throw AppFailure(_fallbackMessageFor(error));
    } on FormatException catch (error) {
      throw AppFailure(error.message);
    }
  }

  String _fallbackMessageFor(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'The request timed out. Please try again.',
      DioExceptionType.connectionError =>
        'Unable to reach the server. Please check your connection.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
