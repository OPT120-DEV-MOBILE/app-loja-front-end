// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:app_lojas/menu/menu.dart';
import 'package:app_lojas/styles/styles_app.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late bool _isMounted;
  late Future<List<Product>> _productFuture;

  String? jwt;
  String? role;
  String? idUsuario;
  final TextEditingController _searchController = TextEditingController(); // Controlador para o campo de pesquisa
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _productFuture = Future.value([]);
    _getStoredValues().then((_) {
      setState(() {
        _productFuture = _fetchProducts();
      });
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

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _productFuture = _fetchProducts(query: _searchController.text);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Produtos', style: AppStyles.largeTextStyle),
        backgroundColor: AppStyles.primaryColor,
      ),
      drawer: const AppMenu(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: AppStyles.textFieldDecoration.copyWith(
                        hintText: 'Pesquisar por código ou nome',
                        hintStyle: AppStyles.formTextStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      style: AppStyles.elevatedButtonStyle,
                      onPressed: () {
                        _openCreateProductForm(context);
                      },
                      child: Text('Criar Produto', style: AppStyles.smallTextStyle,),
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
    return FutureBuilder<List<Product>>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhum produto encontrado'));
        } else {
          final products = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
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
                      Text('Nome: ${product.nome}',
                          style: AppStyles.listItemTitleStyle),
                      Text('Preco: ${product.preco}', style: AppStyles.listItemSubtitleStyle),
                      Text('Descrição: ${product.descricao}', style: AppStyles.listItemSubtitleStyle),
                      Text('Quantidade: ${product.quantidade}', style: AppStyles.listItemSubtitleStyle),
                      Text(
                        'Data de fabricação: ${DateFormat('dd-MM-yyyy').format(product.dataDeFabricacao)}', style: AppStyles.listItemSubtitleStyle
                      ),
                      Text(
                        'Data de validade: ${DateFormat('dd-MM-yyyy').format(product.dataDeValidade)}', style: AppStyles.listItemSubtitleStyle
                      ),
                      ButtonBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                              _openEditProductForm(context, product),
                              color: AppStyles.primaryColor, 
                          ),
                          // IconButton(
                          //   icon: const Icon(Icons.delete),
                          //   onPressed: () => _deleteUser(user.id),
                          // ),
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

  Future<List<Product>> _fetchProducts({String? query}) async {
    try {
      final dio = Dio();
      final options = Options(headers: {'JWT': jwt});
      final response = await dio.get(
        'http://localhost:3300/produtos/',
        queryParameters: query != null && query.isNotEmpty ? {'produto': query} : null,
        options: options,
      );
      // print(response);
      if (response.statusCode == 201 && _isMounted) {
        final List<dynamic> responseData = response.data['Produtos'];
        return responseData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (error) {
      if (_isMounted) {
        setState(() {
        });
      }
      throw Exception('Failed to load products: $error');
    }
  }

  void _openCreateProductForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Criar Produto', style: AppStyles.formTitleStyle),
          content: IntrinsicHeight(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 600,
                child: ProductForm(
                  onFormSubmitted: () {
                    setState(() {
                      _productFuture = _fetchProducts();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openEditProductForm(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Produto', style: AppStyles.formTitleStyle),
          content: IntrinsicHeight(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 600,
                child: EditProductForm(
                  product: product,
                  jwt: jwt!,
                  onFormSubmitted: () {
                    setState(() {
                      _productFuture = _fetchProducts();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // void _deleteUser(int userId) async {
  //   try {
  //     final dio = Dio();
  //     final options = Options(headers: {'jwt': jwt});
  //     final response = await dio.put(
  //       'http://localhost:3000/users/$userId?roleUser=$role',
  //       data: {'desabilitado': true},
  //       options: options,
  //     );

  //     if (response.statusCode == 200) {
  //       setState(() {
  //         _productFuture = _fetchProducts();
  //       });
  //     } else {
  //       // Handle error
  //     }
  //   } catch (error) {
  //     // Handle error
  //   }
  // }
}

class ProductForm extends StatefulWidget {
  final Function onFormSubmitted;

  const ProductForm({super.key, required this.onFormSubmitted});

  @override
  _ProductFormState createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _precoController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dataDeFabricacaoController = TextEditingController();
  final _dataDeValidadeController = TextEditingController();

  DateTime? _dateFabricacao;
  DateTime? _dateValidade;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
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
          const SizedBox(height: 10),
          TextFormField(
            controller: _precoController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Preço',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o preço';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descriptionController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Descrição',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira a descrição';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _amountController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Quantidade',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o quantidade';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _dataDeFabricacaoController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              suffixIcon: const Icon(Icons.calendar_today, color: AppStyles.primaryColor,),
              hintText: 'Data de fabricação',
              hintStyle: AppStyles.formTextStyle,
            ),
            onTap: () async {
              DateTime? pickeddate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                initialDatePickerMode: DatePickerMode.year,
              );

              if (pickeddate != null) {
                setState(
                  () {
                    _dateFabricacao = pickeddate;
                    _dataDeFabricacaoController.text =
                        DateFormat('dd-MM-yyyy').format(pickeddate);
                  },
                );
              }
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _dataDeValidadeController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              suffixIcon: const Icon(Icons.calendar_today, color: AppStyles.primaryColor,),
              hintText: 'Data de validade',
              hintStyle: AppStyles.formTextStyle,
            ),
            onTap: () async {
              DateTime? pickeddate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                initialDatePickerMode: DatePickerMode.year,
              );

              if (pickeddate != null) {
                setState(
                  () {
                    _dateValidade = pickeddate;
                    _dataDeValidadeController.text =
                        DateFormat('dd-MM-yyyy').format(pickeddate);
                  },
                );
              }
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _submitForm();
              }
            },
            style: AppStyles.elevatedButtonStyle,
            child: const Text('Criar Produto'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final preco = double.tryParse(_precoController.text.replaceAll(',', '.')) ?? 0.0;
        final quantidade = int.tryParse(_amountController.text) ?? 0;
        final dataDeFabricacao = _dateFabricacao != null
          ? '${DateFormat('yyyy-MM-ddTHH:mm:ss').format(_dateFabricacao!.toUtc())}Z'
          : '';
        final dataDeValidade = _dateValidade != null
          ? '${DateFormat('yyyy-MM-ddTHH:mm:ss').format(_dateValidade!.toUtc())}Z'
          : '';
          
        final response = await Dio().post(
          'http://localhost:3300/produtos/',
          data: {
            'nome': _nameController.text,
            'preco': preco,
            'descricao': _descriptionController.text,
            'quantidade': quantidade,
            'dataDeFabricacao': dataDeFabricacao,
            'dataDeValidade': dataDeValidade
          },
        );

        if (response.statusCode == 201) {
          Fluttertoast.showToast(
            msg: "Produto Cadastrado com sucesso!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          widget.onFormSubmitted();
        } else {
          Fluttertoast.showToast(
            msg: "Erro ao cadatrar Produto, verifique os dados!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } catch (error) {
        Fluttertoast.showToast(
          msg: "Erro ao cadatrar Produto, verifique a conexão com o banco de dados!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _precoController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _dataDeFabricacaoController.dispose();
    _dataDeValidadeController.dispose();
    super.dispose();
  }
}

class EditProductForm extends StatefulWidget {
  final Product product;
  final String jwt;
  final Function onFormSubmitted;

  const EditProductForm({
    super.key,
    required this.product,
    required this.jwt,
    required this.onFormSubmitted,
  });

  @override
  _EditProductFormState createState() => _EditProductFormState();
}

class _EditProductFormState extends State<EditProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _precoController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dataDeFabricacaoController = TextEditingController();
  final _dataDeValidadeController = TextEditingController();

  DateTime? _dateFabricacao;
  DateTime? _dateValidade;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product.nome;
    _precoController.text = widget.product.preco.toString();
    _descriptionController.text = widget.product.descricao;
    _amountController.text = widget.product.quantidade.toString();
    _dateFabricacao = widget.product.dataDeFabricacao;
    _dateValidade = widget.product.dataDeValidade;
    _dataDeFabricacaoController.text = DateFormat('yyyy-MM-dd').format(_dateFabricacao ?? DateTime.now());
    _dataDeValidadeController.text = DateFormat('yyyy-MM-dd').format(_dateValidade ?? DateTime.now());
  }

  Future<void> _submitUpdateForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Formata o preço e a quantidade
        final preco = double.tryParse(_precoController.text.replaceAll(',', '.')) ?? 0.0;
        final quantidade = int.tryParse(_amountController.text) ?? 0;

        // Formata as datas no formato ISO-8601 com timezone UTC
        final dataDeFabricacao = _dateFabricacao != null
          ? '${DateFormat('yyyy-MM-ddTHH:mm:ss').format(_dateFabricacao!.toUtc())}Z'
          : null;
        final dataDeValidade = _dateValidade != null
          ? '${DateFormat('yyyy-MM-ddTHH:mm:ss').format(_dateValidade!.toUtc())}Z'
          : null;

        final dio = Dio();
        final response = await dio.put(
          'http://localhost:3300/produtos/',
          data: {
            'id': widget.product.id,
            'nome': _nameController.text,
            'preco': preco,
            'descricao': _descriptionController.text,
            'quantidade': quantidade,
            'dataDeFabricacao': dataDeFabricacao,
            'dataDeValidade': dataDeValidade
          },
          options: Options(headers: {'JWT': widget.jwt}),
        );

        if (response.statusCode == 201) {
          Fluttertoast.showToast(
            msg: "Produto Editado com sucesso!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          widget.onFormSubmitted();
        } else {
          Fluttertoast.showToast(
            msg: "Erro ao editar Produto, verifique os dados!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } catch (error) {
        Fluttertoast.showToast(
          msg: "Erro ao editar Produto, verifique a conexão com o banco de dados!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
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
          const SizedBox(height: 10),
          TextFormField(
            controller: _precoController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Preço',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o preço';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descriptionController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Descrição',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira a descrição';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _amountController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Quantidade',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira a quantidade';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _dataDeFabricacaoController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              suffixIcon: const Icon(Icons.calendar_today, color: AppStyles.primaryColor,),
              hintText: 'Data de fabricação',
              hintStyle: AppStyles.formTextStyle,
            ),
            onTap: () async {
              DateTime? pickeddate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                initialDatePickerMode: DatePickerMode.year,
              );

              if (pickeddate != null) {
                setState(
                  () {
                    _dateFabricacao = pickeddate;
                    _dataDeFabricacaoController.text =
                        DateFormat('yyyy-MM-dd').format(pickeddate);
                  },
                );
              }
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _dataDeValidadeController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              suffixIcon: const Icon(Icons.calendar_today, color: AppStyles.primaryColor,),
              hintText: 'Data de validade',
              hintStyle: AppStyles.formTextStyle,
            ),
            onTap: () async {
              DateTime? pickeddate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                initialDatePickerMode: DatePickerMode.year,
              );

              if (pickeddate != null) {
                setState(
                  () {
                    _dateValidade = pickeddate;
                    _dataDeValidadeController.text =
                        DateFormat('yyyy-MM-dd').format(pickeddate);
                  },
                );
              }
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitUpdateForm,
            style: AppStyles.elevatedButtonStyle,
            child: const Text('Atualizar Produto'),
          ),
        ],
      ),
    );
  }
}

class Product {
  final int id;
  final String nome;
  final double preco;
  final String descricao;
  final int quantidade;
  final DateTime dataDeFabricacao;
  final DateTime dataDeValidade;

  Product({
    required this.id,
    required this.nome,
    required this.preco,
    required this.descricao,
    required this.quantidade,
    required this.dataDeFabricacao,
    required this.dataDeValidade,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      nome: json['nome'],
      preco: json['preco'],
      descricao: json['descricao'],
      quantidade: json['quantidade'] ?? 0,
      dataDeFabricacao: DateTime.parse(json['dataDeFabricacao']),
      dataDeValidade: DateTime.parse(json['dataDeValidade']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'preco': preco,
      'descricao': descricao,
      'quantidade': quantidade,
      'dataDeFabricacao': dataDeFabricacao.toIso8601String(),
      'dataDeValidade': dataDeValidade.toIso8601String(),
    };
  }
}
