import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const CreateCommunityPage());

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();
  bool _isLoading = false;
  String _selectedCategory = 'Geral';
  String _previewUrl = '';

  final List<String> _categories = [
    'Namoro', 'Filmes e Séries', 'Animes', 'Amizade', 'LGBTQIA+', 'Jogos', 
    'Músicas', 'Arte e Criação', 'Esportes e Exercícios', 'Escola e Faculdade', 
    'Dinheiro e Carreira', 'Fofoca', 'Memes e Humor', 'Perguntas Aleatórias', 
    'Opinião', 'Segredos', 'Autoestima e Depressão', 'Conquistas', 'Conselhos', 'Geral'
  ];

  @override
  void initState() {
    super.initState();
    // Atualiza a pré-visualização quando o utilizador digita o link
    _logoCtrl.addListener(() {
      setState(() => _previewUrl = _logoCtrl.text.trim());
    });
  }

  Future<void> _createCommunity() async {
    if (_nameCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    try {
      await Supabase.instance.client.from('communities').insert({
        'owner_id': Supabase.instance.client.auth.currentUser!.id,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'logo_url': _logoCtrl.text.trim(),
        'category': _selectedCategory,
        'rules': _rulesCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comunidade criada com sucesso!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao criar comunidade.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Comunidade')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Nome da Comunidade'), maxLength: 50),
            const SizedBox(height: 16),
            TextField(controller: _descCtrl, decoration: const InputDecoration(hintText: 'Sobre o que é esta comunidade?'), maxLines: 3),
            const SizedBox(height: 16),
            
            // DROPDOWN EXATO DAS CATEGORIAS QUE PEDISTE
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(hintText: 'Categoria'),
              dropdownColor: const Color(0xFF23232F),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            
            const SizedBox(height: 16),
            TextField(controller: _rulesCtrl, decoration: const InputDecoration(hintText: 'Regras (Opcional)'), maxLines: 2),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  const Text('Logótipo da Comunidade', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Faz upload no imgur.com, copia o "Direct Link" e cola aqui.', style: TextStyle(fontSize: 12, color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextField(controller: _logoCtrl, decoration: const InputDecoration(hintText: 'https://i.imgur.com/...png')),
                  const SizedBox(height: 16),
                  
                  // PRÉ-VISUALIZAÇÃO AO VIVO DA IMAGEM
                  if (_previewUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        _previewUrl,
                        height: 100, width: 100, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Text('Link inválido ou imagem não encontrada', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _createCommunity,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Criar Comunidade'),
            ),
          ],
        ),
      ),
    );
  }
}
