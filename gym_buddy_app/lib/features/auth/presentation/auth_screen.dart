import 'package:flutter/material.dart';
import 'package:gym_buddy_app/core/errors/app_failure.dart';
import 'package:gym_buddy_app/features/auth/application/auth_form_controller.dart';
import 'package:gym_buddy_app/features/auth/domain/auth_mode.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_next_action.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/list_sessions_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_all_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/register_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/revoke_session_use_case.dart';
import 'package:gym_buddy_app/features/auth/presentation/brand_mark.dart';
import 'package:gym_buddy_app/features/auth/presentation/login_form.dart';
import 'package:gym_buddy_app/features/auth/presentation/register_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.logoutAllUseCase,
    required this.listSessionsUseCase,
    required this.revokeSessionUseCase,
    required this.onAuthenticated,
    super.key,
  });

  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final LogoutAllUseCase logoutAllUseCase;
  final ListSessionsUseCase listSessionsUseCase;
  final RevokeSessionUseCase revokeSessionUseCase;
  final ValueChanged<AuthUiModel> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final AuthFormController _controller;
  AuthMode _mode = AuthMode.login;

  @override
  void initState() {
    super.initState();
    _controller = AuthFormController(
      loginUseCase: widget.loginUseCase,
      registerUseCase: widget.registerUseCase,
    );
    _controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChange)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setMode(AuthMode mode) {
    if (_mode == mode || _controller.isSubmitting) {
      return;
    }
    setState(() {
      _mode = mode;
    });
  }

  Future<void> _submitLogin({
    required String email,
    required String password,
  }) async {
    await _submit(() => _controller.login(email: email, password: password));
  }

  Future<void> _submitRegister({
    required String username,
    required String email,
    required String password,
  }) async {
    await _submit(
      () => _controller.register(
        username: username,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> _submit(Future<AuthUiModel> Function() action) async {
    late final AuthUiModel auth;
    try {
      auth = await action();
    } on AppFailure catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(message: error.message, isError: true);
      return;
    }

    if (!mounted) {
      return;
    }

    _showSnackBar(message: auth.message);
    if (auth.nextAction == AuthNextAction.goHome) {
      widget.onAuthenticated(auth);
    }
  }

  void _showSnackBar({required String message, bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroPanel(mode: _mode),
                        const SizedBox(height: 18),
                        _ModeSwitch(
                          mode: _mode,
                          onChanged: _setMode,
                          enabled: !_controller.isSubmitting,
                        ),
                        const SizedBox(height: 16),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E0D8)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 18,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _mode == AuthMode.login
                                  ? LoginForm(
                                      key: const ValueKey(AuthMode.login),
                                      isSubmitting: _controller.isSubmitting,
                                      onSubmit: _submitLogin,
                                    )
                                  : RegisterForm(
                                      key: const ValueKey(AuthMode.register),
                                      isSubmitting: _controller.isSubmitting,
                                      onSubmit: _submitRegister,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.mode});

  final AuthMode mode;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF173B30);
    const accent = Color(0xFFF2B84B);
    const heart = Color(0xFFF05A5A);
    const activeGreen = Color(0xFF16A34A);
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: BrandMark(
                      size: 30,
                      foregroundColor: heart,
                      accentColor: accent,
                      connectionColor: activeGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'GymBuddy',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      'BETA',
                      style: textTheme.labelSmall?.copyWith(
                        color: background,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              mode == AuthMode.login
                  ? 'Find a gym partner nearby.'
                  : 'Meet someone who matches your training rhythm.',
              style: textTheme.headlineLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              mode == AuthMode.login
                  ? 'Match by location, schedule, and training goal before you head out.'
                  : 'Build a profile for nearby workouts, check-ins, and real training connections.',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(
                  child: _MetricPill(
                    value: '24',
                    label: 'nearby today',
                    icon: Icons.location_on_outlined,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _MetricPill(
                    value: '8',
                    label: 'checked in',
                    icon: Icons.favorite_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _MatchPreview(),
          ],
        ),
      ),
    );
  }
}

class _MatchPreview extends StatelessWidget {
  const _MatchPreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const _AvatarPair(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Linh + Minh matched',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '1.8km away · Push day · 7:00 PM',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFFF2B84B)),
          ],
        ),
      ),
    );
  }
}

class _AvatarPair extends StatelessWidget {
  const _AvatarPair();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 34,
      child: Stack(
        children: [
          _AvatarBubble(
            color: const Color(0xFF60A5FA),
            icon: Icons.male,
            alignment: Alignment.centerLeft,
          ),
          _AvatarBubble(
            color: const Color(0xFFF9A8D4),
            icon: Icons.female,
            alignment: Alignment.centerRight,
          ),
        ],
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({
    required this.color,
    required this.icon,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: SizedBox.square(
          dimension: 34,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFF2B84B), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.mode,
    required this.onChanged,
    required this.enabled,
  });

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AuthMode>(
      style: ButtonStyle(
        visualDensity: VisualDensity.standard,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
      segments: AuthMode.values
          .map(
            (mode) =>
                ButtonSegment<AuthMode>(value: mode, label: Text(mode.label)),
          )
          .toList(),
      selected: {mode},
      onSelectionChanged: enabled
          ? (selection) {
              onChanged(selection.first);
            }
          : null,
    );
  }
}
