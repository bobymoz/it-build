import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivateChatPage extends StatefulWidget {
  final Map<String, dynamic> otherUser;
  const PrivateChatPage({super.key, required this.otherUser});
  static Route<void> route(Map<String, dynamic> user) => MaterialPageRoute(builder: (_) => PrivateChatPage(otherUser: user));

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final _msgCtrl = TextEditingController();
  late Stream<List<Map<String, dynamic>>> _messagesStream;
  final String _myId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    // Escuta as mensagens onde tu és o remetente e ele o destinatário, OU vice-versa
    _messagesStream = Supabase.instance.client
        .from('private_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true);
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    
    try {
      await Supabase.instance.client.from('private_messages').insert({
        'sender_id': _myId,
        'receiver_id': widget.otherUser['id'],
        'content': text,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao enviar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(int.parse(widget.otherUser['avatar_color'])).withOpacity(0.3),
              child: Padding(padding: const EdgeInsets.all(3.0), child: Image.asset('assets/${widget.otherUser['avatar_icon']}.png', fit: BoxFit.contain)),
            ),
            const SizedBox(width: 12),
            Text(widget.otherUser['username']),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                // Filtragem local para mostrar apenas as mensagens entre os dois
                final allMsgs = snapshot.data ?? [];
                final chatMsgs = allMsgs.where((m) => 
                  (m['sender_id'] == _myId && m['receiver_id'] == widget.otherUser['id']) ||
                  (m['sender_id'] == widget.otherUser['id'] && m['receiver_id'] == _myId)
                ).toList();

                if (chatMsgs.isEmpty) return const Center(child: Text('Inicia a conversa!', style: TextStyle(color: Colors.white54)));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chatMsgs.length,
                  itemBuilder: (context, index) {
                    final msg = chatMsgs[index];
                    final isMe = msg['sender_id'] == _myId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        // CORREÇÃO: Removido o maxLines que estava a quebrar o código
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).primaryColor : const Color(0xFF23232F),
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                          ),
                        ),
                        child: Text(msg['content'], style: const TextStyle(color: Colors.white, fontSize: 15)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Caixa de texto
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF23232F),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'Escreve uma mensagem...',
                        filled: true,
                        fillColor: const Color(0xFF181820),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
