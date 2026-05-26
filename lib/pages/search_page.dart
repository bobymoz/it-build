import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/pages/community_page.dart';
import 'package:my_chat_app/pages/profile_page.dart';

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
  bool _searchUsers = false; // Toggle entre Comunidades (false) e Utilizadores (true)

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_searchUsers) {
        final data = await Supabase.instance.client.from('profiles').select().ilike('username', '%$query%').limit(20);
        if (mounted) setState(() => _results = data);
      } else {
        final data = await Supabase.instance.client.from('communities').select().ilike('name', '%$query%').limit(20);
        if (mounted) setState(() => _results = data);
      }
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
          decoration: const InputDecoration(hintText: 'Pesquisar...', border: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: _performSearch)],
      ),
      body: Column(
        children: [
          // FILTRO DA PESQUISA
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Comunidades'),
                selected: !_searchUsers,
                selectedColor: Theme.of(context).primaryColor,
                onSelected: (val) => setState(() { _searchUsers = false; _performSearch(); }),
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Utilizadores'),
                selected: _searchUsers,
                selectedColor: Theme.of(context).primaryColor,
                onSelected: (val) => setState(() { _searchUsers = true; _performSearch(); }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(child: Text('Nenhum resultado.', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          
                          if (_searchUsers) {
                            // Mostrar Utilizador
                            return Card(
                              color: const Color(0xFF23232F),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: Color(int.parse(item['avatar_color'])).withOpacity(0.3), child: Padding(padding: const EdgeInsets.all(4.0), child: Image.asset('assets/${item['avatar_icon']}.png'))),
                                title: Text(item['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                onTap: () => Navigator.of(context).push(ProfilePage.route(item['id'])),
                              ),
                            );
                          } else {
                            // Mostrar Comunidade
                            return Card(
                              color: const Color(0xFF23232F),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: item['logo_url'] != null ? Image.network(item['logo_url'], width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const Icon(Icons.group)) : const Icon(Icons.group)),
                                title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(item['category'], style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommunityPage(community: item))),
                              ),
                            );
                          }
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
