import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/providers.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with environment variables
  await SupabaseService.initialize(
    supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
    supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const StyleMemoryApp());
}

class StyleMemoryApp extends StatelessWidget {
  const StyleMemoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClientsProvider()),
        ChangeNotifierProvider(create: (_) => VisitsProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
      ],
      child: MaterialApp.router(
        title: 'StyleMemory',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
