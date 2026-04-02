import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../profile/data/user_profile.dart';

class AuthResult {
  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final UserProfile user;
  final String accessToken;
  final String refreshToken;
}

class AuthRepository {
  AuthRepository({required this.apiClient, required this.tokenStorage});

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<AuthResult> signup({
    required String email,
    required String fullName,
    required String password,
  }) async {
    final payload = await apiClient.postJson(
      'auth/signup/',
      body: {'email': email, 'full_name': fullName, 'password': password},
    );
    return _parseAuthPayload(payload);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final payload = await apiClient.postJson(
      'auth/login/',
      body: {'email': email, 'password': password},
    );
    return _parseAuthPayload(payload);
  }

  Future<AuthResult> loginWithGoogle() async {
    final googleSignIn = AppConfig.googleWebClientId.isEmpty
        ? GoogleSignIn()
        : GoogleSignIn(serverClientId: AppConfig.googleWebClientId);

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const ApiException('Google sign-in canceled');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const ApiException('Unable to fetch Google ID token');
    }

    final payload = await apiClient.postJson(
      'auth/google/',
      body: {'id_token': idToken},
    );
    return _parseAuthPayload(payload);
  }

  Future<void> logout() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    final accessToken = await tokenStorage.readAccessToken();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await apiClient.postNoContent(
          'auth/logout/',
          body: {'refresh': refreshToken},
          accessToken: accessToken,
        );
      } catch (_) {
        // Tokens are removed locally even if API logout fails.
      }
    }

    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    await tokenStorage.clearTokens();
  }

  Future<void> persistTokens(AuthResult result) {
    return tokenStorage.saveTokens(
      access: result.accessToken,
      refresh: result.refreshToken,
    );
  }

  AuthResult _parseAuthPayload(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Unexpected server response');
    }

    final tokens = payload['tokens'];
    final userJson = payload['user'];
    if (tokens is! Map<String, dynamic> || userJson is! Map<String, dynamic>) {
      throw const ApiException('Malformed auth payload');
    }

    final access = tokens['access'] as String?;
    final refresh = tokens['refresh'] as String?;
    if (access == null || refresh == null) {
      throw const ApiException('Missing tokens in response');
    }

    return AuthResult(
      user: UserProfile.fromJson(userJson),
      accessToken: access,
      refreshToken: refresh,
    );
  }
}
