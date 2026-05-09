class AuthResponseDto {
  const AuthResponseDto({
    required this.message,
    required this.user,
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.tokenType,
    required this.sessionId,
  });

  final String message;
  final AuthUserDto user;
  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String tokenType;
  final String sessionId;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final message = _readString(json, 'message');
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Auth response data is invalid.');
    }

    final user = data['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Auth response user is invalid.');
    }

    return AuthResponseDto(
      message: message,
      user: AuthUserDto.fromJson(user),
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
    final value = _readString(json, key);
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('$key must be a valid ISO date.');
    }

    return parsed;
  }
}

class AuthUserDto {
  const AuthUserDto({
    required this.id,
    required this.username,
    required this.email,
  });

  final String id;
  final String username;
  final String email;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: AuthResponseDto._readString(json, 'id'),
      username: AuthResponseDto._readString(json, 'username'),
      email: AuthResponseDto._readString(json, 'email'),
    );
  }
}
