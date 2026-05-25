import 'package:flutter/material.dart';
class ProfilePage extends StatelessWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});
  static Route<void> route(String id) => MaterialPageRoute(builder: (_) => ProfilePage(userId: id));
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Perfil')), body: const Center(child: Text('A carregar perfil...')));
}
