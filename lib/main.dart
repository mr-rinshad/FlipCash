import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/request_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env securely contains SUPABASE_URL & SUPABASE_ANON_KEY)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Note: .env file loading: $e");
  }

  // Initialize Supabase with configured credentials
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://vronmezuytwqhpgukmlm.supabase.co';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_jxqblw45vAb-qXmVWeXZ9Q_IpPEXNZE';

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } catch (e) {
    debugPrint("Supabase initialization notice: $e");
  }

  runApp(const FlipCashApp());
}

class FlipCashApp extends StatelessWidget {
  const FlipCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
