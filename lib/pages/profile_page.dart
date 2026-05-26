import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/pages/private_chat_page.dart';

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
  bool _isBlocked = false;
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _checkBlock();
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

  Future<void> _checkBlock() async {
    final res = await Supabase.instance.client.from('blocked_users').select().eq('blocker_id', _currentUserId).eq('blocked_id', widget.userId);
    if (res.isNotEmpty && mounted) setState(() => _isBlocked = true);
  }

  Future<void> _toggleBlock() async {
    if (_isBlocked) {
      await Supabase.instance.client.from('blocked_users').delete().eq('blocker_id', _currentUserId).eq('blocked_id', widget.userId);
      setState(() => _isBlocked = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilizador desbloqueado.')));
    } else {
      await Supabase.instance.client.from('blocked_users').insert({'blocker_id': _currentUserId, 'blocked_id': widget.userId});
      setState(() => _isBlocked = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilizador bloqueado.')));
    }
  }

  void _showEditProfileSheet() {
    final descCtrl = TextEditingController(text: _profileData!['description']);
    int tempAvatar = _profileData!['avatar_icon'] ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF23232F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Editar Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Escolher Novo Avatar:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 140,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8),
                    itemCount: 23,
                    itemBuilder: (context, index) {
                      final avatarId = index + 1;
                      return GestureDetector(
                        onTap: () => setSheetState(() => tempAvatar = avatarId),
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: tempAvatar == avatarId ? Theme.of(context).primaryColor : Colors.transparent, width: 3)),
                          child: Image.asset('assets/$avatarId.png', fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Nova Biografia'), maxLines: 3),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await Supabase.instance.client.from('profiles').update({'description': descCtrl.text.trim(), 'avatar_icon': tempAvatar}).eq('id', _currentUserId);
                    setState(() { _profileData!['description'] = descCtrl.text.trim(); _profileData!['avatar_icon'] = tempAvatar; });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
                  },
                  child: const Text('Salvar Alterações'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_profileData == null) return const Scaffold(body: Center(child: Text('Perfil não encontrado.')));

    final bool isMe = widget.userId == _currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_profileData!['username']),
        actions: !isMe ? [
          PopupMenuButton<String>(
            onSelected: (val) { if (val == 'block') _toggleBlock(); },
            itemBuilder: (context) => [PopupMenuItem(value: 'block', child: Text(_isBlocked ? 'Desbloquear Utilizador' : 'Bloquear Utilizador', style: const TextStyle(color: Colors.red)))],
          )
        ] : [],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150, height: 150,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Color(int.parse(_profileData!['avatar_color'])).withOpacity(0.3)),
                child: Padding(padding: const EdgeInsets.all(12.0), child: Image.asset('assets/${_profileData!['avatar_icon']}.png', fit: BoxFit.contain)),
              ),
              const SizedBox(height: 24),
              Text(_profileData!['username'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Caixa da Biografia COM LÁPIS INDICATIVO
              GestureDetector(
                onTap: isMe ? _showEditProfileSheet : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF23232F), borderRadius: BorderRadius.circular(20)),
                  child: Stack(
                    children: [
                      Center(child: Text(_profileData!['description'] ?? 'Sem biografia.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.white70))),
                      if (isMe) const Positioned(right: 0, bottom: 0, child: Icon(Icons.edit, color: Colors.white38, size: 18)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              if (!isMe)
                SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.chat_bubble_outline), label: const Text('Enviar Mensagem Privada'), onPressed: () => Navigator.of(context).push(PrivateChatPage.route(_profileData!)))),
            ],
          ),
        ),
      ),
    );
  }
}
