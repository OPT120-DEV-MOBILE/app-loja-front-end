import 'package:app_lojas/screens/VendaCriar/vendaCriar.dart';
import 'package:app_lojas/screens/VendaEditar/VendaEditar.dart';
import 'package:app_lojas/screens/empresa/empresa.dart';
import 'package:app_lojas/screens/home/home.dart';
import 'package:app_lojas/screens/login/login.dart';
import 'package:app_lojas/screens/product/product.dart';
import 'package:app_lojas/screens/relatorio/relatorio.dart';
import 'package:app_lojas/screens/user/user.dart';
import 'package:app_lojas/screens/venda/venda.dart';
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
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
        '/user': (context) => const UserScreen(),
        '/empresas': (context) => const EmpresaScreen(),
        '/produtos': (context) => const ProductScreen(),
        '/vendas': (context) => const VendaScreen(),
        '/vendasCriar': (context) => const VendaCriarScreen(),
        '/vendasEditar': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int;
          return VendaEditarScreen(id: id);
        },
        '/relatorio': (context) => const RelatorioScreen(),
      },
    );
  }
}
