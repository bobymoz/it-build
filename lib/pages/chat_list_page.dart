import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/pages/private_chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const ChatListPage());

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  final String _myId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      // 1. Vai buscar todas as mensagens onde tu participas
      final msgs = await Supabase.instance.client.from('private_messages').select().or('sender_id.eq.$_myId,receiver_id.eq.$_myId');
      
      // 2. Extrai os IDs das pessoas com quem falaste (sem repetir)
      final Set<String> peerIds = {};
      for (var msg in msgs) {
        final peer = msg['sender_id'] == _myId ? msg['receiver_id'] : msg['sender_id'];
        peerIds.add(peer.toString());
      }

      // 3. Vai buscar os perfis dessas pessoas
      if (peerIds.isNotEmpty) {
        final profiles = await Supabase.instance.client.from('profiles').select().inFilter('id', peerIds.toList());
        if (mounted) setState(() => _contacts = profiles);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao carregar chats.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(child: Text('Ainda não tens conversas.\nVai ao perfil de alguém e manda mensagem!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, height: 1.5)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return Card(
                      color: const Color(0xFF23232F),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(int.parse(contact['avatar_color'])).withOpacity(0.3),
                          child: Padding(padding: const EdgeInsets.all(4.0), child: Image.asset('assets/${contact['avatar_icon']}.png', fit: BoxFit.contain)),
                        ),
                        title: Text(contact['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                        onTap: () {
                          // Abre o chat privado com esta pessoa
                          Navigator.of(context).push(PrivateChatPage.route(contact));
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
