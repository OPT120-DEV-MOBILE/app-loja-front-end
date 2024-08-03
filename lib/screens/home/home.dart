import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? jwt;
  // String? role;

  @override
  void initState() {
    super.initState();
    _getStoredValues();
  }

  Future<void> _getStoredValues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      jwt = prefs.getString('token');
      // role = prefs.getString('role');
    });
  }

  Future<void> _clearStoredValues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    // await prefs.remove('role');
    setState(() {
      jwt = null;
      // role = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (jwt == null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Login'),
              )
            else if (jwt != null)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/user');
                    },
                    child: const Text('Usuários'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _clearStoredValues,
                    child: const Text('Sair'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
