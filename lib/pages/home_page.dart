import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/utils/skeleton.dart';
import 'package:my_chat_app/pages/create_topic_page.dart'; // Nova página separada

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const HomePage());

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  Map<String, dynamic>? _currentUserProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = Supabase.instance.client.from('categories').select().order('created_at', ascending: true);
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client.from('profiles').select().eq('id', userId).single();
      if (mounted) setState(() => _currentUserProfile = data);
    } catch (e) {
      // Se falhar, carrega um perfil seguro para não ficar infinito
      if (mounted) setState(() => _currentUserProfile = {'avatar_icon': 1, 'avatar_color': '0xFFB388FF'});
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Widget _buildCategoryIcon(int? code, Color color) {
    switch (code) {
      case 58364: return Icon(Icons.forum, size: 28, color: color);
      case 57895: return Icon(Icons.attach_money, size: 28, color: color);
      case 58050: return Icon(Icons.favorite, size: 28, color: color);
      case 58074: return Icon(Icons.headset, size: 28, color: color);
      case 58106: return Icon(Icons.gavel, size: 28, color: color);
      default: return Icon(Icons.folder, size: 28, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 70,
        // Canto Esquerdo: O teu Avatar!
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil em breve!'))),
            child: _isLoadingProfile
                ? const CircularProgressIndicator()
                : CircleAvatar(
                    backgroundColor: Color(int.parse(_currentUserProfile!['avatar_color'])).withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset('assets/${_currentUserProfile!['avatar_icon']}.png', fit: BoxFit.contain),
                    ),
                  ),
          ),
        ),
        title: const Text('Redoot', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search, size: 28), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28), 
            onPressed: () => Navigator.of(context).push(CreateTopicPage.route()), // Abre página dedicada
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      // Ícone de Chat em Baixo e no Meio com o teu PNG
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF23232F),
        elevation: 0,
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat em breve!'))),
        child: Image.asset('assets/chat.png', width: 30, height: 30),
      ),
      bottomNavigationBar: const BottomAppBar(
        color: Color(0xFF181820),
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(height: 50),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return _buildSkeletonList();
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Nenhuma categoria.'));

          final categories = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: const Color(0xFF23232F),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.15), shape: BoxShape.circle),
                          child: _buildCategoryIcon(cat['icon_code'], Theme.of(context).primaryColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(cat['description'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13)),
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
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: const Color(0xFF23232F),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Skeleton(width: 50, height: 50, borderRadius: 25),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Skeleton(width: 150, height: 16), SizedBox(height: 8), Skeleton(width: double.infinity, height: 12)]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
