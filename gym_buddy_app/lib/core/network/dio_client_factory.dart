import 'package:dio/dio.dart';
import 'package:gym_buddy_app/core/config/app_config.dart';
import 'package:gym_buddy_app/core/network/dev_certificate_trust.dart';

class DioClientFactory {
  const DioClientFactory();

  Dio create(AppConfig config) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    configureDevCertificateTrust(dio, apiBaseUri: Uri.parse(config.apiBaseUrl));

    return dio;
  }
}
