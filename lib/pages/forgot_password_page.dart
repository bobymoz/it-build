import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final PageController _pageController = PageController();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendCode() async {
    if (_emailCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(_emailCtrl.text.trim());
      if (mounted) _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao enviar e-mail.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_codeCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(type: OtpType.recovery, token: _codeCtrl.text.trim(), email: _emailCtrl.text.trim());
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: _newPassCtrl.text.trim()));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Palavra-passe alterada com sucesso! Podes entrar.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código inválido ou erro.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Segurança')),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep(
            'Qual é o teu e-mail?',
            TextField(controller: _emailCtrl, decoration: const InputDecoration(hintText: 'exemplo@email.com')),
            'Enviar Código', _sendCode,
          ),
          _buildStep(
            'Verifica a tua Caixa de Entrada',
            Column(
              children: [
                TextField(controller: _codeCtrl, decoration: const InputDecoration(hintText: 'Código de segurança de 6 dígitos')),
                const SizedBox(height: 16),
                TextField(controller: _newPassCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Nova palavra-passe')),
              ],
            ),
            'Redefinir e Entrar', _resetPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String title, Widget content, String btnText, VoidCallback action) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 30),
          content,
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isLoading ? null : action,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(btnText),
          ),
        ],
      ),
    );
  }
}
