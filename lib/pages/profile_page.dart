import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});
  static Route<void> route(String id) => MaterialPageRoute(builder: (_) => ProfilePage(userId: id));

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await Supabase.instance.client.from('profiles').select().eq('id', widget.userId).single();
      if (mounted) setState(() => _profileData = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao carregar perfil.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_profileData == null) return const Scaffold(body: Center(child: Text('Perfil não encontrado.')));

    final bool isMe = widget.userId == _currentUserId;

    return Scaffold(
      appBar: AppBar(title: Text(_profileData!['username'])),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // O Avatar de PNG Gigante
              Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(int.parse(_profileData!['avatar_color'])).withOpacity(0.3),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset('assets/${_profileData!['avatar_icon']}.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 24),
              Text(_profileData!['username'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // A Descrição
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF23232F), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _profileData!['description'] ?? 'Este utilizador ainda não escreveu uma biografia.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 40),

              // Botão de Mensagem (SÓ aparece se não for o teu próprio perfil)
              if (!isMe)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Enviar Mensagem Privada', style: TextStyle(fontSize: 16)),
                    onPressed: () {
                      // No próximo passo vamos ligar isto ao Chat Privado!
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat Privado a caminho!')));
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
