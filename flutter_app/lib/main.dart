import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/firebase_event_repository_impl.dart';
import 'data/repositories/control_repository_impl.dart';
import 'data/repositories/offline_first_sensor_repository.dart';
import 'data/services/notification_service.dart';
import 'data/services/firebase_service.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/camera_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/sensors_screen.dart';
import 'presentation/screens/control_screen.dart';
import 'presentation/screens/stats_screen.dart';
import 'presentation/widgets/offline_banner.dart';
import 'presentation/viewmodels/auth_view_model.dart';
import 'presentation/viewmodels/control_view_model.dart';
import 'presentation/viewmodels/firebase_alarm_log_view_model.dart';
import 'presentation/viewmodels/sensor_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final isSupabaseConfigured =
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  if (isSupabaseConfigured) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  await NotificationService.initialize();
  await FirebaseService.initialize();

  runApp(SmartHomeApp(isSupabaseConfigured: isSupabaseConfigured));
}

class SmartHomeApp extends StatelessWidget {
  final bool isSupabaseConfigured;

  const SmartHomeApp({super.key, this.isSupabaseConfigured = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4AA),
          surface: Color(0xFF161B22),
        ),
        textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
      ),
      home: isSupabaseConfigured
          ? const _AppProviders(child: AuthGate())
          : const _SupabaseConfigScreen(),
    );
  }
}

class _AppProviders extends StatelessWidget {
  final Widget child;

  const _AppProviders({required this.child});

  @override
  Widget build(BuildContext context) {
    final firebaseEventRepository = FirebaseEventRepositoryImpl();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(FirebaseAuthRepository())
            ..ensureAnonymousSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => FirebaseAlarmLogViewModel(firebaseEventRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SensorViewModel(
            OfflineFirstSensorRepository(),
            eventRepository: firebaseEventRepository,
          )..connectLiveReadings(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ControlViewModel(ControlRepositoryImpl())..loadControlData(),
        ),
      ],
      child: child,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const LoginScreen();
        }
        return const MainScreen();
      },
    );
  }
}

class _SupabaseConfigScreen extends StatelessWidget {
  const _SupabaseConfigScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Supabase ayarlari eksik. Flutter run komutuna SUPABASE_URL ve SUPABASE_ANON_KEY dart-define olarak ekleyin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onQuickAccessSelected: _selectTab),
      const SensorsScreen(),
      const ControlScreen(),
      const StatsScreen(),
      const CameraScreen(),
    ];

    return Scaffold(
      body: OfflineBanner(child: screens[_currentIndex]),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Cikis yap',
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: const Color(0xFF00D4AA),
        onPressed: () => Supabase.instance.client.auth.signOut(),
        child: const Icon(Icons.logout),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF161B22),
        indicatorColor: const Color(0xFF00D4AA).withValues(alpha: 0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF00D4AA)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors, color: Color(0xFF00D4AA)),
            label: 'Sensors',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune, color: Color(0xFF00D4AA)),
            label: 'Control',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF00D4AA)),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam, color: Color(0xFF00D4AA)),
            label: 'Camera',
          ),
        ],
      ),
    );
  }

  void _selectTab(int index) {
    setState(() => _currentIndex = index);
  }
}
