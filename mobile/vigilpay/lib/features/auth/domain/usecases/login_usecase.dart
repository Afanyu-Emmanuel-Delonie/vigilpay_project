import '../entities/session_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<SessionEntity> call({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }
}
