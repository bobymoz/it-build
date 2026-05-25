import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/pages/home_page.dart';
import 'package:my_chat_app/pages/register_page.dart';

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
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pushAndRemoveUntil(HomePage.route(), (route) => false);
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fluxo de Esquecer a Palavra-Passe (Pede Email -> Recebe Código -> Muda Senha)
  Future<void> _forgotPasswordFlow() async {
    final emailCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    
    // Passo 1: Pedir o E-mail
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF23232F),
        title: const Text('Recuperar Palavra-passe', style: TextStyle(fontSize: 18)),
        content: TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: 'O teu e-mail')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, emailCtrl.text.trim()), child: const Text('Enviar Código')),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      
      // Passo 2: Inserir Código e Nova Senha
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF23232F),
          title: const Text('Código Enviado!', style: TextStyle(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Verifica o teu e-mail e insere o código abaixo:'),
              const SizedBox(height: 16),
              TextField(controller: codeCtrl, decoration: const InputDecoration(hintText: 'Código de 6 dígitos')),
              const SizedBox(height: 10),
              TextField(controller: newPassCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Nova palavra-passe')),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client.auth.verifyOTP(type: OtpType.recovery, token: codeCtrl.text.trim(), email: email);
                  await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPassCtrl.text.trim()));
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Palavra-passe alterada com sucesso!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código inválido ou erro.')));
                }
              },
              child: const Text('Redefinir e Entrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao enviar o e-mail.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // LOGOTIPO DO REDOOT (Afastado do formulário)
              Image.asset('assets/logo.png', height: 80),
              const Spacer(flex: 1),
              
              // Formulário Estilo FB
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Número de telemóvel ou e-mail'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Palavra-passe'),
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Iniciar sessão', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: _forgotPasswordFlow,
                child: const Text('Esqueceste-te da palavra-passe?', style: TextStyle(color: Colors.white70)),
              ),
              
              const Spacer(flex: 3),
              
              // Botão Criar Conta no fundo (Outlined Estilo FB)
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
              const SizedBox(height: 20),
              const Text('∞ Redoot', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
