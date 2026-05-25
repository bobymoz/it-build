import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/pages/home_page.dart';
import 'package:my_chat_app/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const RegisterPage());
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final PageController _pageController = PageController();
  final _emailCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  
  bool _isLoading = false;
  int _selectedAvatarIndex = 1;
  Color _selectedColor = const Color(0xFFB388FF);

  final List<Color> _colors = [
    const Color(0xFFB388FF), const Color(0xFFFF8A65), const Color(0xFF81C784), 
    const Color(0xFF64B5F6), const Color(0xFFF06292), const Color(0xFFFFD54F) // Cores fofas e suaves
  ];

  void _nextPage() {
    FocusScope.of(context).unfocus();
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _signUp() async {
    if (_passCtrl.text != _confirmPassCtrl.text) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        data: {'username': _userCtrl.text.trim(), 'avatar_icon': _selectedAvatarIndex, 'avatar_color': _selectedColor.value.toString()}
      );
      if (mounted) Navigator.of(context).pushAndRemoveUntil(HomePage.route(), (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao criar conta.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _pageController.page == 0 ? Navigator.of(context).pushReplacement(LoginPage.route()) : _prevPage(),
              ),
            ),
            Image.asset('assets/logo.png', height: 40), // Logo pequenino no topo
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep('Qual o teu E-mail?', TextField(controller: _emailCtrl, decoration: const InputDecoration(hintText: 'exemplo@email.com')), _nextPage),
                  _buildStep('Escolhe um Nome', TextField(controller: _userCtrl, decoration: const InputDecoration(hintText: 'Como te queres chamar?')), _nextPage),
                  _buildStep('Cria uma Palavra-passe', Column(children: [
                    TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Palavra-passe')),
                    const SizedBox(height: 16),
                    TextField(controller: _confirmPassCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Confirma a Palavra-passe')),
                  ]), _nextPage),
                  _buildAvatarSelection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String title, Widget child, VoidCallback onNext) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 30),
          child,
          const SizedBox(height: 30),
          ElevatedButton(onPressed: onNext, child: const Text('Avançar')),
        ],
      ),
    );
  }

  Widget _buildAvatarSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('O teu Avatar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          
          // IMAGEM CORRIGIDA PARA NÃO CORTAR (Uso de Padding e BoxFit.contain)
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _selectedColor.withOpacity(0.3)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/$_selectedAvatarIndex.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 30),
          
          Wrap(
            spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
            children: List.generate(23, (index) {
              final avatarId = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatarIndex = avatarId),
                child: Container(
                  width: 55, height: 55,
                  decoration: BoxDecoration(
                    color: _selectedColor.withOpacity(0.1), shape: BoxShape.circle,
                    border: Border.all(color: _selectedAvatarIndex == avatarId ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
                  ),
                  child: Padding(padding: const EdgeInsets.all(4.0), child: Image.asset('assets/$avatarId.png', fit: BoxFit.contain)),
                ),
              );
            }),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 10, alignment: WrapAlignment.center,
            children: _colors.map((color) => GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: _selectedColor == color ? Colors.white : Colors.transparent, width: 3)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Entrar no Redoot'),
          ),
        ],
      ),
    );
  }
}
