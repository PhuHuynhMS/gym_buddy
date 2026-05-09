class SessionSnapshot {
  const SessionSnapshot({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.sessionId,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String sessionId;

  bool get isExpired => !DateTime.now().isBefore(accessTokenExpiresAt);

  bool get isNearExpiry {
    final now = DateTime.now();
    if (!now.isBefore(accessTokenExpiresAt)) {
      return true;
    }

    final remaining = accessTokenExpiresAt.difference(now);
    const ttl = Duration(minutes: 15);
    return remaining <= ttl * 0.2;
  }
}
