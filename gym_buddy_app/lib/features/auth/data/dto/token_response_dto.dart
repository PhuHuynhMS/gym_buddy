class TokenResponseDto {
  const TokenResponseDto({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.tokenType,
    required this.sessionId,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String tokenType;
  final String sessionId;

  factory TokenResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Token response data is invalid.');
    }

    return TokenResponseDto(
      accessToken: _readString(data, 'accessToken'),
      accessTokenExpiresAt: _readDateTime(data, 'accessTokenExpiresAt'),
      tokenType: _readString(data, 'tokenType'),
      sessionId: _readString(data, 'sessionId'),
    );
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
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
