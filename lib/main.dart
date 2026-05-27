import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://cgeddnpcckoqilcqstnk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnZWRkbnBjY2tvcWlsY3FzdG5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2MjU5MjksImV4cCI6MjA5NTIwMTkyOX0.827gFhTAqkSF1OSuysXVr_dACyTPekYwHSqlGHcj9aQ',
  );
  runApp(const RedootApp());
}

class RedootApp extends StatelessWidget {
  const RedootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Redoot',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF181820),
        primaryColor: const Color(0xFFB388FF),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFB388FF), surface: Color(0xFF23232F)),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF181820), elevation: 0, centerTitle: true),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFFB388FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB388FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFF23232F),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFB388FF))),
        ),
      ),
      home: Supabase.instance.client.auth.currentSession != null ? const HomePage() : const LoginPage(),
    );
  }
}

// ==========================================
// UTILS
// ==========================================
class Skeleton extends StatefulWidget {
  final double width, height, borderRadius;
  const Skeleton({super.key, required this.width, required this.height, this.borderRadius = 8});
  @override
  State<Skeleton> createState() => _SkeletonState();
}
class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width, height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              stops: [0.0, _controller.value, 1.0],
              colors: const [Color(0xFF23232F), Color(0xFF333345), Color(0xFF23232F)],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// AUTH PAGES
// ==========================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 100),
              const SizedBox(height: 40),
              TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'O teu e-mail')),
              const SizedBox(height: 16),
              TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Palavra-passe')),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _signIn, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Iniciar sessão'))),
              const SizedBox(height: 16),
              TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordPage())), child: const Text('Esqueceste-te da palavra-passe?', style: TextStyle(color: Colors.white70))),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, child: OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Color(0xFFB388FF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text('Criar conta nova', style: TextStyle(color: Color(0xFFB388FF))))),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}
class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final PageController _pageController = PageController();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendCode() async {
    if (_emailCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(_emailCtrl.text.trim());
      if (mounted) _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao enviar e-mail.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_codeCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(type: OtpType.recovery, token: _codeCtrl.text.trim(), email: _emailCtrl.text.trim());
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: _newPassCtrl.text.trim()));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Palavra-passe alterada!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código inválido.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Conta')),
      body: PageView(
        controller: _pageController, physics: const NeverScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Qual é o teu e-mail?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 30),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(hintText: 'exemplo@email.com')), const SizedBox(height: 30),
              ElevatedButton(onPressed: _isLoading ? null : _sendCode, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Enviar Código')),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Verifica a Caixa de Entrada', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 30),
              TextField(controller: _codeCtrl, decoration: const InputDecoration(hintText: 'Código de 6 dígitos')), const SizedBox(height: 16),
              TextField(controller: _newPassCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Nova palavra-passe')), const SizedBox(height: 30),
              ElevatedButton(onPressed: _isLoading ? null : _resetPassword, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Redefinir e Entrar')),
            ]),
          ),
        ],
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}
class _RegisterPageState extends State<RegisterPage> {
  final PageController _pageController = PageController();
  final _emailCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;
  int _selectedAvatarIndex = 1;
  Color _selectedColor = const Color(0xFFB388FF);
  final List<Color> _colors = [const Color(0xFFB388FF), const Color(0xFFFF8A65), const Color(0xFF81C784), const Color(0xFF64B5F6), const Color(0xFFF06292), const Color(0xFFFFD54F)];

