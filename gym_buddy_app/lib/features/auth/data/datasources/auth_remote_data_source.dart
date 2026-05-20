import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gym_buddy_app/core/device/device_info_provider.dart';
import 'package:gym_buddy_app/core/errors/app_failure.dart';
import 'package:gym_buddy_app/core/network/api_error_parser.dart';
import 'package:gym_buddy_app/features/auth/data/dto/auth_response_dto.dart';
import 'package:gym_buddy_app/features/auth/data/dto/profile_response_dto.dart';
import 'package:gym_buddy_app/features/auth/data/dto/session_dto.dart';
import 'package:gym_buddy_app/features/auth/data/dto/token_response_dto.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource({
    required Dio dio,
    required DeviceInfoProvider deviceInfoProvider,
  }) : _dio = dio,
       _deviceInfoProvider = deviceInfoProvider;

  final Dio _dio;
  final DeviceInfoProvider _deviceInfoProvider;

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
      final headers = await _deviceInfoProvider.authHeaders();
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: headers),
      );
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
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure('Unable to prepare device session details.');
    }
  }

  Future<TokenResponseDto> refresh() async {
    return _requestToken(
      () => _dio.post<Map<String, dynamic>>('/auth/refresh'),
    );
  }

  Future<void> logout() async {
    await _requestVoid(() => _dio.post<Map<String, dynamic>>('/auth/logout'));
  }

  Future<void> logoutAll() async {
    await _requestVoid(
      () => _dio.post<Map<String, dynamic>>('/auth/logout-all'),
    );
  }

  Future<List<SessionDto>> listSessions() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/sessions');
      final data = response.data;
      if (data == null) {
        throw const AppFailure('The server returned an empty response.');
      }

      return SessionDto.listFromJson(data);
    } on DioException catch (error) {
      throw AppFailure(
        parseApiErrorMessage(error.response?.data) ??
            _fallbackMessageFor(error),
      );
    } on FormatException catch (error) {
      throw AppFailure(error.message);
    }
  }

  Future<ProfileResponseDto> profile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/profile');
      final data = response.data;
      if (data == null) {
        throw const AppFailure('The server returned an empty response.');
      }

      return ProfileResponseDto.fromJson(data);
    } on DioException catch (error) {
      throw AppFailure(
        parseApiErrorMessage(error.response?.data) ??
            _fallbackMessageFor(error),
      );
    } on FormatException catch (error) {
      throw AppFailure(error.message);
    }
  }

  Future<void> revokeSession(String sessionId) async {
    await _requestVoid(
      () => _dio.delete<Map<String, dynamic>>('/auth/sessions/$sessionId'),
    );
  }

  Future<TokenResponseDto> _requestToken(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null) {
        throw const AppFailure('The server returned an empty response.');
      }

      return TokenResponseDto.fromJson(data);
    } on DioException catch (error) {
      throw AppFailure(
        parseApiErrorMessage(error.response?.data) ??
            _fallbackMessageFor(error),
      );
    } on FormatException catch (error) {
      throw AppFailure(error.message);
    }
  }

  Future<void> _requestVoid(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      await request();
    } on DioException catch (error) {
      throw AppFailure(
        parseApiErrorMessage(error.response?.data) ??
            _fallbackMessageFor(error),
      );
    }
  }

  String _fallbackMessageFor(DioException error) {
    final underlyingError = error.error?.toString();
    final underlyingErrorType = error.error.runtimeType.toString();

    if (error.type == DioExceptionType.unknown &&
        underlyingError != null &&
        (underlyingError.contains('HandshakeException') ||
            underlyingError.contains('CertificateException') ||
            underlyingError.toLowerCase().contains('certificate'))) {
      return 'The server certificate is not trusted on this device.';
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'The request timed out. Please try again.',
      DioExceptionType.connectionError =>
        'Unable to reach the server. Please check your connection.',
      DioExceptionType.badCertificate =>
        'The server certificate is not trusted on this device.',
      _ => kDebugMode
          ? 'Network error: ${error.type.name}, status ${error.response?.statusCode ?? 'none'}, ${error.message ?? 'no message'}, underlying $underlyingErrorType: ${underlyingError ?? 'none'}'
          : 'Something went wrong. Please try again.',
    };
  }
}
