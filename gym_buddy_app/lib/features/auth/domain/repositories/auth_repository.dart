import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';

abstract interface class AuthRepository {
  Future<AuthUiModel> login({
    required String email,
    required String password,
  });

  Future<AuthUiModel> register({
    required String username,
    required String email,
    required String password,
  });
}
