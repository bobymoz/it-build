import 'package:flutter/material.dart';
class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const ChatListPage());
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Chat Privado')), body: const Center(child: Text('A carregar mensagens...')));
}
