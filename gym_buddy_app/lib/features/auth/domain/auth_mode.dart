enum AuthMode { login, register }

extension AuthModeLabel on AuthMode {
  String get label {
    return switch (this) {
      AuthMode.login => 'Login',
      AuthMode.register => 'Register',
    };
  }
}