  void _nextPage() { FocusScope.of(context).unfocus(); _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); }
  void _prevPage() { FocusScope.of(context).unfocus(); _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); }

  Future<void> _signUp() async {
    if (_passCtrl.text != _confirmPassCtrl.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senhas não coincidem.'))); return; }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(), password: _passCtrl.text.trim(),
        data: {'username': _userCtrl.text.trim(), 'avatar_icon': _selectedAvatarIndex, 'avatar_color': _selectedColor.value.toString()}
      );
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), child: Row(children: [IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _pageController.page == 0 ? Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage())) : _prevPage()), const Spacer(), Image.asset('assets/logo.png', height: 45), const Spacer(flex: 2)])),
            Expanded(
              child: PageView(
                controller: _pageController, physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep('E-mail', TextField(controller: _emailCtrl, decoration: const InputDecoration(hintText: 'exemplo@email.com')), _nextPage),
                  _buildStep('Nome', TextField(controller: _userCtrl, decoration: const InputDecoration(hintText: 'Como te queres chamar?')), _nextPage),
                  _buildStep('Palavra-passe', Column(children: [TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Palavra-passe')), const SizedBox(height: 16), TextField(controller: _confirmPassCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Confirma'))]), _nextPage),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Avatar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 20),
                        Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: _selectedColor.withOpacity(0.3)), child: Padding(padding: const EdgeInsets.all(8.0), child: Image.asset('assets/$_selectedAvatarIndex.png', fit: BoxFit.contain))), const SizedBox(height: 30),
                        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: List.generate(23, (index) { final avatarId = index + 1; return GestureDetector(onTap: () => setState(() => _selectedAvatarIndex = avatarId), child: Container(width: 55, height: 55, decoration: BoxDecoration(color: _selectedColor.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: _selectedAvatarIndex == avatarId ? Theme.of(context).primaryColor : Colors.transparent, width: 2)), child: Padding(padding: const EdgeInsets.all(4.0), child: Image.asset('assets/$avatarId.png', fit: BoxFit.contain))));})), const SizedBox(height: 30),
                        Wrap(spacing: 10, alignment: WrapAlignment.center, children: _colors.map((color) => GestureDetector(onTap: () => setState(() => _selectedColor = color), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: _selectedColor == color ? Colors.white : Colors.transparent, width: 3))))).toList()), const SizedBox(height: 40),
                        ElevatedButton(onPressed: _isLoading ? null : _signUp, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Entrar')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStep(String title, Widget child, VoidCallback onNext) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 30), child, const SizedBox(height: 30), ElevatedButton(onPressed: onNext, child: const Text('Avançar'))]));
}

