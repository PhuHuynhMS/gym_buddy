import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/app/gym_buddy_app.dart';
import 'package:gym_buddy_app/core/session/secure_session_store.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_next_action.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_session_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:gym_buddy_app/features/auth/domain/repositories/session_repository.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/bootstrap_auth_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/list_sessions_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_all_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/register_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/revoke_session_use_case.dart';

Future<void> pumpAuthApp(WidgetTester tester) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  await binding.setSurfaceSize(const Size(430, 900));
  addTearDown(() => binding.setSurfaceSize(null));
  final repository = _FakeAuthRepository();
  final sessionRepository = _FakeSessionRepository();
  await tester.pumpWidget(
    GymBuddyApp(
      bootstrapAuthUseCase: _FakeBootstrapAuthUseCase(),
      loginUseCase: LoginUseCase(repository),
      registerUseCase: RegisterUseCase(repository),
      logoutUseCase: LogoutUseCase(sessionRepository),
      logoutAllUseCase: LogoutAllUseCase(sessionRepository),
      listSessionsUseCase: ListSessionsUseCase(sessionRepository),
      revokeSessionUseCase: RevokeSessionUseCase(sessionRepository),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the login screen first', (tester) async {
    await pumpAuthApp(tester);

    expect(find.text('GymBuddy'), findsOneWidget);
    expect(find.text('Find a gym partner nearby.'), findsOneWidget);
    expect(find.text('Linh + Minh matched'), findsOneWidget);
    expect(find.byKey(const Key('login-submit-button')), findsOneWidget);
  });

  testWidgets('switches to the register screen', (tester) async {
    await pumpAuthApp(tester);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register-submit-button')), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });

  testWidgets('shows validation errors for an empty login form', (
    tester,
  ) async {
    await pumpAuthApp(tester);

    final loginButton = find.byKey(const Key('login-submit-button'));
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('toggles password visibility', (tester) async {
    await pumpAuthApp(tester);

    expect(find.byTooltip('Show password'), findsOneWidget);
    expect(find.byTooltip('Hide password'), findsNothing);

    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    expect(find.byTooltip('Show password'), findsNothing);
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('navigates home after a valid login submit', (tester) async {
    await pumpAuthApp(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'tester@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    final loginButton = find.byKey(const Key('login-submit-button'));
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Test User'), findsOneWidget);
    expect(find.text('tester@example.com'), findsOneWidget);
    expect(find.text('Login successful'), findsWidgets);
  });

  testWidgets('requires terms acceptance before register submit', (
    tester,
  ) async {
    await pumpAuthApp(tester);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'linh',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'linh@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'secret123',
    );
    final registerButton = find.byKey(const Key('register-submit-button'));
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump();

    expect(
      find.text('Accept the terms to create your account'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('register-terms-checkbox')),
    );
    await tester.tap(find.byKey(const Key('register-terms-checkbox')));
    await tester.pump();
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(find.text('Welcome, linh'), findsOneWidget);
    expect(find.text('linh@example.com'), findsOneWidget);
    expect(find.text('Register successful'), findsWidgets);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUiModel> login({
    required String email,
    required String password,
  }) async {
    return AuthUiModel(
      message: 'Login successful',
      displayName: 'Test User',
      email: email,
      nextAction: AuthNextAction.goHome,
    );
  }

  @override
  Future<AuthUiModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return AuthUiModel(
      message: 'Register successful',
      displayName: username,
      email: email,
      nextAction: AuthNextAction.goHome,
    );
  }

  @override
  Future<AuthUiModel> profile() async {
    return const AuthUiModel(
      message: 'Profile fetched successfully',
      displayName: 'Test User',
      email: 'tester@example.com',
      nextAction: AuthNextAction.goHome,
    );
  }
}

class _FakeBootstrapAuthUseCase extends BootstrapAuthUseCase {
  _FakeBootstrapAuthUseCase()
    : super(
        sessionStore: const SecureSessionStore(),
        sessionRepository: _FakeSessionRepository(),
        authRepository: _FakeAuthRepository(),
      );

  @override
  Future<BootstrapAuthResult> call() async {
    return const BootstrapUnauthenticated();
  }
}

class _FakeSessionRepository implements SessionRepository {
  @override
  Future<List<AuthSessionUiModel>> listSessions() async {
    return [
      AuthSessionUiModel(
        id: 'session-1',
        deviceName: 'Test Device',
        platform: 'android',
        lastUsedAt: DateTime(2026),
        createdAt: DateTime(2026),
        isCurrentDevice: true,
      ),
    ];
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutAll() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> revokeSession(String sessionId) async {}
}
