import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:gym_buddy_app/core/config/app_config.dart';

class AppConfigLoader {
  const AppConfigLoader({AssetBundle? assetBundle})
    : _assetBundle = assetBundle;

  final AssetBundle? _assetBundle;

  Future<AppConfig> load() async {
    final bundle = _assetBundle ?? rootBundle;
    final rawConfig = await bundle.loadString('assets/config/app_config.json');
    final json = jsonDecode(rawConfig);

    if (json is! Map<String, dynamic>) {
      throw const FormatException('App config must be a JSON object');
    }

    return AppConfig.fromJson(json);
  }
}
