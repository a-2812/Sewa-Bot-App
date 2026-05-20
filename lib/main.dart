import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'providers/role_state.dart';
import 'providers/trace_state.dart';
import 'providers/voice_state.dart';
import 'providers/provider_state.dart';

// Shared screens
import 'screens/shared/splash_screen.dart';
import 'screens/shared/trace_screen.dart';
import 'screens/shared/dev_index_screen.dart';
import 'screens/shared/agent_flow_screen.dart';

// Auth screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/email_verification_screen.dart';

// User screens
import 'screens/user/home_screen.dart';
import 'screens/user/chat_screen.dart';
import 'screens/user/providers_screen.dart';
import 'screens/user/quote_screen.dart';
import 'screens/user/booking_screen.dart';
import 'screens/user/status_screen.dart';
import 'screens/user/dispute_screen.dart';

// Provider screens
import 'screens/provider/provider_home_screen.dart';
import 'screens/provider/incoming_jobs_screen.dart';
import 'screens/provider/active_job_screen.dart';
import 'screens/provider/earnings_screen.dart';
import 'screens/provider/provider_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));


  runApp(const KhidmatAIApp());
}

class KhidmatAIApp extends StatelessWidget {
  const KhidmatAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoleState()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => TraceState()),
        ChangeNotifierProvider(create: (_) => VoiceState()),
        ChangeNotifierProvider(create: (_) => ProviderState()),
      ],
      child: Consumer<RoleState>(
        builder: (context, roleState, _) {
          return MaterialApp(
            title: 'SewaBot',
            debugShowCheckedModeBanner: false,
            theme: roleState.hasRole ? roleState.theme : AppTheme.userTheme,
            initialRoute: '/splash',
            routes: {
              // ─── Shared Routes ────────────────────────
              '/dev-index': (context) => const DevIndexScreen(),
              '/agent-flow': (context) => AgentFlowScreen(),
              '/splash': (context) => const SplashScreen(),
              '/trace': (context) => const TraceViewerScreen(),

              // ─── Auth Routes ──────────────────────────
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/reset-password': (context) => const ResetPasswordScreen(),
              '/verify-email': (context) => const EmailVerificationScreen(),

              // ─── User Routes ──────────────────────────
              '/user/home': (context) => const HomeScreen(),
              '/user/chat': (context) => const ChatScreen(),
              '/user/providers': (context) => const ProvidersScreen(),
              '/user/quote': (context) => const QuoteScreen(),
              '/user/booking': (context) => const BookingScreen(),
              '/user/status': (context) => const StatusScreen(),
              '/user/dispute': (context) => const DisputeScreen(),

              // ─── Provider Routes ──────────────────────
              '/provider/home': (context) => const ProviderHomeScreen(),
              '/provider/jobs': (context) => const IncomingJobsScreen(),
              '/provider/job': (context) => const ActiveJobScreen(),
              '/provider/active': (context) => const ActiveJobScreen(),
              '/provider/earnings': (context) => const EarningsScreen(),
              '/provider/profile': (context) => const ProviderProfileScreen(),
            },
          );
        },
      ),
    );
  }
}
