import 'package:dio/dio.dart';
import 'package:gym_buddy_app/core/config/app_config.dart';

class DioClientFactory {
  const DioClientFactory();

  Dio create(AppConfig config) {
    return Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: const {'Content-Type': 'application/json'},
      ),
    );
  }
}
