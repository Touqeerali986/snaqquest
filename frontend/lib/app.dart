import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/state/session_controller.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/profile/data/profile_repository.dart';

class SnaqQuestApp extends StatelessWidget {
  const SnaqQuestApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiClient(baseUrl: AppConfig.apiBaseUrl)),
        Provider(create: (_) => TokenStorage()),
        ChangeNotifierProvider(
          create: (context) {
            final apiClient = context.read<ApiClient>();
            final tokenStorage = context.read<TokenStorage>();

            final controller = SessionController(
              authRepository: AuthRepository(
                apiClient: apiClient,
                tokenStorage: tokenStorage,
              ),
              profileRepository: ProfileRepository(
                apiClient: apiClient,
                tokenStorage: tokenStorage,
              ),
              firebaseReady: firebaseReady,
            );

            controller.bootstrap();
            return controller;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SnaqQuest',
        theme: AppTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}
