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
  int _selectedIcon = Icons.face.codePoint;
  Color _selectedColor = Colors.blue;

  // Seguindo a sua exigência por ícones profissionais padrão Material Design
  final List<IconData> _avatars = [
    Icons.face, Icons.pets, Icons.rocket_launch, 
    Icons.local_fire_department, Icons.sports_esports, Icons.music_note,
    Icons.psychology, Icons.cruelty_free, Icons.directions_car
  ];
  
  final List<Color> _colors = [
    Colors.blue, Colors.red, Colors.green, 
    Colors.purple, Colors.orange, Colors.teal
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
    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As senhas não coincidem.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        data: {
          'username': _userCtrl.text.trim(),
          'avatar_icon': _selectedIcon,
          'avatar_color': _selectedColor.value.toString(),
        }
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(HomePage.route(), (route) => false);
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro inesperado.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_pageController.page == 0) {
              Navigator.of(context).pushReplacement(LoginPage.route());
            } else {
              _prevPage();
            }
          },
        ),
        title: const Text('Criar Conta'),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Impede deslizar com o dedo, obriga a usar o botão Avançar
        children: [
          _buildStep(
            title: 'Qual o seu Email?',
            child: TextField(controller: _emailCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
            onNext: _nextPage,
          ),
          _buildStep(
            title: 'Escolha um Nome de Usuário',
            child: TextField(controller: _userCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
            onNext: _nextPage,
          ),
          _buildStep(
            title: 'Crie uma Senha',
            child: Column(
              children: [
                TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: _confirmPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirme a Senha', border: OutlineInputBorder())),
              ],
            ),
            onNext: _nextPage,
          ),
          _buildAvatarSelection(),
        ],
      ),
    );
  }

  Widget _buildStep({required String title, required Widget child, required VoidCallback onNext}) {
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: onNext,
            child: const Text('Avançar', style: TextStyle(fontSize: 16)),
          ),
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
          const Text('Monte seu Avatar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: _selectedColor.withOpacity(0.2),
            child: Icon(IconData(_selectedIcon, fontFamily: 'MaterialIcons'), size: 60, color: _selectedColor),
          ),
          const SizedBox(height: 30),
          const Text('Ícone:', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 10,
            children: _avatars.map((icon) {
              final isSelected = _selectedIcon == icon.codePoint;
              return ChoiceChip(
                label: Icon(icon, color: isSelected ? Colors.white : Colors.grey),
                selected: isSelected,
                selectedColor: Theme.of(context).primaryColor,
                onSelected: (_) => setState(() => _selectedIcon = icon.codePoint),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Cor:', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 10,
            children: _colors.map((color) {
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: _selectedColor == color ? Colors.white : Colors.transparent, width: 3),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _isLoading ? null : _signUp,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Finalizar e Entrar', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
