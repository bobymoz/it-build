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
  
  // Agora usamos números de 1 a 23, que correspondem aos seus PNGs
  int _selectedAvatarIndex = 1;
  Color _selectedColor = Colors.blue;

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
          'avatar_icon': _selectedAvatarIndex, // Vai salvar o número da imagem (Ex: 1, 15, 23)
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
        physics: const NeverScrollableScrollPhysics(),
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
          
          // Imagem principal gigante no topo
          CircleAvatar(
            radius: 60,
            backgroundColor: _selectedColor.withOpacity(0.5),
            backgroundImage: AssetImage('assets/$_selectedAvatarIndex.png'),
          ),
          const SizedBox(height: 30),
          const Text('Escolha um Avatar:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // Geração automática dos 23 avatares PNG em formato de grade
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(23, (index) {
              final avatarId = index + 1; // Cria a sequência de 1 a 23
              final isSelected = _selectedAvatarIndex == avatarId;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatarIndex = avatarId),
                child: Container(
                  width: 55, 
                  height: 55,
                  decoration: BoxDecoration(
                    color: _selectedColor.withOpacity(0.2), // Fundo suave acompanhando a cor
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, 
                      width: 3
                    ),
                    image: DecorationImage(
                      image: AssetImage('assets/$avatarId.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 30),
          const Text('Cor de Fundo:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
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
