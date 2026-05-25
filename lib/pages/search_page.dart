import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/pages/community_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const SearchPage());

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Procura comunidades onde o nome contenha o texto pesquisado (ilike = case insensitive)
      final data = await Supabase.instance.client
          .from('communities')
          .select()
          .ilike('name', '%$query%')
          .limit(20);
      
      if (mounted) setState(() => _results = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao pesquisar.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Pesquisar comunidades...',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _performSearch),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(child: Text('Escreve algo e clica na lupa para pesquisar.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final com = _results[index];
                    return Card(
                      color: const Color(0xFF23232F),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: com['logo_url'] != null && com['logo_url'].toString().isNotEmpty
                              ? Image.network(com['logo_url'], width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 40, height: 40, color: Colors.grey[800], child: const Icon(Icons.group)))
                              : Container(width: 40, height: 40, color: Colors.grey[800], child: const Icon(Icons.group)),
                        ),
                        title: Text(com['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(com['category'], style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommunityPage(community: com))),
                      ),
                    );
                  },
                ),
    );
  }
}
