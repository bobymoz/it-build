import 'package:flutter/material.dart';
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  static Route<void> route() => MaterialPageRoute(builder: (_) => const SearchPage());
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Pesquisa')), body: const Center(child: Text('A carregar...')));
}
