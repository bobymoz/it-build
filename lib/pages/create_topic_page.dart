import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateTopicPage extends StatefulWidget {
  const CreateTopicPage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const CreateTopicPage());

  @override
  State<CreateTopicPage> createState() => _CreateTopicPageState();
}

class _CreateTopicPageState extends State<CreateTopicPage> {
  final _titleCtrl = TextEditingController();
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final data = await Supabase.instance.client.from('categories').select();
    if (mounted) {
      setState(() {
        _categories = data;
        if (_categories.isNotEmpty) _selectedCategoryId = _categories.first['id'].toString();
      });
    }
  }

  Future<void> _createTopic() async {
    if (_titleCtrl.text.isEmpty || _selectedCategoryId == null) return;
    setState(() => _isLoading = true);
    
    try {
      await Supabase.instance.client.from('topics').insert({
        'category_id': _selectedCategoryId,
        'profile_id': Supabase.instance.client.auth.currentUser!.id,
        'title': _titleCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tópico criado com sucesso!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao criar tópico.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Tópico')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'Título do teu tópico...'),
              maxLength: 100,
            ),
            const SizedBox(height: 24),
            const Text('Onde queres publicar?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (_categories.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                dropdownColor: const Color(0xFF23232F),
                items: _categories.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['title']))).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _createTopic,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Publicar Agora'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
