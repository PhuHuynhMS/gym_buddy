import 'package:flutter/material.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.auth, super.key});

  final AuthUiModel auth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GymBuddy')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${auth.displayName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              auth.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(auth.message),
          ],
        ),
      ),
    );
  }
}
