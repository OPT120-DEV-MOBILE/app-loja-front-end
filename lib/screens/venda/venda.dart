// ignore_for_file: library_private_types_in_public_api

import 'package:app_lojas/menu/menu.dart';
import 'package:app_lojas/styles/styles_app.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _vendaFuture = Future.value([]);
    _getStoredValues().then((_) {
      _refreshVendas();
    });
    _searchController.addListener(_onSearchChanged);
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
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _refreshVendas() async {
    if (_isMounted) {
      setState(() {
        _vendaFuture = _fetchVendas();
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _vendaFuture = _fetchVendas(query: _searchController.text);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vendas', style: AppStyles.largeTextStyle),
        backgroundColor: AppStyles.primaryColor,
      ),
      drawer: const AppMenu(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: AppStyles.textFieldDecoration.copyWith(
                      hintText: 'Pesquisar por funcionário ou cliente',
                      hintStyle: AppStyles.formTextStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      style: AppStyles.elevatedButtonStyle,
                      onPressed: () async {
                        final result = await Navigator.pushNamed(context, '/vendasCriar');
                        if (result == 'created') {
                          _refreshVendas();
                        }
                      },
                      child: Text('Criar Venda', style: AppStyles.smallTextStyle,),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildList(context),
            ],
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
              double valorComDesconto = venda.precoTotal;
              if (venda.codigoDesconto != null && venda.codigoDesconto!.isNotEmpty) {
                valorComDesconto = aplicarDesconto(venda.precoTotal, venda.codigoDesconto!);
              }

              return Card(
                shape: AppStyles.cardTheme.shape,
                margin: AppStyles.cardTheme.margin,
                elevation: AppStyles.cardTheme.elevation,
                color: AppStyles.cardTheme.color,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Código da Venda: ${venda.id}',
                          style: AppStyles.listItemTitleStyle),
                      const SizedBox(height: 10),
                      Text('Funcionário: ${venda.funcionario?.nome ?? "Não disponível"}', style: AppStyles.listItemSubtitleStyle),
                      Text('Cliente: ${venda.cliente?.nome ?? "Não disponível"}', style: AppStyles.listItemSubtitleStyle),
                      Text('Preço Total: R\$ ${venda.precoTotal.toStringAsFixed(2)}', style: AppStyles.listItemSubtitleStyle),
                      if (venda.codigoDesconto != null) // Exibe o valor com desconto se houver
                        Text('Preço com Desconto: R\$ ${valorComDesconto.toStringAsFixed(2)}', style: AppStyles.listItemSubtitleStyle),
                      Text('Parcelas: ${venda.parcelas ?? 'Não disponível'}', style: AppStyles.listItemSubtitleStyle),
                      Text('Preço Parcelado: R\$ ${venda.precoParcelado ?? 'Não disponível'}', style: AppStyles.listItemSubtitleStyle),
                      Text('Código de Desconto: ${venda.codigoDesconto ?? 'Não disponível'}', style: AppStyles.listItemSubtitleStyle),
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
                            color: AppStyles.primaryColor, 
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

  double aplicarDesconto(double precoTotal, String codigoDesconto) {
    double desconto = 0.0;
    
    if (codigoDesconto.startsWith('ganhe')) {
      final porcentagem = double.tryParse(codigoDesconto.substring(5)) ?? 0;
      
      if (porcentagem > 0 && porcentagem <= 40) {
        desconto = porcentagem / 100;
      } else {
        Fluttertoast.showToast(
          msg: "O desconto não pode ser maior que 40%",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return precoTotal;
      }
    }

    return precoTotal * (1 - desconto);
  }


  Future<List<Venda>> _fetchVendas({String? query}) async {
    try {
      final dio = Dio();
      final options = Options(headers: {'jwt-access': jwt});
      final response = await dio.get(
        'http://localhost:3300/vendas/',
        queryParameters: query != null && query.isNotEmpty ? {'venda': query} : null,
        options: options,
      );

      if (response.statusCode == 201 && _isMounted) {
        final List<dynamic> responseData = response.data['vendas'];
        return responseData.map((json) => Venda.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vendas');
      }
    } catch (error) {
      if (_isMounted) {
        setState(() {
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
