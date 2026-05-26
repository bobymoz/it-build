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
  late Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    // Escuta em tempo real para as badges vermelhas!
    _messagesStream = Supabase.instance.client.from('private_messages').stream(primaryKey: ['id']);
  }

  Future<void> _loadContacts() async {
    try {
      final msgs = await Supabase.instance.client.from('private_messages').select().or('sender_id.eq.$_myId,receiver_id.eq.$_myId');
      final Set<String> peerIds = {};
      for (var msg in msgs) {
        peerIds.add((msg['sender_id'] == _myId ? msg['receiver_id'] : msg['sender_id']).toString());
      }
      if (peerIds.isNotEmpty) {
        final profiles = await Supabase.instance.client.from('profiles').select().inFilter('id', peerIds.toList());
        if (mounted) setState(() => _contacts = profiles);
      }
    } catch (e) {} finally {
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
              ? const Center(child: Text('Ainda não tens conversas.', style: TextStyle(color: Colors.white54)))
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    final allMsgs = snapshot.data ?? [];
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        // Conta quantas mensagens recebidas deste contato estão como is_read = false
                        int unreadCount = allMsgs.where((m) => m['sender_id'] == contact['id'] && m['receiver_id'] == _myId && m['is_read'] != true).length;

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
                            trailing: unreadCount > 0
                                ? Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                    child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  )
                                : const Icon(Icons.chevron_right, color: Colors.white38),
                            onTap: () {
                              Navigator.of(context).push(PrivateChatPage.route(contact));
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
