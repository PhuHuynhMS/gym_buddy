import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy_app/app/gym_buddy_app.dart';

Future<void> pumpAuthApp(WidgetTester tester) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  await binding.setSurfaceSize(const Size(430, 900));
  addTearDown(() => binding.setSurfaceSize(null));
  await tester.pumpWidget(const GymBuddyApp());
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

  testWidgets('shows snackbar after a valid login submit', (tester) async {
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Login form is ready to connect API'), findsOneWidget);
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Register form is ready to connect API'), findsOneWidget);
  });
}
