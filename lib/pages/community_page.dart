import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_chat_app/pages/create_post_page.dart';
import 'package:my_chat_app/pages/post_detail_page.dart';

class CommunityPage extends StatefulWidget {
  final Map<String, dynamic> community;
  const CommunityPage({super.key, required this.community});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late Stream<List<Map<String, dynamic>>> _postsStream;
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  late Map<String, dynamic> _currentCommunity;
  bool _isMember = false;
  bool _isBanned = false;

  @override
  void initState() {
    super.initState();
    _currentCommunity = widget.community;
    _postsStream = Supabase.instance.client.from('posts').stream(primaryKey: ['id']).eq('community_id', _currentCommunity['id']).order('created_at', ascending: false);
    _checkMembership();
  }

  Future<void> _checkMembership() async {
    final res = await Supabase.instance.client.from('community_members').select().eq('community_id', _currentCommunity['id']).eq('profile_id', _currentUserId);
    if (res.isNotEmpty && mounted) {
      setState(() {
        _isMember = true;
        _isBanned = res.first['is_banned'] ?? false;
      });
    }
  }

  Future<void> _toggleJoin() async {
    if (_isBanned) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foste banido desta comunidade.')));
      return;
    }
    if (_isMember) {
      await Supabase.instance.client.from('community_members').delete().eq('community_id', _currentCommunity['id']).eq('profile_id', _currentUserId);
      setState(() => _isMember = false);
    } else {
      await Supabase.instance.client.from('community_members').insert({'community_id': _currentCommunity['id'], 'profile_id': _currentUserId});
      setState(() => _isMember = true);
    }
  }

  // PAINEL DE MODERAÇÃO (APENAS PARA O DONO)
  void _showAdminPanel() async {
    final members = await Supabase.instance.client.from('community_members').select('*, profiles(*)').eq('community_id', _currentCommunity['id']);
    
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF23232F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Painel da Comunidade', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit), label: const Text('Editar Dados da Comunidade'),
                  onPressed: () { /* O teu código antigo de edição ficaria aqui, vou resumir para focar na moderação */ },
                ),
                const Divider(height: 40, color: Colors.white24),
                const Text('Gerir Membros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final mem = members[index];
                      final prof = mem['profiles'];
                      if (prof['id'] == _currentUserId) return const SizedBox(); // O dono não se pode banir
                      return ListTile(
                        leading: CircleAvatar(backgroundImage: AssetImage('assets/${prof['avatar_icon']}.png')),
                        title: Text(prof['username']),
                        trailing: IconButton(
                          icon: Icon(mem['is_banned'] ? Icons.lock : Icons.lock_open, color: mem['is_banned'] ? Colors.red : Colors.green),
                          onPressed: () async {
                            final newStatus = !(mem['is_banned'] ?? false);
                            await Supabase.instance.client.from('community_members').update({'is_banned': newStatus}).eq('community_id', _currentCommunity['id']).eq('profile_id', prof['id']);
                            setSheetState(() => mem['is_banned'] = newStatus);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = _currentCommunity['owner_id'] == _currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCommunity['name']),
        actions: isOwner ? [IconButton(icon: const Icon(Icons.admin_panel_settings, color: Colors.amber), onPressed: _showAdminPanel)] : [],
      ),
      floatingActionButton: _isMember && !_isBanned
          ? FloatingActionButton.extended(
              backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, icon: const Icon(Icons.edit_document),
              label: const Text('Fazer Post', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).push(CreatePostPage.route(_currentCommunity['id'])),
            )
          : null,
      body: Column(
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFF23232F), borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _currentCommunity['logo_url'] != null ? Image.network(_currentCommunity['logo_url'], width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const Icon(Icons.group, size: 40)) : const Icon(Icons.group, size: 40),
                ),
                const SizedBox(height: 16),
                Text(_currentCommunity['description'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.white70)),
                const SizedBox(height: 16),
                if (!isOwner)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _isMember ? Colors.grey[700] : Theme.of(context).primaryColor),
                    onPressed: _toggleJoin,
                    child: Text(_isMember ? 'Sair da Comunidade' : 'Juntar-se à Comunidade'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Nenhum post. Entra e cria um!'));

                final posts = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8), color: const Color(0xFF23232F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () => Navigator.of(context).push(PostDetailPage.route(post)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post['image_url'] != null)
                              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), child: Image.network(post['image_url'], width: double.infinity, height: 180, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const SizedBox())),
                            if (post['video_url'] != null)
                              Container(width: double.infinity, height: 180, color: Colors.black, child: const Icon(Icons.play_circle_fill, size: 50, color: Colors.white54)),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Linkify(text: post['content'], maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70), onOpen: (link) => launchUrl(Uri.parse(link.url))),
                                  const Divider(height: 24, color: Colors.white12),
                                  Row(
                                    children: [
                                      const Icon(Icons.favorite, size: 18, color: Colors.redAccent), const SizedBox(width: 4), Text('${post['likes'] ?? 0}'),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.comment, size: 18, color: Colors.white54), const SizedBox(width: 4), const Text('Ver respostas'),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
