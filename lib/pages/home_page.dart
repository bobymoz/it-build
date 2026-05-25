import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/utils/skeleton.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const HomePage());

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  Map<String, dynamic>? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _categoriesFuture = Supabase.instance.client.from('categories').select().order('created_at', ascending: true);
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final data = await Supabase.instance.client.from('profiles').select().eq('id', userId).single();
    if (mounted) setState(() => _currentUserProfile = data);
  }

  // Função que permite aos utilizadores criar um tópico rapidamente
  Future<void> _createTopicFlow() async {
    final titleCtrl = TextEditingController();
    // Pega as categorias para o utilizador escolher onde postar
    final categories = await Supabase.instance.client.from('categories').select();
    String? selectedCategoryId = categories.first['id'];

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF23232F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Criar Novo Tópico', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Título do tópico...')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategoryId,
              dropdownColor: const Color(0xFF181820),
              decoration: const InputDecoration(hintText: 'Escolhe a Categoria'),
              items: categories.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['title']))).toList(),
              onChanged: (val) => selectedCategoryId = val,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty) return;
                await Supabase.instance.client.from('topics').insert({
                  'category_id': selectedCategoryId,
                  'profile_id': Supabase.instance.client.auth.currentUser!.id,
                  'title': titleCtrl.text.trim(),
                });
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tópico criado!')));
              },
              child: const Text('Publicar Tópico'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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
        // Canto Esquerdo: O teu Avatar!
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              // Aqui vamos chamar a futura página de perfil
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aba Perfil em breve!')));
            },
            child: _currentUserProfile == null
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
        // Centro: Ícone de Chat
        title: IconButton(
          icon: const Icon(Icons.chat_bubble_rounded, size: 30),
          color: Theme.of(context).primaryColor,
          onPressed: () {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aba Chat em breve!')));
          },
        ),
        // Canto Direito: Pesquisa
        actions: [
          IconButton(icon: const Icon(Icons.search, size: 30), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      
      // Botão Flutuante (FAB) para Criar Tópicos
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Tópico', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _createTopicFlow,
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
                  onTap: () {
                    // No próximo passo vamos colocar o Navigator.push para a página do Tópico!
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ler tópicos em breve!')));
                  },
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
                        const Icon(Icons.chevron_right_rounded, color: Colors.white38),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [Skeleton(width: 150, height: 16), SizedBox(height: 8), Skeleton(width: double.infinity, height: 12)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
