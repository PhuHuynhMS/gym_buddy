import 'package:flutter/material.dart';
import 'package:gym_buddy_app/app/app_theme.dart';
import 'package:gym_buddy_app/app/bootstrap_gate.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/bootstrap_auth_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/list_sessions_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_all_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/register_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/revoke_session_use_case.dart';
import 'package:gym_buddy_app/features/maps/data/buddy_repository.dart';
import 'package:gym_buddy_app/features/maps/data/gym_repository.dart';

class GymBuddyApp extends StatelessWidget {
  const GymBuddyApp({
    required this.bootstrapAuthUseCase,
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.logoutAllUseCase,
    required this.listSessionsUseCase,
    required this.revokeSessionUseCase,
    required this.gymRepository,
    required this.buddyRepository,
    super.key,
  });

  final BootstrapAuthUseCase bootstrapAuthUseCase;
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final LogoutAllUseCase logoutAllUseCase;
  final ListSessionsUseCase listSessionsUseCase;
  final RevokeSessionUseCase revokeSessionUseCase;
  final GymRepository gymRepository;
  final BuddyRepository buddyRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymBuddy Connect',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: BootstrapGate(
        bootstrapAuthUseCase: bootstrapAuthUseCase,
        loginUseCase: loginUseCase,
        registerUseCase: registerUseCase,
        logoutUseCase: logoutUseCase,
        logoutAllUseCase: logoutAllUseCase,
        listSessionsUseCase: listSessionsUseCase,
        revokeSessionUseCase: revokeSessionUseCase,
        gymRepository: gymRepository,
        buddyRepository: buddyRepository,
      ),
    );
  }
}
