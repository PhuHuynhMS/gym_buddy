import 'package:gym_buddy_app/features/auth/domain/repositories/session_repository.dart';

class RevokeSessionUseCase {
  const RevokeSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<void> call(String sessionId) => _repository.revokeSession(sessionId);
}
