import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUiModel> call({
    required String username,
    required String email,
    required String password,
  }) {
    return _repository.register(
      username: username,
      email: email,
      password: password,
    );
  }
}
