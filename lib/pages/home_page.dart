import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/utils/skeleton.dart';
import 'package:my_chat_app/pages/create_community_page.dart';
import 'package:my_chat_app/pages/profile_page.dart';
import 'package:my_chat_app/pages/chat_list_page.dart';
import 'package:my_chat_app/pages/notifications_page.dart';
import 'package:my_chat_app/pages/search_page.dart';
import 'package:my_chat_app/pages/community_page.dart'; // IMPORTANTE PARA O CLIQUE FUNCIONAR

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const HomePage());

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _communitiesFuture;
  Map<String, dynamic>? _currentUserProfile;
  bool _isLoadingProfile = true;
  String _selectedCategory = 'Tudo';

  final List<String> _categories = [
    'Tudo', 'Namoro', 'Filmes e Séries', 'Animes', 'Amizade', 'LGBTQIA+', 'Jogos', 
    'Músicas', 'Arte e Criação', 'Esportes', 'Escola e Faculdade', 'Carreira', 
    'Fofoca', 'Memes', 'Opinião', 'Segredos', 'Conselhos', 'Geral'
  ];

  @override
  void initState() {
    super.initState();
    _fetchCommunities();
    _fetchUserProfile();
  }

  void _fetchCommunities() {
    if (_selectedCategory == 'Tudo') {
      _communitiesFuture = Supabase.instance.client.from('communities').select().order('created_at', ascending: false);
    } else {
      _communitiesFuture = Supabase.instance.client.from('communities').select().eq('category', _selectedCategory).order('created_at', ascending: false);
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client.from('profiles').select().eq('id', userId).single();
      if (mounted) setState(() => _currentUserProfile = data);
    } catch (e) {
      if (mounted) setState(() => _currentUserProfile = {'avatar_icon': 1, 'avatar_color': '0xFFB388FF'});
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: GestureDetector(
            onTap: () {
              if (_currentUserProfile != null) {
                Navigator.of(context).push(ProfilePage.route(Supabase.instance.client.auth.currentUser!.id));
              }
            },
            child: _isLoadingProfile
                ? const CircularProgressIndicator()
                : CircleAvatar(
                    backgroundColor: Color(int.parse(_currentUserProfile!['avatar_color'])).withOpacity(0.3),
                    child: Padding(padding: const EdgeInsets.all(4.0), child: Image.asset('assets/${_currentUserProfile!['avatar_icon']}.png', fit: BoxFit.contain)),
                  ),
          ),
        ),
        title: Image.asset('assets/logo.png', height: 35),
        actions: [
          IconButton(icon: const Icon(Icons.search, size: 26), onPressed: () => Navigator.of(context).push(SearchPage.route())),
          IconButton(icon: const Icon(Icons.notifications_none, size: 26), onPressed: () => Navigator.of(context).push(NotificationsPage.route())),
          IconButton(icon: Image.asset('assets/chat.png', width: 24, height: 24, color: Colors.white), onPressed: () => Navigator.of(context).push(ChatListPage.route())),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Criar', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.of(context).push(CreateCommunityPage.route()).then((_) {
          setState(() => _fetchCommunities());
        }),
      ),
      body: Column(
        children: [
          // FILTRO DE CATEGORIAS NO TOPO DO FEED
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
                    selected: isSelected,
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: const Color(0xFF23232F),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                        _fetchCommunities();
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _communitiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return _buildSkeletonList();
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Nenhuma comunidade encontrada nesta categoria.'));

                final communities = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: communities.length,
                  itemBuilder: (context, index) {
                    final com = communities[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      color: const Color(0xFF23232F),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        // CLIQUE CORRIGIDO PARA ABRIR A COMUNIDADE
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommunityPage(community: com))),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: com['logo_url'] != null && com['logo_url'].toString().isNotEmpty
                                    ? Image.network(com['logo_url'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: Colors.grey[800], child: const Icon(Icons.broken_image)))
                                    : Container(width: 50, height: 50, color: Colors.grey[800], child: const Icon(Icons.group)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(com['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text(com['description'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
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

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: const Color(0xFF23232F),
        child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [const Skeleton(width: 50, height: 50, borderRadius: 12), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Skeleton(width: 150, height: 16), SizedBox(height: 8), Skeleton(width: double.infinity, height: 12)]))])),
      ),
    );
  }
}
