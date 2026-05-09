class AuthResponseDto {
  const AuthResponseDto({
    required this.message,
    required this.user,
    required this.token,
    required this.tokenType,
    required this.expiresIn,
  });

  final String message;
  final AuthUserDto user;
  final String token;
  final String tokenType;
  final String expiresIn;

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
      token: _readString(data, 'token'),
      tokenType: _readString(data, 'tokenType'),
      expiresIn: _readString(data, 'expiresIn'),
    );
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    throw FormatException('$key is required.');
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
