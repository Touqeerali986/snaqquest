import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/state/session_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isPickingAvatar = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isPickingAvatar) {
      return;
    }

    setState(() {
      _isPickingAvatar = true;
    });

    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null || !mounted) {
        return;
      }

      final session = context.read<SessionController>();
      final ok = await session.updateProfile(avatarPath: picked.path);
      if (!mounted) {
        return;
      }

      if (!ok && session.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(session.errorMessage!)));
      } else if (ok) {
        await session.refreshProfile();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Photo uploaded')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingAvatar = false;
        });
      }
    }
  }

  Future<void> _updateName() async {
    final session = context.read<SessionController>();
    final ok = await session.updateProfile(
      fullName: _nameController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (!ok && session.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(session.errorMessage!)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final user = session.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_nameController.text.isEmpty) {
      _nameController.text = user.fullName;
    }

    final avatarUrl = _resolveAvatarUrl(user.avatarUrl);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF8EF), Color(0xFFE9F7F4)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'My Profile',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            TextButton(
                              onPressed: session.isLoading
                                  ? null
                                  : () async {
                                      await session.logout();
                                    },
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 52,
                                backgroundColor: const Color(0xFFD6ECE8),
                                child: ClipOval(
                                  child: user.avatarUrl != null
                                      ? Image.network(
                                          avatarUrl!,
                                          key: ValueKey(avatarUrl),
                                          width: 104,
                                          height: 104,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) {
                                            debugPrint(
                                              'Avatar load failed for $avatarUrl: $err',
                                            );
                                            return _avatarFallback(
                                              ctx,
                                              user.fullName,
                                            );
                                          },
                                        )
                                      : _avatarFallback(context, user.fullName),
                                ),
                              ),
                              IconButton.filled(
                                onPressed: session.isLoading || _isPickingAvatar
                                    ? null
                                    : _pickAndUploadAvatar,
                                icon: const Icon(Icons.camera_alt),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: user.email,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: session.isLoading ? null : _updateName,
                          child: session.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Profile'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _resolveAvatarUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }

  final trimmed = raw.trim();
  final parsed = Uri.tryParse(trimmed);
  if (parsed != null && parsed.hasScheme) {
    return trimmed;
  }

  final apiUri = Uri.tryParse(AppConfig.apiBaseUrl);
  if (apiUri == null || !apiUri.hasScheme || apiUri.host.isEmpty) {
    return trimmed;
  }

  final origin =
      '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
  if (trimmed.startsWith('/')) {
    return '$origin$trimmed';
  }
  return '$origin/$trimmed';
}

Widget _avatarFallback(BuildContext context, String fullName) {
  return SizedBox(
    width: 104,
    height: 104,
    child: Center(
      child: Text(
        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
    ),
  );
}
