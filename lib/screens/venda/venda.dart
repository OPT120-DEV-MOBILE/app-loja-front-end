// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendaScreen extends StatefulWidget {
  const VendaScreen({super.key});

  @override
  _VendaScreenState createState() => _VendaScreenState();
}

class _VendaScreenState extends State<VendaScreen> {
  late bool _isMounted;
  late Future<List<Venda>> _vendaFuture;

  String? jwt;
  String? role;
  String? idUsuario;

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
      setState(() {
        _vendaFuture = _fetchVendas();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(context, '/vendasCriar');
                        if (result == 'created') {
                          _refreshVendas();
                        }
                      },
                      child: const Text('Criar Venda', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return FutureBuilder<List<Venda>>(
      future: _vendaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhuma venda encontrada'));
        } else {
          final vendas = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: vendas.length,
            itemBuilder: (context, index) {
              final venda = vendas[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Código da Venda: ${venda.id}',
                        style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Text('Funcionário: ${venda.funcionario?.nome ?? "Não disponível"}'),
                      Text('Cliente: ${venda.cliente?.nome ?? "Não disponível"}'),
                      Text('Preço Total: R\$ ${venda.precoTotal.toStringAsFixed(2)}'),
                      Text('Parcelas: ${venda.parcelas ?? 'Não disponível'}'),
                      Text('Preço Parcelado: R\$ ${venda.precoParcelado ?? 'Não disponível'}'),
                      Text('Código de Desconto: ${venda.codigoDesconto ?? 'Não disponível'}'),
                      const SizedBox(height: 10),
                      ButtonBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/vendasEditar',
                                arguments: venda.id,
                              );
                              if (result == 'edited') {
                                _refreshVendas();
                              }
                            },
                          ),
                        ],
                      ),
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

  Future<List<Venda>> _fetchVendas() async {
    try {
      final dio = Dio();
      final options = Options(headers: {'jwt-access': jwt});
      final response = await dio.get(
        'http://localhost:3300/vendas/',
        options: options,
      );

      if (response.statusCode == 201 && _isMounted) {
        final List<dynamic> responseData = response.data;
        return responseData.map((json) => Venda.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vendas');
      }
    } catch (error) {
      if (_isMounted) {
        setState(() {
          // Handle the error state in the FutureBuilder
        });
      }
      throw Exception('Failed to load vendas: $error');
    }
  }
}

class Venda {
  final int id;
  final double precoTotal;
  final int? parcelas;
  final double? precoParcelado;
  final String? codigoDesconto;
  final Usuario? funcionario;
  final Usuario? cliente;

  Venda({
    required this.id,
    required this.precoTotal,
    this.parcelas,
    this.precoParcelado,
    this.codigoDesconto,
    this.funcionario,
    this.cliente,
  });

  factory Venda.fromJson(Map<String, dynamic> json) {
    return Venda(
      id: json['id'],
      precoTotal: json['precoTotal'],
      parcelas: json['parcelas'],
      precoParcelado: json['precoParcelado'],
      codigoDesconto: json['codigoDesconto'],
      funcionario: json['Funcionario'] != null
          ? Usuario.fromJson(json['Funcionario'])
          : null,
      cliente: json['Cliente'] != null
          ? Usuario.fromJson(json['Cliente'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'precoTotal': precoTotal,
      'parcelas': parcelas,
      'precoParcelado': precoParcelado,
      'codigoDesconto': codigoDesconto,
      'Funcionario': funcionario?.toJson(),
      'Cliente': cliente?.toJson(),
    };
  }
}

class Usuario {
  final int id;
  final String nome;
  final String email;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
    };
  }
}
