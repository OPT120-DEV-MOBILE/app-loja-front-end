import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppMenu extends StatelessWidget {
  const AppMenu({super.key});

  Future<void> _clearStoredValues(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('idUsuario');
    // ignore: use_build_context_synchronously
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: const Text('Menu'),
            automaticallyImplyLeading: false,
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Usuários'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/user');
            },
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Empresas'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/empresas');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Produtos'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/produtos');
            },
          ),
          ListTile(
            leading: const Icon(Icons.sell),
            title: const Text('Vendas'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/vendas');
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sair'),
            onTap: () => _clearStoredValues(context),
          ),
        ],
      ),
    );
  }
}
