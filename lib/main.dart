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
  
  // Função global para alternar o tema em qualquer tela
  static _MyAppState of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>()!;
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fórum Jovem',
      themeMode: _themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const SplashPage(),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: const Color(0xFF6200EA),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E), elevation: 0),
      colorScheme: const ColorScheme.dark(primary: Color(0xFF6200EA), surface: Color(0xFF1E1E1E)),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF4F6F8), // Cor suave, sem forçar a vista
      primaryColor: const Color(0xFF6200EA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF), 
        elevation: 1, 
        iconTheme: IconThemeData(color: Colors.black), 
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)
      ),
      colorScheme: const ColorScheme.light(primary: Color(0xFF6200EA), surface: Color(0xFFFFFFFF)),
    );
  }
}
