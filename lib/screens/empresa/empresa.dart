// ignore_for_file: library_private_types_in_public_api

import 'package:app_lojas/menu/menu.dart';
import 'package:app_lojas/styles/styles_app.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'dart:async';

class EmpresaScreen extends StatefulWidget {
  const EmpresaScreen({super.key});

  @override
  _EmpresaScreenState createState() => _EmpresaScreenState();
}

class _EmpresaScreenState extends State<EmpresaScreen> {
  late bool _isMounted;
  late Future<List<Empresa>> _empresaFuture;

  String? jwt;
  String? role;
  String? idUsuario;
  final TextEditingController _searchController = TextEditingController(); // Controlador para o campo de pesquisa
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _empresaFuture = Future.value([]);
    _getStoredValues().then((_) {
      setState(() {
        _empresaFuture = _fetchEmpresas();
      });
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _isMounted = false;
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getStoredValues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      jwt = prefs.getString('token');
      role = prefs.getString('role');
      idUsuario = prefs.getString('idUsuario');
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _empresaFuture = _fetchEmpresas(query: _searchController.text);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Empresas', style: AppStyles.largeTextStyle),
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
                        hintText: 'Pesquisar por empresa',
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
                        _openCreateEmpresaForm(context);
                      },
                      child: Text('Criar Empresa', style: AppStyles.smallTextStyle,),
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
    return FutureBuilder<List<Empresa>>(
      future: _empresaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhuma empresa encontrada'));
        } else {
          final empresas = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: empresas.length,
            itemBuilder: (context, index) {
              final empresa = empresas[index];
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
                      Text('Nome: ${empresa.nome}', style: AppStyles.listItemTitleStyle),
                      Text('Tipo do Documento: ${empresa.tipoDocumento}', style: AppStyles.listItemSubtitleStyle),
                      Text('Nº Documento: ${empresa.numeroDocumento}', style: AppStyles.listItemSubtitleStyle),
                      Text('CEP: ${empresa.cep}', style: AppStyles.listItemSubtitleStyle),
                      Text('Endereço: ${empresa.endereco}', style: AppStyles.listItemSubtitleStyle),
                      Text('Cidade: ${empresa.cidade}', style: AppStyles.listItemSubtitleStyle),
                      Text('Estado: ${empresa.estado}', style: AppStyles.listItemSubtitleStyle),
                      ButtonBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openEditEmpresaForm(context, empresa),
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

  Future<List<Empresa>> _fetchEmpresas({String? query}) async {
    try {
      final dio = Dio();
      final options = Options(headers: {'jwt-access': jwt});
      final response = await dio.get(
        'http://localhost:3300/empresas/',
        queryParameters: query != null && query.isNotEmpty ? {'empresa': query} : null,
        options: options,
      );

      if (response.statusCode == 201 && _isMounted) {
        final List<dynamic> responseData = response.data['empresas'];
        return responseData.map((json) => Empresa.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load empresas');
      }
    } catch (error) {
      if (_isMounted) {
        setState(() {
          // Handle the error state in the FutureBuilder
        });
      }
      throw Exception('Failed to load empresas: $error');
    }
  }

  void _openCreateEmpresaForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Criar Empresa', style: AppStyles.formTitleStyle),
          content: IntrinsicHeight(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 600,
                child: EmpresaForm(
                  onFormSubmitted: () {
                    setState(() {
                      _empresaFuture = _fetchEmpresas();
                    });
                    Navigator.of(context).pop();
                  },
                  jwt: jwt!,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openEditEmpresaForm(BuildContext context, Empresa empresa) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Empresa', style: AppStyles.formTitleStyle),
          content: IntrinsicHeight(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 600,
                child: EditEmpresaForm(
                  empresa: empresa,
                  jwt: jwt!,
                  onFormSubmitted: () {
                    setState(() {
                      _empresaFuture = _fetchEmpresas();
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
  //         _userFuture = _fetchEmpresas();
  //       });
  //     } else {
  //       // Handle error
  //     }
  //   } catch (error) {
  //     // Handle error
  //   }
  // }
}

class EmpresaForm extends StatefulWidget {
  final Function onFormSubmitted;
  final String jwt;

  const EmpresaForm({super.key, required this.onFormSubmitted, required this.jwt});

  @override
  _EmpresaFormState createState() => _EmpresaFormState();
}

class _EmpresaFormState extends State<EmpresaForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tipoDocumentoController = TextEditingController(text: 'CNPJ');
  late MaskedTextController _numeroDocumentoController;
  final _cepController = MaskedTextController(mask: '00000-000');
  final _enderecoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _numeroDocumentoController = MaskedTextController(mask: _tipoDocumentoController.text == 'CNPJ' ? '00.000.000/0000-00' : '000.000.000-00');

    _tipoDocumentoController.addListener(() {
      setState(() {
        if (_tipoDocumentoController.text == 'CNPJ') {
          _numeroDocumentoController.updateMask('00.000.000/0000-00');
        } else if (_tipoDocumentoController.text == 'CPF') {
          _numeroDocumentoController.updateMask('000.000.000-00');
        }
      });
    });
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
          DropdownButtonFormField<String>(
            value: _tipoDocumentoController.text,
            hint: Text('Tipo do Documento', style: AppStyles.dropdownStyle.hintStyle),
            decoration: AppStyles.textFieldDecoration,
            items: [
              DropdownMenuItem(value: 'CNPJ', child: Text('CNPJ', style: AppStyles.dropdownStyle.itemStyle)),
              DropdownMenuItem(value: 'CPF', child: Text('CPF', style: AppStyles.dropdownStyle.itemStyle)),
            ],
            onChanged: (value) {
              if (value != null) {
                _tipoDocumentoController.text = value;
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o tipo do documento';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _numeroDocumentoController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Nº do documento',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o número do documento';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _cepController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'CEP',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o CEP da empresa';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _enderecoController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Endereço',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o endereço da empresa';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _cidadeController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Cidade',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira a cidade da empresa';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _estadoController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Estado',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o estado da empresa';
              }
              return null;
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
            child: const Text('Criar Empresa'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final options = Options(headers: {'jwt-access': widget.jwt});
        final response = await Dio().post(
          'http://localhost:3300/empresas/register/',
          data: {
            'nome': _nameController.text,
            'tipoDocumento': _tipoDocumentoController.text,
            'numeroDocumento': _numeroDocumentoController.text,
            'cep': _cepController.text,
            'endereco': _enderecoController.text,
            'cidade': _cidadeController.text,
            'estado': _estadoController.text,
          },
          options: options,
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
    _tipoDocumentoController.dispose();
    _numeroDocumentoController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }
}

class EditEmpresaForm extends StatefulWidget {
  final Empresa empresa;
  final String jwt;
  final Function onFormSubmitted;

  const EditEmpresaForm({
    super.key,
    required this.empresa,
    required this.jwt,
    required this.onFormSubmitted,
  });

  @override
  _EditEmpresaFormState createState() => _EditEmpresaFormState();
}

class _EditEmpresaFormState extends State<EditEmpresaForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tipoDocumentoController = TextEditingController();
  late MaskedTextController _numeroDocumentoController;
  final _cepController = MaskedTextController(mask: '00000-000');
  final _enderecoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.empresa.nome;
    _tipoDocumentoController.text = widget.empresa.tipoDocumento;
    _numeroDocumentoController = MaskedTextController(
      mask: widget.empresa.tipoDocumento == 'CNPJ' ? '00.000.000/0000-00' : '000.000.000-00',
      text: widget.empresa.numeroDocumento,
    );
    _cepController.text = widget.empresa.cep;
    _enderecoController.text = widget.empresa.endereco;
    _cidadeController.text = widget.empresa.cidade;
    _estadoController.text = widget.empresa.estado;

    _tipoDocumentoController.addListener(() {
      setState(() {
        if (_tipoDocumentoController.text == 'CNPJ') {
          _numeroDocumentoController.updateMask('00.000.000/0000-00');
        } else if (_tipoDocumentoController.text == 'CPF') {
          _numeroDocumentoController.updateMask('000.000.000-00');
        }
      });
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final dio = Dio();
        final response = await dio.patch(
          'http://localhost:3300/empresas/update/',
          data: {
            'id': widget.empresa.id,
            'nome': _nameController.text,
            'tipoDocumento': _tipoDocumentoController.text,
            'numeroDocumento': _numeroDocumentoController.text,
            'cep': _cepController.text,
            'endereco': _enderecoController.text,
            'cidade': _cidadeController.text,
            'estado': _estadoController.text,
          },
          options: Options(headers: {'jwt-access': widget.jwt}),
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
          DropdownButtonFormField<String>(
            value: _tipoDocumentoController.text,
            decoration: AppStyles.textFieldDecoration,
            items: [
              DropdownMenuItem(value: 'CNPJ', child: Text('CNPJ', style: AppStyles.dropdownStyle.itemStyle)),
              DropdownMenuItem(value: 'CPF', child: Text('CPF', style: AppStyles.dropdownStyle.itemStyle)),
            ],
            onChanged: (value) {
              if (value != null) {
                _tipoDocumentoController.text = value;
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o tipo do documento';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _numeroDocumentoController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Nº do documento',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o número do documento';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _cepController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'CEP',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o CEP da empresa';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _enderecoController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Endereço',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o endereço da empresa';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _cidadeController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Cidade',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira a cidade da empresa';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _estadoController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Estado',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o estado da empresa';
              }
              return null;
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
            child: const Text('Editar Empresa'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tipoDocumentoController.dispose();
    _numeroDocumentoController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }
}

class Empresa {
  final int id;
  final String nome;
  final String tipoDocumento;
  final String numeroDocumento;
  final String cep;
  final String endereco;
  final String cidade;
  final String estado;

  Empresa({
    required this.id,
    required this.nome,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.cep,
    required this.endereco,
    required this.cidade,
    required this.estado,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'],
      nome: json['nome'],
      tipoDocumento: json['tipoDocumento'],
      numeroDocumento: json['numeroDocumento'],
      cep: json['cep'],
      endereco: json['endereco'] ?? '',
      cidade: json['cidade'] ?? '',
      estado: json['estado'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'tipoDocumento': tipoDocumento,
      'numeroDocumento': numeroDocumento,
      'cep': cep,
      'endereco': endereco,
      'cidade': cidade,
      'estado': estado,
    };
  }
}
