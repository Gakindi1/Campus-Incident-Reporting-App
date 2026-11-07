import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/incident_repository.dart';
import 'services/storage_service.dart';

/// Composition root: wires services into providers once, at the top of the
/// widget tree, so every screen reads the same state.
class CampusFixApp extends StatelessWidget {
  const CampusFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<IncidentRepository>(
          create: (_) => FirestoreIncidentRepository(),
        ),
        Provider<StorageService>(create: (_) => StorageService()),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthService>()),
        ),
        // Rebinds the incident stream whenever the signed-in user changes,
        // so one account never sees another's cached state.
        ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
          create: (context) => IncidentProvider(
            repository: context.read<IncidentRepository>(),
            storage: context.read<StorageService>(),
          ),
          update: (_, auth, incidents) => incidents!..bindUser(auth.profile),
        ),
      ],
      child: MaterialApp(
        title: 'CampusFix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}
