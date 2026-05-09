import 'package:gym_buddy_app/features/auth/domain/entities/auth_next_action.dart';

class AuthUiModel {
  const AuthUiModel({
    required this.message,
    required this.displayName,
    required this.email,
    required this.nextAction,
  });

  final String message;
  final String displayName;
  final String email;
  final AuthNextAction nextAction;
}
