import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://cgeddnpcckoqilcqstnk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnZWRkbnBjY2tvcWlsY3FzdG5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2MjU5MjksImV4cCI6MjA5NTIwMTkyOX0.827gFhTAqkSF1OSuysXVr_dACyTPekYwHSqlGHcj9aQ',
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static _MyAppState of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>()!;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeMode _themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Redoot',
      themeMode: _themeMode,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF181820),
        primaryColor: const Color(0xFFB388FF),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFB388FF), surface: Color(0xFF23232F)),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF181820), elevation: 0, centerTitle: true),
        // AS NOTIFICAÇÕES (SNACKBARS) AGORA SÃO DO APP E NÃO DO CELULAR!
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFFB388FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB388FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF23232F),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFB388FF))),
        ),
      ),
      home: const SplashPage(),
    );
  }
}
