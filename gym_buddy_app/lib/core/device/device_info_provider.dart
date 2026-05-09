import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoProvider {
  DeviceInfoProvider({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  Future<Map<String, String>> authHeaders() async {
    final platform = defaultTargetPlatform.name.toLowerCase();
    final deviceName = await _deviceNameForPlatform();

    return {'X-Device-Name': deviceName, 'X-Device-Platform': platform};
  }

  Future<String> _deviceNameForPlatform() async {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidName(),
      TargetPlatform.iOS => _iosName(),
      _ => defaultTargetPlatform.name,
    };
  }

  Future<String> _androidName() async {
    final info = await _plugin.androidInfo;
    return [
      info.manufacturer,
      info.model,
    ].where((value) => value.trim().isNotEmpty).join(' ').trim();
  }

  Future<String> _iosName() async {
    final info = await _plugin.iosInfo;
    return info.name.trim().isNotEmpty ? info.name : info.model;
  }
}
