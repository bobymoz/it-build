import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/pages/home_page.dart';
import 'package:my_chat_app/pages/register_page.dart';
import 'package:my_chat_app/pages/forgot_password_page.dart'; // Novo

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const LoginPage());

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      if (mounted) Navigator.of(context).pushAndRemoveUntil(HomePage.route(), (route) => false);
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centraliza tudo
            children: [
              Image.asset('assets/logo.png', height: 100), // Logo grande
              const SizedBox(height: 40), // Mais perto do formulário
              
              TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'O teu e-mail')),
              const SizedBox(height: 16),
              TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Palavra-passe')),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Iniciar sessão', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).push(ForgotPasswordPage.route()), // Chama a aba individual, sem popups!
                child: const Text('Esqueceste-te da palavra-passe?', style: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFB388FF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () => Navigator.of(context).pushReplacement(RegisterPage.route()),
                  child: const Text('Criar conta nova', style: TextStyle(color: Color(0xFFB388FF), fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
