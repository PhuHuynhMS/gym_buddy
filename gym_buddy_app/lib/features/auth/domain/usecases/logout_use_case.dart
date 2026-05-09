import 'package:gym_buddy_app/features/auth/domain/repositories/session_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final SessionRepository _repository;

  Future<void> call() => _repository.logout();
}
