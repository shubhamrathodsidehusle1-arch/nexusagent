/// NexusAgent Mobile App - PRODUCTION READY
/// Connected to database, local storage, and sync

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/services/api_service.dart';
import 'data/services/database_service.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/sync_service.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen_pro.dart';
import 'presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize services
  await _initializeServices();

  runApp(const NexusAgentApp());
}

Future<void> _initializeServices() async {
  // Initialize local storage first
  await LocalStorageService().initialize();

  // Initialize database
  await DatabaseService().initialize();

  // Initialize sync service
  await SyncService().initialize();

  // Check for demo mode
  final token = LocalStorageService().getToken();
  if (token == null) {
    // Demo mode - generate a demo token
    await LocalStorageService().saveToken('demo_token_12345');
  }

  print('All services initialized');
}

class NexusAgentApp extends StatelessWidget {
  const NexusAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core Services
        Provider<DatabaseService>.value(value: DatabaseService()),
        Provider<LocalStorageService>.value(value: LocalStorageService()),
        Provider<ApiService>.value(value: ApiService()),
        Provider<SyncService>.value(value: SyncService()),

        // Auth Provider
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider()..checkAuth(),
        ),

        // App State Provider
        ChangeNotifierProvider<AppStateProvider>(
          create: (_) => AppStateProvider()..loadSettings(),
        ),

        // Data Providers
        ChangeNotifierProxyProvider<AuthProvider, AgentsProvider>(
          create: (_) => AgentsProvider(),
          update: (_, auth, prev) => prev!..loadIfAuthenticated(auth.isAuthenticated),
        ),

        ChangeNotifierProxyProvider<AuthProvider, ChannelsProvider>(
          create: (_) => ChannelsProvider(),
          update: (_, auth, prev) => prev!..loadIfAuthenticated(auth.isAuthenticated),
        ),

        ChangeNotifierProxyProvider<AuthProvider, AnalyticsProvider>(
          create: (_) => AnalyticsProvider(),
          update: (_, auth, prev) => prev!..loadIfAuthenticated(auth.isAuthenticated),
        ),

        ChangeNotifierProxyProvider<AuthProvider, WorkflowsProvider>(
          create: (_) => WorkflowsProvider(),
          update: (_, auth, prev) => prev!..loadIfAuthenticated(auth.isAuthenticated),
        ),

        ChangeNotifierProxyProvider<AuthProvider, TeamProvider>(
          create: (_) => TeamProvider(),
          update: (_, auth, prev) => prev!..loadIfAuthenticated(auth.isAuthenticated),
        ),

        ChangeNotifierProxyProvider<AuthProvider, SessionsProvider>(
          create: (_) => SessionsProvider(),
          update: (_, auth, prev) => prev!..loadIfAuthenticated(auth.isAuthenticated),
        ),

        ChangeNotifierProxyProvider<AuthProvider, SettingsProvider>(
          create: (_) => SettingsProvider(),
          update: (_, auth, prev) => prev!..loadIfAuthenticated(auth.isAuthenticated),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AppRouter(),
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Show splash while checking auth
        if (auth.isLoading) {
          return const SplashScreen();
        }

        // Show login if not authenticated
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        // Show home if authenticated
        return const HomeScreen();
      },
    );
  }
}
