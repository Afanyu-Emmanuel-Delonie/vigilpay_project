import '../../domain/entities/session_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_gateway.dart';
import '../models/session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthGateway gateway}) : _gateway = gateway;

  final AuthGateway _gateway;

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) {
    return _gateway.register(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      password: password,
    );
  }

  @override
  Future<SessionEntity> login({required String email, required String password}) async {
    final response = await _gateway.login(email: email, password: password);
    return SessionModel.fromJson(response);
  }

  @override
  Future<SessionEntity> loadSession() async {
    final response = await _gateway.fetchProfile();
    return SessionModel.fromJson(response);
  }

  @override
  Future<void> logout() {
    return _gateway.logout();
  }
}
