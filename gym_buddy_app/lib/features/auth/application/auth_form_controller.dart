import 'package:flutter/foundation.dart';
import 'package:gym_buddy_app/features/auth/domain/auth_mode.dart';

class AuthFormController extends ChangeNotifier {
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<String> submit(AuthMode mode) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return switch (mode) {
        AuthMode.login => 'Login form is ready to connect API',
        AuthMode.register => 'Register form is ready to connect API',
      };
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return _errorMessage!;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
