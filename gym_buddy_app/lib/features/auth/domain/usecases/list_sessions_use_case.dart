import 'package:gym_buddy_app/features/auth/domain/entities/auth_session_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/repositories/session_repository.dart';

class ListSessionsUseCase {
  const ListSessionsUseCase(this._repository);

  final SessionRepository _repository;

  Future<List<AuthSessionUiModel>> call() => _repository.listSessions();
}
