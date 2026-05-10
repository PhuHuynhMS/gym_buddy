import 'package:gym_buddy_app/core/session/secure_session_store.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:gym_buddy_app/features/auth/domain/repositories/session_repository.dart';

sealed class BootstrapAuthResult {
  const BootstrapAuthResult();
}

class BootstrapAuthenticated extends BootstrapAuthResult {
  const BootstrapAuthenticated(this.auth);

  final AuthUiModel auth;
}

class BootstrapUnauthenticated extends BootstrapAuthResult {
  const BootstrapUnauthenticated();
}

class BootstrapRecoverableError extends BootstrapAuthResult {
  const BootstrapRecoverableError(this.message);

  final String message;
}

class BootstrapAuthUseCase {
  const BootstrapAuthUseCase({
    required SecureSessionStore sessionStore,
    required SessionRepository sessionRepository,
    required AuthRepository authRepository,
  }) : _sessionStore = sessionStore,
       _sessionRepository = sessionRepository,
       _authRepository = authRepository;

  final SecureSessionStore _sessionStore;
  final SessionRepository _sessionRepository;
  final AuthRepository _authRepository;

  Future<BootstrapAuthResult> call() async {
    final session = await _sessionStore.read();
    if (session == null) {
      return const BootstrapUnauthenticated();
    }

    try {
      if (session.isNearExpiry) {
        await _sessionRepository.refresh();
      }

      final profile = await _authRepository.profile();
      return BootstrapAuthenticated(profile);
    } catch (error) {
      return BootstrapRecoverableError(error.toString());
    }
  }
}
