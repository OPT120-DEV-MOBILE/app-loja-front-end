import 'package:app_lojas/screens/home/home.dart';
import 'package:app_lojas/screens/login/login.dart';
import 'package:app_lojas/screens/user/user.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Home',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => LoginScreen(
          onFormSubmitted: () {
            // Navegar para a HomeScreen após o login bem-sucedido
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
        '/user': (context) => const UserScreen(),
      },
    );
  }
}
