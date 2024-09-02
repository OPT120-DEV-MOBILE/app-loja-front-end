import 'package:app_lojas/menu/menu.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../user/user.dart';

class RelatorioScreen extends StatefulWidget {
  const RelatorioScreen({super.key});

  @override
  _RelatorioScreenState createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  late Future<Map<String, Map<String, dynamic>>> _vendaFuture =
      Future.value({});

  String? jwt;
  late bool _isMounted;

  String? role;
  String? idUsuario;

  String _selectedReportType = 'Funcionários';

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _getStoredValues().then((_) {
      _refreshVendas();
    });
  }

  Future<void> _getStoredValues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      jwt = prefs.getString('token');
      role = prefs.getString('role');
      idUsuario = prefs.getString('idUsuario');
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _refreshVendas() async {
    if (_isMounted) {
      try {
        final Map<String, String> cpfToNameMap = await _fetchUserCpfs();
        final Map<String, Map<String, dynamic>> vendasPorNome = {};

        for (String cpf in cpfToNameMap.keys) {
          final Map<String, dynamic> relatorio =
              await _fetchRelatorio(cpf: cpf);

          vendasPorNome[cpfToNameMap[cpf] ?? 'Desconhecido'] = {
            'total': relatorio['valorTotalVendas'],
            'quantidade': relatorio['totalVendas'],
          };
        }

        setState(() {
          _vendaFuture = Future.value(vendasPorNome);
        });
      } catch (e) {
        // Handle error
        setState(() {
          _vendaFuture = Future.error('Failed to load vendas');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _selectedReportType = value;
                _refreshVendas(); // Atualiza a lista de vendas ao selecionar um relatório
              });
            },
            itemBuilder: (BuildContext context) {
              return ['Funcionários', 'Clientes'].map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      drawer: const AppMenu(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: _vendaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhuma venda encontrada'));
        } else {
          final vendasPorNome = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vendasPorNome.length,
            itemBuilder: (context, index) {
              final nome = vendasPorNome.keys.elementAt(index);
              final totalVendas = vendasPorNome[nome]!['total'];
              final quantidade = vendasPorNome[nome]!['quantidade'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nome: $nome',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text(
                          'Quantidade de ${_selectedReportType == 'Clientes' ? 'Compras' : 'Vendas'}: $quantidade'),
                      const SizedBox(height: 10),
                      Text(
                          'Total de ${_selectedReportType == 'Clientes' ? 'Compras' : 'Vendas'}: R\$ ${double.tryParse(totalVendas.toString())?.toStringAsFixed(2) ?? '0.00'}'),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  Future<Map<String, dynamic>> _fetchRelatorio({required String cpf}) async {
    try {
      final dio = Dio();
      final options = Options(headers: {'jwt-access': jwt});
      final String endpoint = _selectedReportType == 'Clientes'
          ? 'http://localhost:3300/vendas/relatorio/cliente'
          : 'http://localhost:3300/vendas/relatorio/funcionario';

      final response = await dio.get(
        endpoint,
        queryParameters: {'cpf': cpf},
        options: options,
      );

      if (response.statusCode == 201 && _isMounted) {
        return response.data;
      } else {
        throw Exception('Failed to load vendas');
      }
    } catch (error) {
      if (_isMounted) {
        setState(() {});
      }
      throw Exception('Failed to load vendas: $error');
    }
  }

  Future<Map<String, String>> _fetchUserCpfs({String? query}) async {
    try {
      final dio = Dio();
      final options = Options(headers: {'jwt-access': jwt});
      final response = await dio.get(
        'http://localhost:3300/users/',
        queryParameters:
            query != null && query.isNotEmpty ? {'usuario': query} : null,
        options: options,
      );

      if (response.statusCode == 201 && _isMounted) {
        final List<dynamic> responseData = response.data['usuarios'];
        final Map<String, String> cpfToNameMap = {};
        final List<User> users =
            responseData.map((json) => User.fromJson(json)).toList();
        for (var user in users) {
          if (_selectedReportType == 'Funcionários' && user.role.id != 4) {
            cpfToNameMap[user.cpf] = user.nome;
          } else if (_selectedReportType == 'Clientes' && user.role.id == 4) {
            cpfToNameMap[user.cpf] = user.nome;
          }
        }
        return cpfToNameMap;
      } else {
        throw Exception('Failed to load users');
      }
    } catch (error) {
      if (_isMounted) {
        setState(() {
          // Handle the error state in the FutureBuilder
        });
      }
      throw Exception('Failed to load users: $error');
    }
  }
}
