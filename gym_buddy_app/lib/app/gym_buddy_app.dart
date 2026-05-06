import 'package:flutter/material.dart';
import 'package:gym_buddy_app/app/app_theme.dart';
import 'package:gym_buddy_app/features/auth/presentation/auth_screen.dart';

class GymBuddyApp extends StatelessWidget {
  const GymBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymBuddy Connect',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthScreen(),
    );
  }
}
