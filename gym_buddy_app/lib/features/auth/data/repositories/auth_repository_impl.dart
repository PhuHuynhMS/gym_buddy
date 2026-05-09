import 'package:gym_buddy_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:gym_buddy_app/features/auth/data/mappers/auth_ui_model_mapper.dart';
import 'package:gym_buddy_app/features/auth/domain/entities/auth_ui_model.dart';
import 'package:gym_buddy_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthUiModelMapper mapper,
  }) : _remoteDataSource = remoteDataSource,
       _mapper = mapper;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthUiModelMapper _mapper;

  @override
  Future<AuthUiModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    return _mapper.fromAuthResponse(response);
  }

  @override
  Future<AuthUiModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.register(
      username: username,
      email: email,
      password: password,
    );
    return _mapper.fromAuthResponse(response);
  }
}