// ==========================================
// HOME, FEED & SEARCH
// ==========================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _communities = [];
  bool _isLoadingCommunities = true;
  Map<String, dynamic>? _currentUserProfile;
  bool _isLoadingProfile = true;
  String _selectedCategory = 'Tudo';
  final List<String> _categories = ['Tudo', 'Namoro', 'Filmes e Séries', 'Animes', 'Amizade', 'LGBTQIA+', 'Jogos', 'Músicas', 'Arte e Criação', 'Esportes e Exercícios', 'Escola e Faculdade', 'Dinheiro e Carreira', 'Fofoca', 'Memes e Humor', 'Perguntas Aleatórias', 'Opinião', 'Segredos', 'Autoestima e Depressão', 'Conquistas', 'Conselhos', 'Geral'];

  @override
  void initState() {
    super.initState();
    _fetchCommunities();
    _fetchUserProfile();
  }

  Future<void> _fetchCommunities() async {
    setState(() => _isLoadingCommunities = true);
    final query = Supabase.instance.client.from('communities').select().order('created_at', ascending: false);
    final res = _selectedCategory == 'Tudo' ? await query : await query.eq('category', _selectedCategory);
    if (mounted) setState(() { _communities = res; _isLoadingCommunities = false; });
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client.from('profiles').select().eq('id', userId).single();
      if (mounted) setState(() => _currentUserProfile = data);
    } catch (e) {
      if (mounted) setState(() => _currentUserProfile = {'avatar_icon': 1, 'avatar_color': '4280391411'});
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
            onTap: () { if (_currentUserProfile != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage(userId: Supabase.instance.client.auth.currentUser!.id))); },
            child: _isLoadingProfile ? const CircularProgressIndicator() : CircleAvatar(backgroundColor: Color(int.parse(_currentUserProfile!['avatar_color'])).withOpacity(0.3), child: Padding(padding: const EdgeInsets.all(4.0), child: Image.asset('assets/${_currentUserProfile!['avatar_icon']}.png', fit: BoxFit.contain))),
          ),
        ),
        title: Image.asset('assets/logo.png', height: 35),
        actions: [
          IconButton(icon: const Icon(Icons.search, size: 26), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchPage()))),
          IconButton(icon: const Icon(Icons.notifications_none, size: 26), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage()))),
          IconButton(icon: Image.asset('assets/chat.png', width: 24, height: 24, color: Colors.white), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatListPage()))),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, icon: const Icon(Icons.add_rounded), label: const Text('Criar', style: TextStyle(fontWeight: FontWeight.bold)), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateCommunityPage())).then((_) => _fetchCommunities())),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index]; final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)), selected: isSelected, selectedColor: Theme.of(context).primaryColor, backgroundColor: const Color(0xFF23232F),
                    onSelected: (selected) => setState(() { _selectedCategory = cat; _fetchCommunities(); }),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _isLoadingCommunities
              ? ListView.builder(padding: const EdgeInsets.all(16), itemCount: 5, itemBuilder: (_, __) => Card(margin: const EdgeInsets.symmetric(vertical: 8), color: const Color(0xFF23232F), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [const Skeleton(width: 50, height: 50, borderRadius: 12), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Skeleton(width: 150, height: 16), SizedBox(height: 8), Skeleton(width: double.infinity, height: 12)]))]))))
              : _communities.isEmpty ? const Center(child: Text('Nenhuma comunidade.')) : ListView.builder(
                  padding: const EdgeInsets.all(16), itemCount: _communities.length,
                  itemBuilder: (context, index) {
                    final com = _communities[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), color: const Color(0xFF23232F),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommunityPage(community: com))),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              ClipRRect(borderRadius: BorderRadius.circular(12), child: com['logo_url'] != null && com['logo_url'].toString().isNotEmpty ? Image.network(com['logo_url'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: Colors.grey[800], child: const Icon(Icons.group))) : Container(width: 50, height: 50, color: Colors.grey[800], child: const Icon(Icons.group))),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(com['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 4), Text(com['description'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)])),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}
class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _searchUsers = false;

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) { setState(() => _results = []); return; }
    setState(() => _isLoading = true);
    try {
      final res = _searchUsers ? await Supabase.instance.client.from('profiles').select().ilike('username', '%$query%').limit(20) : await Supabase.instance.client.from('communities').select().ilike('name', '%$query%').limit(20);
      if (mounted) setState(() => _results = res);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao pesquisar.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextField(controller: _searchCtrl, autofocus: true, decoration: const InputDecoration(hintText: 'Pesquisar...', border: InputBorder.none, focusedBorder: InputBorder.none, filled: false), onSubmitted: (_) => _performSearch()), actions: [IconButton(icon: const Icon(Icons.search), onPressed: _performSearch)]),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(label: const Text('Comunidades'), selected: !_searchUsers, selectedColor: Theme.of(context).primaryColor, onSelected: (val) => setState(() { _searchUsers = false; _performSearch(); })), const SizedBox(width: 16),
              ChoiceChip(label: const Text('Utilizadores'), selected: _searchUsers, selectedColor: Theme.of(context).primaryColor, onSelected: (val) => setState(() { _searchUsers = true; _performSearch(); })),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : _results.isEmpty ? const Center(child: Text('Nenhum resultado.', style: TextStyle(color: Colors.white54))) : ListView.builder(
              padding: const EdgeInsets.all(16), itemCount: _results.length,
              itemBuilder: (context, index) {
                final item = _results[index];
                if (_searchUsers) {
                  return Card(color: const Color(0xFF23232F), margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: CircleAvatar(backgroundColor: Color(int.parse(item['avatar_color'])).withOpacity(0.3), child: Padding(padding: const EdgeInsets.all(4.0), child: Image.asset('assets/${item['avatar_icon']}.png'))), title: Text(item['username'], style: const TextStyle(fontWeight: FontWeight.bold)), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage(userId: item['id'])))));
                } else {
                  return Card(color: const Color(0xFF23232F), margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: item['logo_url'] != null ? Image.network(item['logo_url'], width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const Icon(Icons.group)) : const Icon(Icons.group)), title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(item['category'], style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommunityPage(community: item)))));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}
class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final myId = Supabase.instance.client.auth.currentUser!.id;
    final res = await Supabase.instance.client.from('notifications').select('*, posts(*)').eq('profile_id', myId).order('created_at', ascending: false);
    if (mounted) setState(() { _notifications = res; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _notifications.isEmpty ? const Center(child: Text('Nenhuma notificação.', style: TextStyle(color: Colors.white54))) : ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final note = _notifications[index];
          return Card(
            color: const Color(0xFF23232F), margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2), child: Icon(Icons.notifications_active, color: Theme.of(context).primaryColor)),
              title: Text(note['content']),
              onTap: () {
                if (note['posts'] != null) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailPage(post: note['posts'])));
                }
              },
            ),
          );
        },
      ),
    );
  }
}
