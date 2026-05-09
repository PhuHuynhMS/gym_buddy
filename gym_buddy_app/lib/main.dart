import 'package:flutter/material.dart';
import 'package:gym_buddy_app/app/gym_buddy_app.dart';
import 'package:gym_buddy_app/core/config/app_config_loader.dart';
import 'package:gym_buddy_app/core/network/dio_client_factory.dart';
import 'package:gym_buddy_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:gym_buddy_app/features/auth/data/mappers/auth_ui_model_mapper.dart';
import 'package:gym_buddy_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:gym_buddy_app/features/auth/domain/usecases/register_use_case.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await const AppConfigLoader().load();
  final dio = const DioClientFactory().create(config);
  final repository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSource(dio: dio),
    mapper: const AuthUiModelMapper(),
  );

  runApp(
    GymBuddyApp(
      loginUseCase: LoginUseCase(repository),
      registerUseCase: RegisterUseCase(repository),
    ),
  );
}
