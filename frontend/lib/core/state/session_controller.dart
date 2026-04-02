import 'package:flutter/foundation.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/data/user_profile.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required this.authRepository,
    required this.profileRepository,
    required this.firebaseReady,
  });

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final bool firebaseReady;

  UserProfile? _currentUser;
  bool _isLoading = false;
  bool _isBootstrapping = true;
  String? _errorMessage;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isBootstrapping => _isBootstrapping;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  Future<void> bootstrap() async {
    _setBootstrapping(true);
    try {
      _currentUser = await profileRepository.me();
      _errorMessage = null;
    } catch (_) {
      _currentUser = null;
    } finally {
      _setBootstrapping(false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    return _handleAuthOperation(() async {
      final result = await authRepository.login(
        email: email,
        password: password,
      );
      await authRepository.persistTokens(result);
      _currentUser = result.user;
    });
  }

  Future<bool> signup({
    required String email,
    required String fullName,
    required String password,
  }) async {
    return _handleAuthOperation(() async {
      final result = await authRepository.signup(
        email: email,
        fullName: fullName,
        password: password,
      );
      await authRepository.persistTokens(result);
      _currentUser = result.user;
    });
  }

  Future<bool> loginWithGoogle() async {
    if (!firebaseReady) {
      _setError(
        'Google sign-in not configured yet. Complete Firebase setup first.',
      );
      notifyListeners();
      return false;
    }

    return _handleAuthOperation(() async {
      final result = await authRepository.loginWithGoogle();
      await authRepository.persistTokens(result);
      _currentUser = result.user;
    });
  }

  Future<bool> refreshProfile() async {
    _setLoading(true);
    try {
      _currentUser = await profileRepository.me();
      _errorMessage = null;
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({String? fullName, String? avatarPath}) async {
    _setLoading(true);
    try {
      _currentUser = await profileRepository.updateProfile(
        fullName: fullName,
        avatarPath: avatarPath,
      );
      _errorMessage = null;
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await authRepository.logout();
      _currentUser = null;
      _errorMessage = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _handleAuthOperation(Future<void> Function() action) async {
    _setLoading(true);
    try {
      await action();
      _errorMessage = null;
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String value) {
    _errorMessage = value;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setBootstrapping(bool value) {
    _isBootstrapping = value;
    notifyListeners();
  }
}
