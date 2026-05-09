import 'package:flutter/material.dart';
import 'package:gym_buddy_app/app/app_theme.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/register_use_case.dart';
import 'package:gym_buddy_app/features/auth/presentation/auth_screen.dart';

class GymBuddyApp extends StatelessWidget {
  const GymBuddyApp({
    required this.loginUseCase,
    required this.registerUseCase,
    super.key,
  });

  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymBuddy Connect',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AuthScreen(
        loginUseCase: loginUseCase,
        registerUseCase: registerUseCase,
      ),
    );
  }
}
