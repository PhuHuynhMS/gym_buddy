import 'package:dio/dio.dart';
import 'package:gym_buddy_app/core/session/secure_session_store.dart';

class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor({
    required Dio dio,
    required SecureSessionStore sessionStore,
    required Future<void> Function() refreshSession,
  }) : _dio = dio,
       _sessionStore = sessionStore,
       _refreshSession = refreshSession;

  final Dio _dio;
  final SecureSessionStore _sessionStore;
  final Future<void> Function() _refreshSession;
  Future<void>? _refreshInFlight;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final session = await _sessionStore.read();
    if (session != null && !session.isExpired) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRefresh(err)) {
      handler.next(err);
      return;
    }

    try {
      await _refreshOnce();
      final session = await _sessionStore.read();
      if (session == null) {
        handler.next(err);
        return;
      }

      final requestOptions = err.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer ${session.accessToken}';
      requestOptions.extra['retriedAfterRefresh'] = true;

      final response = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } catch (_) {
      await _sessionStore.clear();
      handler.next(err);
    }
  }

  bool _shouldRefresh(DioException err) {
    if (err.response?.statusCode != 401) {
      return false;
    }
    if (err.requestOptions.extra['retriedAfterRefresh'] == true) {
      return false;
    }
    if (err.requestOptions.path.contains('/auth/refresh')) {
      return false;
    }

    final data = err.response?.data;
    if (data is Map<String, dynamic>) {
      return data['code'] == 'TOKEN_EXPIRED';
    }

    return false;
  }

  Future<void> _refreshOnce() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final refresh = _refreshSession();
    _refreshInFlight = refresh;
    refresh.whenComplete(() {
      _refreshInFlight = null;
    });
    return refresh;
  }
}
