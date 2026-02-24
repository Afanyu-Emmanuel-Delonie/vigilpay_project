import '../entities/session_entity.dart';

abstract class AuthRepository {
  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  });
  Future<SessionEntity> login({required String email, required String password});
  Future<SessionEntity> loadSession();
  Future<void> logout();
}
