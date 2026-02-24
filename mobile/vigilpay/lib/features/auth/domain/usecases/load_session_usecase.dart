import '../entities/session_entity.dart';
import '../repositories/auth_repository.dart';

class LoadSessionUseCase {
  LoadSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<SessionEntity> call() {
    return _repository.loadSession();
  }
}
