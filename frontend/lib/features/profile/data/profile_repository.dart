import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import 'user_profile.dart';

class ProfileRepository {
  ProfileRepository({required this.apiClient, required this.tokenStorage});

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<UserProfile> me() async {
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('Not authenticated');
    }

    final payload = await apiClient.getJson(
      'profile/me/',
      accessToken: accessToken,
    );
    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Unexpected profile response');
    }

    return UserProfile.fromJson(payload);
  }

  Future<UserProfile> updateProfile({
    String? fullName,
    String? avatarPath,
  }) async {
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('Not authenticated');
    }

    final payload = await apiClient.patchMultipart(
      'profile/me/',
      accessToken: accessToken,
      fields: {
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
      },
      filePath: avatarPath,
      fileField: 'avatar',
    );

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Unexpected profile update response');
    }

    return UserProfile.fromJson(payload);
  }
}
