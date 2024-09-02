// ignore_for_file: file_names

import 'package:app_lojas/styles/styles_app.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart'; 

class VendaCriarScreen extends StatefulWidget {
  const VendaCriarScreen({super.key});

  @override
  VendaCriarState createState() => VendaCriarState();
}

class VendaCriarState extends State<VendaCriarScreen> {
  String? jwt;
  String? role;
  String? idUsuario;

  final _formKey = GlobalKey<FormState>();
  final _nameClienteController = TextEditingController();
  final _emailClienteController = TextEditingController();
  final _cpfClienteController = MaskedTextController(mask: '000.000.000-00');
  final _parcelasController = TextEditingController();
  final _precoParceladoController = TextEditingController();
  final _codigoDescontoController = TextEditingController();
  
  List<Map<String, dynamic>> produtos = [];
  List<Map<String, dynamic>> produtosSelecionados = [];
  String? clienteId;

  @override
  void initState() {
    super.initState();
    _getStoredValues().then((_) {
      _fetchProdutos();
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

  Future<void> _fetchProdutos() async {
    try {
      final response = await Dio().get('http://localhost:3300/produtos/');

      if (response.statusCode == 201) {
        if (response.data.containsKey('Produtos')) {
          setState(() {
            produtos = List<Map<String, dynamic>>.from(response.data['Produtos']);
          });
        }
      } else {
        Fluttertoast.showToast(
          msg: "Erro ao buscar produtos: ${response.statusCode}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 20.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Erro ao buscar produtos, verifique o banco de dados",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 20.0,
      );
    }
  }

  Future<void> _fetchClienteData() async {
    final cpf = _cpfClienteController.text;
    if (cpf.length != 14) return;

    try {
      final options = Options(headers: {'jwt-access': jwt});
      final response = await Dio().get(
        'http://localhost:3300/users/getUser/?cpf=$cpf',
        options: options,
      );
      
      if (response.statusCode == 201) {
        final data = response.data;
        if (data['status'] == 'sucesso') {
          final cliente = data['usuarios'];
          setState(() {
            clienteId = cliente['id'].toString();
            _nameClienteController.text = cliente['nome'];
            _emailClienteController.text = cliente['email'];
          });
        } else {
          setState(() {
            _nameClienteController.text = '';
            _emailClienteController.text = '';
          });
          Fluttertoast.showToast(
            msg: "Erro ao buscar, cliente não existe!",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 20.0,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "Erro ao buscar cliente: ${response.statusCode}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 20.0,
        );
      }
    } catch (e) {
      setState(() {
        _nameClienteController.text = '';
        _emailClienteController.text = '';
        clienteId = null;
      });
      Fluttertoast.showToast(
        msg: "Erro ao buscar, cliente não existe!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 20.0,
      );
    }
  }

  @override
  void dispose() {
    _nameClienteController.dispose();
    _emailClienteController.dispose();
    _cpfClienteController.dispose();
    _parcelasController.dispose();
    _precoParceladoController.dispose();
    _codigoDescontoController.dispose();
    super.dispose();
  }

  double _calcularPrecoTotal() {
    return produtosSelecionados.fold(
      0.0,
      (total, produto) => total + (produto['quantidade'] * produto['preco']),
    );
  }

  double _calcularPrecoParcelado() {
    final precoTotal = _calcularPrecoTotal();
    final parcelas = int.tryParse(_parcelasController.text) ?? 1;
    return parcelas > 0 ? precoTotal / parcelas : 0.0;
  }

  double _aplicarDesconto(double precoTotal) {
    final codigoDesconto = _codigoDescontoController.text;
    if (codigoDesconto.startsWith('ganhe')) {
      final porcentagem = double.tryParse(codigoDesconto.substring(5)) ?? 0;
      if (porcentagem > 40) {
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
      return precoTotal * (1 - porcentagem / 100);
    }
    return precoTotal;
  }

  Future<void> _confirmarVenda() async {
    if (!_formKey.currentState!.validate()) return;

    final precoTotal = _calcularPrecoTotal();
    final precoParcelado = double.tryParse(_precoParceladoController.text) ?? 0;
    final parcelas = int.tryParse(_parcelasController.text) ?? 1;

    final idUsuarioInt = idUsuario is int ? idUsuario : int.tryParse(idUsuario.toString()) ?? 0;
    final clienteIdInt = clienteId is int ? clienteId : int.tryParse(clienteId.toString()) ?? 0;

    final vendaData = {
      'idUsuario': idUsuarioInt,
      'idCliente': clienteIdInt,
      'precoTotal': precoTotal,
      'parcelas': parcelas,
      'precoParcelado': precoParcelado,
      'codigoDesconto': _codigoDescontoController.text,
      'produtos': produtosSelecionados.map((produto) {
        return {
          'idProduto': produto['id'],
          'quantidade': produto['quantidade'],
          'preco': produto['preco'],
        };
      }).toList(),
    };

    try {
      final options = Options(headers: {'jwt-access': jwt});
      final response = await Dio().post(
        'http://localhost:3300/vendas/register',
        data: vendaData,
        options: options,
      );

      if (response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: "Venda confirmada com sucesso!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, '/vendas');
      } else {
        Fluttertoast.showToast(
          msg: "Erro ao confirmar venda: ${response.statusCode}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Erro ao confirmar venda, tente novamente",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Criar Venda', style: AppStyles.largeTextStyle),
        backgroundColor: AppStyles.primaryColor,
      ),
      body: Center(
        child: Container(
          width: 1200,
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cpfClienteController,
                          decoration: AppStyles.textFieldDecoration.copyWith(
                            hintText: 'Pesquisar por CPF',
                            hintStyle: AppStyles.formTextStyle,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o CPF';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: AppStyles.elevatedButtonStyle,
                        onPressed: _fetchClienteData,
                        child: Text('Buscar', style: AppStyles.smallTextStyle,),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameClienteController,
                          decoration: AppStyles.textFieldDecoration.copyWith(
                            hintText: 'Nome',
                            hintStyle: AppStyles.formTextStyle,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o nome';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emailClienteController,
                          decoration: AppStyles.textFieldDecoration.copyWith(
                            hintText: 'Email',
                            hintStyle: AppStyles.formTextStyle,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o email';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownSearch<Map<String, dynamic>>(
                    items: produtos,
                    itemAsString: (item) => "${item['nome']} - R\$ ${item['preco']}",
                    onChanged: (value) {
                      if (value != null) {
                        final existingProduct = produtosSelecionados.firstWhere(
                          (produto) => produto['id'] == value['id'],
                          orElse: () => {},
                        );

                        if (existingProduct.isEmpty) {
                          setState(() {
                            produtosSelecionados.add({
                              ...value,
                              'quantidade': 1,
                              'quantidadeDisponivel': value['quantidade'],
                              'preco': value['preco'],
                            });
                          });
                        } else {
                          Fluttertoast.showToast(
                            msg: "Produto já selecionado!",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.TOP,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        }
                      }
                    },
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: AppStyles.textFieldDecoration.copyWith(
                        labelText: 'Selecione o Produto',
                        labelStyle: AppStyles.formTextStyle,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    popupProps: PopupProps.dialog(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: AppStyles.textFieldDecoration.copyWith(
                          hintText: 'Pesquise por nome',
                          hintStyle: AppStyles.formTextStyle,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (produtosSelecionados.isEmpty) {
                        return 'Por favor, selecione ao menos um produto';
                      }
                      return null;
                    },
                  ),
                  const Divider(),
                  ...produtosSelecionados.map((produto) {
                    return Row(
                      children: [
                        Expanded(child: Text('${produto['nome']} - R\$ ${produto['preco'].toStringAsFixed(2)}')),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: produto['quantidade'].toString(),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final quantidade = int.tryParse(value) ?? 0;
                              if (quantidade > 0 && quantidade <= produto['quantidadeDisponivel']) {
                                setState(() {
                                  produto['quantidade'] = quantidade;
                                });
                                _precoParceladoController.text = _calcularPrecoParcelado().toStringAsFixed(2);
                              } else {
                                Fluttertoast.showToast(
                                  msg: "Quantidade máxima é de ${produto['quantidadeDisponivel']}!",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.TOP,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0,
                                );
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'R\$ ${(produto['quantidade'] * produto['preco']).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              produtosSelecionados.remove(produto);
                            });
                            _precoParceladoController.text = _calcularPrecoParcelado().toStringAsFixed(2);
                          },
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _parcelasController,
                    keyboardType: TextInputType.number,
                    decoration: AppStyles.textFieldDecoration.copyWith(
                      hintText: 'Número de Parcelas',
                      hintStyle: AppStyles.formTextStyle,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      final int parcelas = int.tryParse(value) ?? 0;
                      if (parcelas > 10) {
                        Fluttertoast.showToast(
                          msg: "Número de parcelas não pode ser maior que 10",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.TOP,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                        _parcelasController.text = '10';
                      }

                      setState(() {
                        _precoParceladoController.text = _calcularPrecoParcelado().toStringAsFixed(2);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codigoDescontoController,
                    decoration: AppStyles.textFieldDecoration.copyWith(
                      hintText: 'Código de Desconto',
                      hintStyle: AppStyles.formTextStyle,
                    ),
                    onChanged: (_) {
                      setState(() {
                        final precoTotal = _calcularPrecoTotal();
                        _aplicarDesconto(precoTotal);
                        _precoParceladoController.text = _calcularPrecoParcelado().toStringAsFixed(2);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quantidade de Parcelas: ${_parcelasController.text}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Valor por Parcelas: R\$ ${_calcularPrecoParcelado().toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preço Total: R\$ ${_aplicarDesconto(_calcularPrecoTotal()).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _confirmarVenda,
                    style: AppStyles.elevatedButtonStyle,
                    child: const Text('Confirmar Venda'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
