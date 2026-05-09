import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUiModel> call({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }
}
