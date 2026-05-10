import 'package:cookie_jar/cookie_jar.dart';
import 'package:gym_buddy_app/core/session/secure_session_store.dart';
import 'package:gym_buddy_app/core/session/session_snapshot.dart';
import 'package:gym_buddy_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:gym_buddy_app/features/auth/data/dto/token_response_dto.dart';
import 'package:gym_buddy_app/features/auth/data/mappers/session_mapper.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_session_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/repositories/session_repository.dart';

class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureSessionStore sessionStore,
    required SessionMapper mapper,
    required PersistCookieJar cookieJar,
  }) : _remoteDataSource = remoteDataSource,
       _sessionStore = sessionStore,
       _mapper = mapper,
       _cookieJar = cookieJar;

  final AuthRemoteDataSource _remoteDataSource;
  final SecureSessionStore _sessionStore;
  final SessionMapper _mapper;
  final PersistCookieJar _cookieJar;

  @override
  Future<void> refresh() async {
    final response = await _remoteDataSource.refresh();
    await _sessionStore.save(_snapshotFrom(response));
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      await clearLocalSession();
    }
  }

  @override
  Future<void> logoutAll() async {
    try {
      await _remoteDataSource.logoutAll();
    } finally {
      await clearLocalSession();
    }
  }

  @override
  Future<List<AuthSessionUiModel>> listSessions() async {
    final currentSession = await _sessionStore.read();
    final sessions = await _remoteDataSource.listSessions();
    return _mapper.fromDtos(
      sessions,
      currentSessionId: currentSession?.sessionId,
    );
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    await _remoteDataSource.revokeSession(sessionId);
    final currentSession = await _sessionStore.read();
    if (currentSession?.sessionId == sessionId) {
      await clearLocalSession();
    }
  }

  Future<void> clearLocalSession() async {
    await _sessionStore.clear();
    await _cookieJar.deleteAll();
  }

  SessionSnapshot _snapshotFrom(TokenResponseDto response) {
    return SessionSnapshot(
      accessToken: response.accessToken,
      accessTokenExpiresAt: response.accessTokenExpiresAt,
      sessionId: response.sessionId,
    );
  }
}
