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
  final _categoryCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _createCommunity() async {
    if (_nameCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    try {
      await Supabase.instance.client.from('communities').insert({
        'owner_id': Supabase.instance.client.auth.currentUser!.id,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'logo_url': _logoCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'rules': _rulesCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comunidade criada!')));
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
            TextField(controller: _categoryCtrl, decoration: const InputDecoration(hintText: 'Categoria (Ex: Jogos, Tecnologia...)')),
            const SizedBox(height: 16),
            TextField(controller: _rulesCtrl, decoration: const InputDecoration(hintText: 'Regras (Opcional)'), maxLines: 2),
            const SizedBox(height: 24),
            
            // Secção da Imagem
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  const Text('Logótipo da Comunidade', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Dica: Faz upload da imagem no imgur.com, copia o "Direct Link" (terminado em .png ou .jpg) e cola aqui.', style: TextStyle(fontSize: 12, color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextField(controller: _logoCtrl, decoration: const InputDecoration(hintText: 'https://i.imgur.com/...png')),
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
