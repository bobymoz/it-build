import 'package:flutter/material.dart';
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const NotificationsPage());
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Notificações')), body: const Center(child: Text('A carregar...')));
}
