class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.authProvider,
    this.avatarUrl,
  });

  final int id;
  final String email;
  final String fullName;
  final String authProvider;
  final String? avatarUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: (json['email'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ?? '',
      authProvider: (json['auth_provider'] as String?) ?? 'email',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
