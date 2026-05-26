import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _currentCommunity = widget.community;
    _postsStream = Supabase.instance.client.from('posts').stream(primaryKey: ['id']).eq('community_id', _currentCommunity['id']).order('created_at', ascending: false);
  }

  // PAINEL DE EDIÇÃO DA COMUNIDADE PARA O DONO
  void _showEditCommunitySheet() {
    final nameCtrl = TextEditingController(text: _currentCommunity['name']);
    final descCtrl = TextEditingController(text: _currentCommunity['description']);
    final logoCtrl = TextEditingController(text: _currentCommunity['logo_url']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF23232F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Editar Comunidade', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Novo Nome')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Nova Descrição')),
            const SizedBox(height: 12),
            TextField(controller: logoCtrl, decoration: const InputDecoration(hintText: 'Novo Link do Logo (Imgur)')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await Supabase.instance.client.from('communities').update({
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'logo_url': logoCtrl.text.trim(),
                }).eq('id', _currentCommunity['id']);
                
                setState(() {
                  _currentCommunity['name'] = nameCtrl.text.trim();
                  _currentCommunity['description'] = descCtrl.text.trim();
                  _currentCommunity['logo_url'] = logoCtrl.text.trim();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comunidade atualizada!')));
              },
              child: const Text('Salvar Alterações'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = _currentCommunity['owner_id'] == _currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCommunity['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: isOwner
            ? [
                PopupMenuButton<String>(
                  onSelected: (val) async {
                    if (val == 'edit') _showEditCommunitySheet();
                    if (val == 'delete') {
                      await Supabase.instance.client.from('communities').delete().eq('id', _currentCommunity['id']);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comunidade apagada.')));
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar Comunidade')),
                    const PopupMenuItem(value: 'delete', child: Text('Apagar Comunidade', style: TextStyle(color: Colors.red))),
                  ],
                )
              ]
            : [],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_document),
        label: const Text('Fazer Post', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.of(context).push(CreatePostPage.route(_currentCommunity['id'])),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFF23232F), borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _currentCommunity['logo_url'] != null && _currentCommunity['logo_url'].toString().isNotEmpty
                      ? Image.network(_currentCommunity['logo_url'], width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey[800], child: const Icon(Icons.group, size: 40)))
                      : Container(width: 80, height: 80, color: Colors.grey[800], child: const Icon(Icons.group, size: 40)),
                ),
                const SizedBox(height: 16),
                Text(_currentCommunity['description'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.white70)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Nenhum post ainda.'));

                final posts = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color(0xFF23232F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () => Navigator.of(context).push(PostDetailPage.route(post)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SE O POST TIVER IMAGEM, MOSTRA NO FEED
                            if (post['image_url'] != null && post['image_url'].toString().isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                child: Image.network(post['image_url'], width: double.infinity, height: 180, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const SizedBox()),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(post['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                      if (isOwner)
                                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => Supabase.instance.client.from('posts').delete().eq('id', post['id'])),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(post['content'], maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
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
