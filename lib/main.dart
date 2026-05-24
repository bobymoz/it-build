import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
// 1. INICIALIZAÇÃO E CONEXÃO COM SUPABASE
// ==========================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suas credenciais oficiais
  await Supabase.initialize(
    url: 'https://cgeddnpcckoqilcqstnk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnZWRkbnBjY2tvcWlsY3FzdG5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2MjU5MjksImV4cCI6MjA5NTIwMTkyOX0.827gFhTAqkSF1OSuysXVr_dACyTPekYwHSqlGHcj9aQ',
  );

  runApp(const ForumApp());
}

final supabase = Supabase.instance.client;

// ==========================================
// 2. TEMA PRINCIPAL (MODO ESCURO MODERNO)
// ==========================================
class ForumApp extends StatelessWidget {
  const ForumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fórum Jovem',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A), // Fundo super escuro
        primaryColor: const Color(0xFF8B5CF6), // Roxo moderno vibrante
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF10B981), // Verde para detalhes/grana
          surface: Color(0xFF171717), // Cor dos cards
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ==========================================
// 3. CONTROLE DE SESSÃO (LOGADO VS NÃO LOGADO)
// ==========================================
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Ouve as mudanças de autenticação (login/logout)
    supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    // Se tem sessão, vai pro Feed. Se não, vai pro Login.
    return session == null ? const TelaLogin() : const TelaPrincipal();
  }
}

// ==========================================
// 4. TELA DE LOGIN SIMPLES
// ==========================================
class TelaLogin extends StatelessWidget {
  const TelaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.flame, size: 80, color: Color(0xFF8B5CF6)),
              const SizedBox(height: 20),
              Text('Fórum Jovem', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              const Text('Conecte-se para ver as tretas e confissões.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  // Aqui depois faremos o login real. Para testar a UI, vamos usar um signIn anônimo ou pular.
                  // Simulando entrada para ver o design:
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TelaPrincipal()));
                },
                child: const Text('Entrar (Modo Visitante)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. TELA PRINCIPAL (FEED, NAVEGAÇÃO, CHAT)
// ==========================================
class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _abaAtual = 0;
  String _topicoSelecionado = 'Tudo';

  final List<String> _topicos = ['Tudo', 'Confissões', 'Futuro e Grana', 'Namoro', 'Hobbies', 'Tretas'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fórum', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 24)),
        actions: [
          IconButton(icon: const Icon(LucideIcons.bell), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Barra de Tópicos Deslizante
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _topicos.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final topico = _topicos[index];
                final isSelected = topico == _topicoSelecionado;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(topico, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey[400])),
                    selected: isSelected,
                    selectedColor: const Color(0xFF8B5CF6),
                    backgroundColor: const Color(0xFF171717),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      setState(() => _topicoSelecionado = topico);
                    },
                  ),
                );
              },
            ),
          ),
          
          // Feed de Posts
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3, // Mock de 3 posts para você ver o design
              itemBuilder: (context, index) {
                return CardPost(topico: _topicoSelecionado == 'Tudo' ? _topicos[index + 1] : _topicoSelecionado);
              },
            ),
          ),
        ],
      ),
      // Botão Flutuante de Criar Post
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B5CF6),
        child: const Icon(LucideIcons.penTool, color: Colors.white),
        onPressed: () {
          // Ação para criar post
        },
      ),
      // Menu Inferior
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0A0A0A),
        selectedItemColor: const Color(0xFF8B5CF6),
        unselectedItemColor: Colors.grey[600],
        currentIndex: _abaAtual,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _abaAtual = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.messageCircle), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Perfil'),
        ],
      ),
    );
  }
}

// ==========================================
// 6. DESIGN DO CARD DE POST
// ==========================================
class CardPost extends StatelessWidget {
  final String topico;
  const CardPost({super.key, required this.topico});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do Post
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF8B5CF6),
                child: Icon(LucideIcons.user, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('UsuarioAnonimo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Há 2 horas • Em $topico', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              const Icon(LucideIcons.moreVertical, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          
          // Texto do Post
          const Text(
            'Fiz uma burrada gigante hoje. Preciso de conselhos, não sei o que fazer. Alguém já passou por isso?',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Imagem (Placeholder)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Icon(LucideIcons.image, color: Colors.grey, size: 40)),
          ),
          const SizedBox(height: 16),

          // Interações (Like, Dislike, Comentários)
          Row(
            children: [
              _buildIconAction(LucideIcons.thumbsUp, '24'),
              const SizedBox(width: 16),
              _buildIconAction(LucideIcons.thumbsDown, '2'),
              const SizedBox(width: 16),
              _buildIconAction(LucideIcons.messageSquare, '12'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIconAction(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 6),
        Text(count, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
      ],
    );
  }
}
