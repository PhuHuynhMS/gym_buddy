import 'package:gym_buddy_app/features/auth/data/dto/auth_response_dto.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_next_action.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';

class AuthUiModelMapper {
  const AuthUiModelMapper();

  AuthUiModel fromAuthResponse(AuthResponseDto dto) {
    return AuthUiModel(
      message: dto.message,
      displayName: dto.user.username,
      email: dto.user.email,
      nextAction: AuthNextAction.goHome,
    );
  }
}
