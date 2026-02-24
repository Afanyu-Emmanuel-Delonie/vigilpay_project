import 'package:flutter/foundation.dart';

import '../../../../core/utils/request_state.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/usecases/load_session_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required LoginUseCase loginUseCase,
    required LoadSessionUseCase loadSessionUseCase,
    required LogoutUseCase logoutUseCase,
    required RegisterUseCase registerUseCase,
  })  : _loginUseCase = loginUseCase,
        _loadSessionUseCase = loadSessionUseCase,
        _logoutUseCase = logoutUseCase,
        _registerUseCase = registerUseCase;

  final LoginUseCase _loginUseCase;
  final LoadSessionUseCase _loadSessionUseCase;
  final LogoutUseCase _logoutUseCase;
  final RegisterUseCase _registerUseCase;

  RequestState _loginState    = RequestState.idle;
  RequestState _sessionState  = RequestState.idle;
  RequestState _logoutState   = RequestState.idle;
  RequestState _registerState = RequestState.idle;
  String? _errorMessage;
  SessionEntity? _session;

  RequestState get loginState    => _loginState;
  RequestState get sessionState  => _sessionState;
  RequestState get logoutState   => _logoutState;
  RequestState get registerState => _registerState;
  String?      get errorMessage  => _errorMessage;
  SessionEntity? get session     => _session;
  bool get isAuthenticated       => _session != null;

  // ─────────────────────────────────────────
  //  Login
  // ─────────────────────────────────────────
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _loginState = RequestState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _session = await _loginUseCase(email: email, password: password);
      _loginState = RequestState.success;
    } catch (error) {
      _loginState = RequestState.error;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────
  //  Register
  // ─────────────────────────────────────────
  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    _registerState = RequestState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _registerUseCase(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
      );
      _registerState = RequestState.success;
    } catch (error) {
      _registerState = RequestState.error;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────
  //  Load session
  // ─────────────────────────────────────────
  Future<void> loadSession() async {
    _sessionState = RequestState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _session = await _loadSessionUseCase();
      _sessionState = RequestState.success;
    } catch (error) {
      _sessionState = RequestState.error;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────
  //  Logout
  // ─────────────────────────────────────────
  Future<void> logout() async {
    _logoutState = RequestState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _logoutUseCase();
      _session = null;
      _logoutState = RequestState.success;
    } catch (error) {
      _logoutState = RequestState.error;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }
}