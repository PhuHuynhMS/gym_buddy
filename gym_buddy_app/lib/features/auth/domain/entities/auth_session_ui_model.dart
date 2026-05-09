class AuthSessionUiModel {
  const AuthSessionUiModel({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.lastUsedAt,
    required this.createdAt,
    required this.isCurrentDevice,
  });

  final String id;
  final String deviceName;
  final String platform;
  final DateTime lastUsedAt;
  final DateTime createdAt;
  final bool isCurrentDevice;
}
