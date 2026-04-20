import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/dispatcher_dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/setup_required_screen.dart';
import 'services/profile_service.dart';
import 'services/settings_service.dart';

const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://YOUR-PROJECT.supabase.co',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'YOUR-ANON-KEY',
);
final _supabaseConfigured =
    !_supabaseUrl.contains('YOUR-PROJECT') && !_supabaseAnonKey.contains('YOUR-ANON-KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseConfigured) {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: GoldenHourApp()));
}

class GoldenHourApp extends StatelessWidget {
  const GoldenHourApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB42318),
        primary: const Color(0xFFB42318),
        secondary: const Color(0xFF0B6E4F),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6F3EE),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Color(0xFF111827),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );

    return MaterialApp(
      title: 'Golden Hour',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!_supabaseConfigured) {
      return const SetupRequiredScreen();
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session == null) {
          return const LoginScreen();
        }
        return FutureBuilder<ProfileRecord?>(
          future: ProfileService().fetchCurrentProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null || profile.fullName.trim().isEmpty) {
              return const ProfileSetupScreen();
            }

            return FutureBuilder<UserSettingsRecord>(
              future: SettingsService().fetchCurrentSettings(),
              builder: (context, settingsSnapshot) {
                if (settingsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final settings = settingsSnapshot.data;
                if (settings == null || !settings.onboardingCompleted) {
                  return const OnboardingScreen();
                }

                if (profile.role == 'dispatcher') {
                  return DispatcherDashboardScreen(profile: profile);
                }

                return HomeScreen(profile: profile);
              },
            );
          },
        );
      },
    );
  }
}
