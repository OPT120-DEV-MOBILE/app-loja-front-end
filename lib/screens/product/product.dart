import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _getStoredValues().then((_) {
      setState(() {
        _productFuture = _fetchProducts();
      });
    });
  }

  Future<void> _getStoredValues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      jwt = prefs.getString('token');
      role = prefs.getString('role');
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
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
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () {
                        _openCreateProductForm(context);
                      },
                      child: const Text('Criar Produto',
                          style: TextStyle(fontSize: 10)),
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
          print(snapshot.hasError);
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
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nome: ${product.nome}',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text('Preco: ${product.preco}'),
                      Text('Descrição: ${product.descricao}'),
                      Text('Quantidade: ${product.quantidade}'),
                      Text(
                        'Data de fabricação: ${DateFormat('dd-MM-yyyy').format(product.dataDeFabricacao)}',
                      ),
                      Text(
                        'Data de validade: ${DateFormat('dd-MM-yyyy').format(product.dataDeValidade)}',
                      ),
                      ButtonBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _openEditProductForm(context, product),
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

  Future<List<Product>> _fetchProducts() async {
    try {
      final dio = Dio();
      final options = Options(headers: {'JWT': jwt});
      final response = await dio.get(
        'http://localhost:3000/exemplo',
        options: options,
      );
      // print(response);
      if (response.statusCode == 201 && _isMounted) {
        final List<dynamic> responseData = response.data['produtos'];
        return responseData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (error) {
      if (_isMounted) {
        setState(() {
          // Handle the error state in the FutureBuilder
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
          title: const Text('Criar Produto'),
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
          title: const Text('Editar Produto'),
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
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o nome';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _precoController,
            decoration: const InputDecoration(labelText: 'Preço'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o preço';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Descrição'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira a descrição';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Quantidade'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o quantidade';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _dataDeFabricacaoController,
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today),
              hintText: 'Data de fabricação',
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
          TextFormField(
            controller: _dataDeValidadeController,
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today),
              hintText: 'Data de validade',
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
            child: const Text('Criar Produto'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await Dio().post(
          'http://localhost:3300/users/register/',
          data: {
            'nome': _nameController.text,
            'preco': _precoController.text,
            'descricao': _descriptionController.text,
            'quantidade': _amountController.text,
            'dataDeFabricacao': _dataDeFabricacaoController.text,
            'dataDeValidade': _dataDeValidadeController.text
          },
        );

        if (response.statusCode == 201) {
          widget.onFormSubmitted();
        } else {
          // Handle error
        }
      } catch (error) {
        // Handle error
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

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product.nome;
    _precoController.text = widget.product.preco.toString();
    _amountController.text = widget.product.quantidade.toString();
    _dataDeFabricacaoController.text =
        widget.product.dataDeFabricacao.toString();
    _dataDeValidadeController.text = widget.product.dataDeValidade.toString();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final dio = Dio();
        final response = await dio.patch(
          'http://localhost:3300/users/update/',
          data: {
            'id': widget.product.id,
            'nome': _nameController.text,
            'preco': _precoController.text,
            'descricao': _descriptionController.text,
            'quantidade': _amountController.text,
            'dataDeFabricacao': _dataDeFabricacaoController,
            'dataDeValidade': _dataDeValidadeController,
          },
          options: Options(headers: {'JWT': widget.jwt}),
        );

        if (response.statusCode == 201) {
          widget.onFormSubmitted();
        } else {
          // Handle error
        }
      } catch (error) {
        // Handle error
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
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o nome';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _precoController,
            decoration: const InputDecoration(labelText: 'Preço'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o preço';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Descrição'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira a descrição';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Quantidade'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o quantidade';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _dataDeFabricacaoController,
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today),
              hintText: 'Data de fabricação',
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
                    // _dateFabricacao = pickeddate;
                    _dataDeFabricacaoController.text =
                        DateFormat('dd-MM-yyyy').format(pickeddate);
                  },
                );
              }
            },
          ),
          TextFormField(
            controller: _dataDeValidadeController,
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today),
              hintText: 'Data de validade',
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
                    // _dateValidade = pickeddate;
                    _dataDeValidadeController.text =
                        DateFormat('dd-MM-yyyy').format(pickeddate);
                  },
                );
              }
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitForm,
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
