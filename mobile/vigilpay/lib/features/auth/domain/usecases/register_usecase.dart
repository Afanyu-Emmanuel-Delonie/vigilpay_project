import '../repositories/auth_repository.dart';

class RegisterUseCase {
  RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) {
    return _repository.register(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      password: password,
    );
  }
}
