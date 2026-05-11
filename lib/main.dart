
import 'package:flutter/material.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

// Import your architecture layers
import 'views/onboarding_view.dart';
import 'views/login_view.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/admin_viewmodel.dart';
import 'views/home_view.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Initialization [cite: 112, 115]
  await Supabase.initialize(
    url: 'https://jqovxwkxuahggrzvvhz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impxb3Z4d3hrdXhhaGdncnp2dmh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzQ1OTAsImV4cCI6MjA5MzI1MDU5MH0.VxNCDwx-BQL5rZO5VGuPzsiNHPQ6ycNLVOJ-rKe9OH0',
  );

  runApp(
    // MultiProvider manages app state across the MVVM structure [cite: 45, 133]
    MultiProvider(
      providers: [
        // Add your ViewModels here as we create them
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => AdminViewModel()),
      ],
      child: const MyApp(),

    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Assistant App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Using Blue to match CUT branding and your onboarding theme [cite: 1]
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
      ),
      // Set Onboarding as the initial screen [cite: 126]
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingView(),
        '/login': (context) => const LoginView(),
        '/home': (context) => const HomeView(),
      },

    );
  }
}