import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureDevCertificateTrust(Dio dio, {required Uri apiBaseUri}) {
  var isDebugBuild = false;
  assert(() {
    isDebugBuild = true;
    return true;
  }());

  if (!isDebugBuild) {
    return;
  }

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        return host == apiBaseUri.host &&
            port == apiBaseUri.port &&
            cert.issuer.contains('GymBuddy Dev CA');
      };
      return client;
    },
  );
}
