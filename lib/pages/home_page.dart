import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/utils/skeleton.dart';
import 'package:my_chat_app/main.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const HomePage());

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchCategories();
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    return await Supabase.instance.client.from('categories').select().order('created_at', ascending: true);
  }

  // SOLUÇÃO ESTRUTURAL: Em vez de retornar um dado solto, retornamos o WIDGET inteiro.
  // Dessa forma o compilador entende exatamente quais ícones nativos não podem ser apagados.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fórum Jovem'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => MyApp.of(context).toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonList();
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma categoria encontrada.'));
          }

          final categories = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _buildCategoryCard(cat, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Skeleton(width: 45, height: 45, borderRadius: 25),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Skeleton(width: 150, height: 16),
                      SizedBox(height: 8),
                      Skeleton(width: double.infinity, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat, bool isDark) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // Aqui vai a navegação para os tópicos
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                // Chamamos a função que constrói o Widget inteiro
                child: _buildCategoryIcon(cat['icon_code'], Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat['title'] ?? 'Sem Título',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat['description'] ?? '',
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
