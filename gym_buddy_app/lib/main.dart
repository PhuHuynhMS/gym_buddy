import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy_app/app/gym_buddy_app.dart';
import 'package:gym_buddy_app/core/config/app_config_loader.dart';
import 'package:gym_buddy_app/core/device/device_info_provider.dart';
import 'package:gym_buddy_app/core/network/dio_client_factory.dart';
import 'package:gym_buddy_app/core/session/auth_token_interceptor.dart';
import 'package:gym_buddy_app/core/session/cookie_store_factory.dart';
import 'package:gym_buddy_app/core/session/secure_session_store.dart';
import 'package:gym_buddy_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:gym_buddy_app/features/auth/data/mappers/auth_ui_model_mapper.dart';
import 'package:gym_buddy_app/features/auth/data/mappers/session_mapper.dart';
import 'package:gym_buddy_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gym_buddy_app/features/auth/data/repositories/session_repository_impl.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/bootstrap_auth_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/list_sessions_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_all_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/register_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/revoke_session_use_case.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await const AppConfigLoader().load();
  final dio = const DioClientFactory().create(config);
  const sessionStore = SecureSessionStore();
  final cookieJar = await const CookieStoreFactory().create();
  dio.interceptors.add(CookieManager(cookieJar));
  final remoteDataSource = AuthRemoteDataSource(
    dio: dio,
    deviceInfoProvider: DeviceInfoProvider(),
  );
  final repository = AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    mapper: const AuthUiModelMapper(),
    sessionStore: sessionStore,
  );
  final sessionRepository = SessionRepositoryImpl(
    remoteDataSource: remoteDataSource,
    sessionStore: sessionStore,
    mapper: const SessionMapper(),
    cookieJar: cookieJar,
  );
  dio.interceptors.add(
    AuthTokenInterceptor(
      dio: dio,
      sessionStore: sessionStore,
      refreshSession: sessionRepository.refresh,
    ),
  );

  runApp(
    GymBuddyApp(
      bootstrapAuthUseCase: BootstrapAuthUseCase(
        sessionStore: sessionStore,
        sessionRepository: sessionRepository,
        authRepository: repository,
      ),
      loginUseCase: LoginUseCase(repository),
      registerUseCase: RegisterUseCase(repository),
      logoutUseCase: LogoutUseCase(sessionRepository),
      logoutAllUseCase: LogoutAllUseCase(sessionRepository),
      listSessionsUseCase: ListSessionsUseCase(sessionRepository),
      revokeSessionUseCase: RevokeSessionUseCase(sessionRepository),
    ),
  );
}
