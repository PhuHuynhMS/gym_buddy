class ProfileResponseDto {
  const ProfileResponseDto({required this.message, required this.user});

  final String message;
  final ProfileUserDto user;

  factory ProfileResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Profile response data is invalid.');
    }

    final user = data['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Profile response user is invalid.');
    }

    return ProfileResponseDto(
      message: _readString(json, 'message'),
      user: ProfileUserDto.fromJson(user),
    );
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value.trim();
    }

    throw FormatException('$key is required.');
  }
}

class ProfileUserDto {
  const ProfileUserDto({
    required this.id,
    required this.username,
    required this.email,
  });

  final String id;
  final String username;
  final String email;

  factory ProfileUserDto.fromJson(Map<String, dynamic> json) {
    return ProfileUserDto(
      id: ProfileResponseDto._readString(json, 'id'),
      username: ProfileResponseDto._readString(json, 'username'),
      email: ProfileResponseDto._readString(json, 'email'),
    );
  }
}
