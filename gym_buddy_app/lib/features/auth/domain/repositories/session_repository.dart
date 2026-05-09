import 'package:gym_buddy_app/features/auth/domain/entities/auth_session_ui_model.dart';

abstract interface class SessionRepository {
  Future<void> refresh();

  Future<void> logout();

  Future<void> logoutAll();

  Future<List<AuthSessionUiModel>> listSessions();

  Future<void> revokeSession(String sessionId);
}
