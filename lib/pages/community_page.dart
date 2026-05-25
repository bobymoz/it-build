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

  @override
  void initState() {
    super.initState();
    // Vai buscar os posts E os dados de quem postou (profiles) ao mesmo tempo
    _postsStream = Supabase.instance.client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('community_id', widget.community['id'])
        .order('created_at', ascending: false);
  }

  Future<void> _deletePost(String postId) async {
    await Supabase.instance.client.from('posts').delete().eq('id', postId);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post apagado!')));
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = widget.community['owner_id'] == _currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.community['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_document),
        label: const Text('Fazer Post', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.of(context).push(CreatePostPage.route(widget.community['id'])),
      ),
      body: Column(
        children: [
          // Cabeçalho da Comunidade
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF23232F),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: widget.community['logo_url'] != null && widget.community['logo_url'].toString().isNotEmpty
                      ? Image.network(widget.community['logo_url'], width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey[800], child: const Icon(Icons.group, size: 40)))
                      : Container(width: 80, height: 80, color: Colors.grey[800], child: const Icon(Icons.group, size: 40)),
                ),
                const SizedBox(height: 16),
                Text(widget.community['description'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.white70)),
                if (widget.community['rules'] != null && widget.community['rules'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF181820), borderRadius: BorderRadius.circular(10)),
                    child: Text('Regras: ${widget.community['rules']}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  ),
                ]
              ],
            ),
          ),
          
          // Lista de Posts
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Nenhum post ainda. Sê o primeiro!'));

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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(post['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                  if (isOwner)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _deletePost(post['id']),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(post['content'], maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
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
