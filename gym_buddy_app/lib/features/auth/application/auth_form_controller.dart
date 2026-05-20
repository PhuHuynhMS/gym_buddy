import 'package:flutter/foundation.dart';
import 'package:gym_buddy_app/core/errors/app_failure.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/register_use_case.dart';

class AuthFormController extends ChangeNotifier {
  AuthFormController({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase;

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<AuthUiModel> login({
    required String email,
    required String password,
  }) async {
    return _submit(
      () => _loginUseCase(email: email.trim(), password: password),
    );
  }

  Future<AuthUiModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return _submit(
      () => _registerUseCase(
        username: username.trim(),
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<AuthUiModel> _submit(Future<AuthUiModel> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await action();
    } on AppFailure catch (error) {
      _errorMessage = error.message;
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Unexpected auth form error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = kDebugMode
          ? 'Unexpected auth error: $error'
          : 'Something went wrong. Please try again.';
      throw AppFailure(_errorMessage!);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
