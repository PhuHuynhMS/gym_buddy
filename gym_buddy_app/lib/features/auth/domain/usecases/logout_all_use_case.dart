import 'package:gym_buddy_app/features/auth/domain/repositories/session_repository.dart';

class LogoutAllUseCase {
  const LogoutAllUseCase(this._repository);

  final SessionRepository _repository;

  Future<void> call() => _repository.logoutAll();
}
