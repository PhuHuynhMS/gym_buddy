import 'package:flutter/material.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/bootstrap_auth_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/list_sessions_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_all_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/register_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/revoke_session_use_case.dart';
import 'package:gym_buddy_app/features/auth/presentation/auth_screen.dart';
import 'package:gym_buddy_app/features/home/home_screen.dart';

class BootstrapGate extends StatefulWidget {
  const BootstrapGate({
    required this.bootstrapAuthUseCase,
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.logoutAllUseCase,
    required this.listSessionsUseCase,
    required this.revokeSessionUseCase,
    super.key,
  });

  final BootstrapAuthUseCase bootstrapAuthUseCase;
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final LogoutAllUseCase logoutAllUseCase;
  final ListSessionsUseCase listSessionsUseCase;
  final RevokeSessionUseCase revokeSessionUseCase;

  @override
  State<BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<BootstrapGate> {
  late Future<BootstrapAuthResult> _bootstrap;
  AuthUiModel? _authenticatedUser;

  @override
  void initState() {
    super.initState();
    _bootstrap = widget.bootstrapAuthUseCase();
  }

  void _retryBootstrap() {
    setState(() {
      _bootstrap = widget.bootstrapAuthUseCase();
    });
  }

  void _setAuthenticated(AuthUiModel auth) {
    setState(() {
      _authenticatedUser = auth;
    });
  }

  void _setUnauthenticated() {
    setState(() {
      _authenticatedUser = null;
      _bootstrap = Future.value(const BootstrapUnauthenticated());
    });
  }

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = _authenticatedUser;
    if (authenticatedUser != null) {
      return _home(authenticatedUser);
    }

    return FutureBuilder<BootstrapAuthResult>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _BootstrapLoadingScreen();
        }

        final result = snapshot.data ?? const BootstrapUnauthenticated();
        return switch (result) {
          BootstrapAuthenticated(:final auth) => _home(auth),
          BootstrapRecoverableError(:final message) => RetrySessionScreen(
            message: message,
            onRetry: _retryBootstrap,
            onLogout: () async {
              await widget.logoutUseCase();
              _setUnauthenticated();
            },
          ),
          BootstrapUnauthenticated() => _auth(),
        };
      },
    );
  }

  Widget _auth() {
    return AuthScreen(
      loginUseCase: widget.loginUseCase,
      registerUseCase: widget.registerUseCase,
      logoutUseCase: widget.logoutUseCase,
      logoutAllUseCase: widget.logoutAllUseCase,
      listSessionsUseCase: widget.listSessionsUseCase,
      revokeSessionUseCase: widget.revokeSessionUseCase,
      onAuthenticated: _setAuthenticated,
    );
  }

  Widget _home(AuthUiModel auth) {
    return HomeScreen(
      auth: auth,
      logoutUseCase: widget.logoutUseCase,
      logoutAllUseCase: widget.logoutAllUseCase,
      listSessionsUseCase: widget.listSessionsUseCase,
      revokeSessionUseCase: widget.revokeSessionUseCase,
      onSignedOut: _setUnauthenticated,
    );
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class RetrySessionScreen extends StatelessWidget {
  const RetrySessionScreen({
    required this.message,
    required this.onRetry,
    required this.onLogout,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.sync_problem,
                  size: 42,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 18),
                Text(
                  'Session check failed',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    await onLogout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
