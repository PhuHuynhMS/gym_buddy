class SessionDto {
  const SessionDto({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.ipAddress,
    required this.userAgent,
    required this.lastUsedAt,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final String userAgent;
  final DateTime lastUsedAt;
  final DateTime createdAt;
  final DateTime expiresAt;

  factory SessionDto.fromJson(Map<String, dynamic> json) {
    return SessionDto(
      id: _readString(json, 'id'),
      deviceName: _readString(json, 'deviceName'),
      platform: _readString(json, 'platform'),
      ipAddress: _readString(json, 'ipAddress'),
      userAgent: _readString(json, 'userAgent'),
      lastUsedAt: _readDateTime(json, 'lastUsedAt'),
      createdAt: _readDateTime(json, 'createdAt'),
      expiresAt: _readDateTime(json, 'expiresAt'),
    );
  }

  static List<SessionDto> listFromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Sessions response data is invalid.');
    }

    final sessions = data['sessions'];
    if (sessions is! List) {
      throw const FormatException('Sessions must be a list.');
    }

    return sessions
        .whereType<Map<String, dynamic>>()
        .map(SessionDto.fromJson)
        .toList();
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value.trim();
    }

    throw FormatException('$key is required.');
  }

  static DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final parsed = DateTime.tryParse(_readString(json, key));
    if (parsed == null) {
      throw FormatException('$key must be a valid ISO date.');
    }

    return parsed;
  }
}
