import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gym_buddy_app/core/session/session_snapshot.dart';

class SecureSessionStore {
  const SecureSessionStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const _accessTokenKey = 'auth.accessToken';
  static const _accessTokenExpiresAtKey = 'auth.accessTokenExpiresAt';
  static const _sessionIdKey = 'auth.sessionId';

  final FlutterSecureStorage _storage;

  Future<void> save(SessionSnapshot snapshot) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: snapshot.accessToken),
      _storage.write(
        key: _accessTokenExpiresAtKey,
        value: snapshot.accessTokenExpiresAt.toIso8601String(),
      ),
      _storage.write(key: _sessionIdKey, value: snapshot.sessionId),
    ]);
  }

  Future<SessionSnapshot?> read() async {
    final values = await Future.wait([
      _storage.read(key: _accessTokenKey),
      _storage.read(key: _accessTokenExpiresAtKey),
      _storage.read(key: _sessionIdKey),
    ]);

    final accessToken = values[0];
    final expiresAtRaw = values[1];
    final sessionId = values[2];
    final expiresAt = expiresAtRaw == null
        ? null
        : DateTime.tryParse(expiresAtRaw);

    if (accessToken == null || expiresAt == null || sessionId == null) {
      return null;
    }

    return SessionSnapshot(
      accessToken: accessToken,
      accessTokenExpiresAt: expiresAt,
      sessionId: sessionId,
    );
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _accessTokenExpiresAtKey),
      _storage.delete(key: _sessionIdKey),
    ]);
  }
}
