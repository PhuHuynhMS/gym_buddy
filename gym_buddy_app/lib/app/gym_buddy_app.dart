import 'package:flutter/material.dart';
import 'package:gym_buddy_app/app/app_theme.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/list_sessions_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_all_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/register_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/revoke_session_use_case.dart';
import 'package:gym_buddy_app/features/auth/presentation/auth_screen.dart';

class GymBuddyApp extends StatelessWidget {
  const GymBuddyApp({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.logoutAllUseCase,
    required this.listSessionsUseCase,
    required this.revokeSessionUseCase,
    super.key,
  });

  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final LogoutAllUseCase logoutAllUseCase;
  final ListSessionsUseCase listSessionsUseCase;
  final RevokeSessionUseCase revokeSessionUseCase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymBuddy Connect',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AuthScreen(
        loginUseCase: loginUseCase,
        registerUseCase: registerUseCase,
        logoutUseCase: logoutUseCase,
        logoutAllUseCase: logoutAllUseCase,
        listSessionsUseCase: listSessionsUseCase,
        revokeSessionUseCase: revokeSessionUseCase,
      ),
    );
  }
}
