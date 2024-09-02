// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:app_lojas/menu/menu.dart';
import 'package:app_lojas/styles/styles_app.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  late bool _isMounted;
  late Future<List<User>> _userFuture;
  String? jwt;
  String? role;
  String? idUsuario;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _getStoredValues().then((_) {
      setState(() {
        _userFuture = _fetchUsers();
      });
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
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuário', style: AppStyles.largeTextStyle),
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
                        hintText: 'Pesquisar por nome',
                        hintStyle: AppStyles.formTextStyle,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      style: AppStyles.elevatedButtonStyle,
                      onPressed: () {
                        _openCreateUserForm(context);
                      },
                      child: Text('Criar Usuário', style: AppStyles.smallTextStyle,),
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _userFuture = _fetchUsers(query: query);
      });
    });
  }

  Widget _buildList(BuildContext context) {
  return FutureBuilder<List<User>>(
    future: _userFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Erro: ${snapshot.error}'));
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(child: Text('Nenhum usuário encontrado'));
      } else {
        final users = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
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
                    Text('Nome: ${user.nome}', style: AppStyles.listItemTitleStyle),
                    Text('Email: ${user.email}', style: AppStyles.listItemSubtitleStyle),
                    Text('CPF: ${user.cpf}', style: AppStyles.listItemSubtitleStyle),
                    Text('Role: ${user.role.nome}', style: AppStyles.listItemSubtitleStyle),
                    if (user.role.nome != 'ADMIN') ...[
                      Text('Quantidade de Compras: ${user.quantidadeDeCompras}', style: AppStyles.listItemSubtitleStyle),
                    ],
                    ButtonBar(
                      alignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openEditUserForm(context, user),
                          color: AppStyles.primaryColor, 
                        ),
                        // IconButton(
                        //   icon: const Icon(Icons.delete),
                        //   onPressed: () => _deleteUser(user.id),
                        //   style: AppStyles.iconButtonTheme.style,
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


  Future<List<User>> _fetchUsers({String? query}) async {
    try {
      final dio = Dio();
      final options = Options(headers: {'jwt-access': jwt});
      final response = await dio.get(
        'http://localhost:3300/users/',
        queryParameters: query != null && query.isNotEmpty
            ? {'usuario': query}
            : null,
        options: options,
      );

      if (response.statusCode == 201 && _isMounted) {
        final List<dynamic> responseData = response.data['usuarios'];
        return responseData.map((json) => User.fromJson(json)).toList();
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

  void _openCreateUserForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Criar Usuário', style: AppStyles.formTitleStyle),
          content: IntrinsicHeight(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 600,
                child: UserForm(
                  onFormSubmitted: () {
                    setState(() {
                      _userFuture = _fetchUsers();
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

  void _openEditUserForm(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Usuário', style: AppStyles.formTitleStyle),
          content: IntrinsicHeight(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 600,
                child: EditUserForm(
                  user: user,
                  jwt: jwt!,
                  onFormSubmitted: () {
                    setState(() {
                      _userFuture = _fetchUsers();
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
  //         _userFuture = _fetchUsers();
  //       });
  //     } else {
  //       // Handle error
  //     }
  //   } catch (error) {
  //     // Handle error
  //   }
  // }
}

class UserForm extends StatefulWidget {
  final Function onFormSubmitted;
  final String jwt;

  const UserForm({super.key, required this.onFormSubmitted, required this.jwt});

  @override
  _UserFormState createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cpfController = MaskedTextController(mask: '000.000.000-00');

  List<Empresa> _empresas = [];
  List<Role> _roles = [];
  Empresa? _selectedEmpresa;
  Role? _selectedRole;
  bool _isCliente = false;

  @override
  void initState() {
    super.initState();
    _fetchEmpresasAndRoles();
  }

  Future<void> _fetchEmpresasAndRoles() async {
    try {
      final dio = Dio();
      final options = Options(headers: {'jwt-access': widget.jwt});
      final empresaResponse = await dio.get('http://localhost:3300/empresas/', options: options,);
      final roleResponse = await dio.get('http://localhost:3300/roles/', options: options,);

      if (empresaResponse.statusCode == 201) {
        final empresaData = empresaResponse.data;
        setState(() {
          _empresas = (empresaData['empresas'] as List)
              .map((json) => Empresa.fromJson(json))
              .toList();
        });
      }

      if (roleResponse.statusCode == 201) {
        final roleData = roleResponse.data;
        setState(() {
          _roles = (roleData['roles'] as List)
              .map((json) => Role.fromJson(json))
              .toList();
        });
      }
    } catch (error) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<Role>(
            value: _selectedRole,
            hint: Text('Selecione o Cargo', style: AppStyles.dropdownStyle.hintStyle),
            items: _roles.map((role) {
              return DropdownMenuItem<Role>(
                value: role,
                child: Text(role.nome, style: AppStyles.dropdownStyle.itemStyle),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRole = value;
                _isCliente = value?.nome == "CLIENTE";
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Por favor, selecione o cargo';
              }
              return null;
            },
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Selecione o Cargo',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Empresa>(
            value: _selectedEmpresa,
            hint: Text('Selecione a Empresa (opcional)', style: AppStyles.dropdownStyle.hintStyle),
            items: _empresas.map((empresa) {
              return DropdownMenuItem<Empresa>(
                value: empresa,
                child: Text(empresa.nome, style: AppStyles.dropdownStyle.itemStyle),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedEmpresa = value;
              });
            },
            decoration: AppStyles.textFieldDecoration
          ),
          const SizedBox(height: 10),
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
            controller: _emailController,
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
          const SizedBox(height: 10),
          if (!_isCliente)
            TextFormField(
              controller: _passwordController,
              decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Senha',
              hintStyle: AppStyles.formTextStyle,
            ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira a senha';
                }
                return null;
              },
            ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _cpfController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'CPF',
              hintStyle: AppStyles.formTextStyle,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o CPF';
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
            child: const Text('Criar Usuário'),
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
          'http://localhost:3300/users/register/',
          data: {
            'nome': _nameController.text,
            'email': _emailController.text,
            'senha': _isCliente ? '123456789' : _passwordController.text,
            'cpf': _cpfController.text,
            'idEmpresa': _selectedEmpresa?.id,
            'roles': _selectedRole?.id,
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
    _emailController.dispose();
    _passwordController.dispose();
    _cpfController.dispose();
    super.dispose();
  }
}

class EditUserForm extends StatefulWidget {
  final User user;
  final String jwt;
  final Function onFormSubmitted;

  const EditUserForm({
    super.key,
    required this.user,
    required this.jwt,
    required this.onFormSubmitted,
  });

  @override
  _EditUserFormState createState() => _EditUserFormState();
}

class _EditUserFormState extends State<EditUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cpfController = MaskedTextController(mask: '000.000.000-00');

  final List<Empresa> _empresas = [];
  final List<Role> _roles = [];
  Empresa? _selectedEmpresa;
  Role? _selectedRole;
  bool _isCliente = false;
  bool _alterarSenha = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.nome;
    _emailController.text = widget.user.email;
    _cpfController.text = widget.user.cpf;
    _isCliente = widget.user.role.nome == "CLIENTE";
    _fetchEmpresasAndRoles().then((_) {
      setState(() {
        _selectedEmpresa = widget.user.empresa;
        _selectedRole = widget.user.role;
      });
    });
  }

  Future<void> _fetchEmpresasAndRoles() async {
    try {
      final dio = Dio();
      final options = Options(headers: {'jwt-access': widget.jwt});
      final empresaResponse = await dio.get('http://localhost:3300/empresas/', options: options,);
      final roleResponse = await dio.get('http://localhost:3300/roles/', options: options,);

      if (empresaResponse.statusCode == 201) {
        final empresaData = empresaResponse.data;
        setState(() {
          _empresas.addAll(
            (empresaData['empresas'] as List)
                .map((json) => Empresa.fromJson(json))
                .toList(),
          );
        });
      }

      if (roleResponse.statusCode == 201) {
        final roleData = roleResponse.data;
        setState(() {
          _roles.addAll(
            (roleData['roles'] as List)
                .map((json) => Role.fromJson(json))
                .toList(),
          );
        });
      }
    } catch (error) {
      // Handle error
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final dio = Dio();
        final response = await dio.patch(
          'http://localhost:3300/users/update/',
          data: {
            'id': widget.user.id,
            'nome': _nameController.text,
            'email': _emailController.text,
            'senha': _passwordController.text,
            'cpf': _cpfController.text,
            'idEmpresa': _selectedEmpresa?.id,
            'roles': _selectedRole?.id,
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
          DropdownButtonFormField<Role>(
            value: _selectedRole,
            hint: Text('Selecione o Cargo', style: AppStyles.dropdownStyle.hintStyle),
            items: _roles.map((role) {
              return DropdownMenuItem<Role>(
                value: role,
                child: Text(role.nome, style: AppStyles.dropdownStyle.itemStyle),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRole = value;
                _isCliente = value?.nome == "CLIENTE";
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Por favor, selecione um cargo';
              }
              return null;
            },
            decoration: AppStyles.textFieldDecoration.copyWith(
              hintText: 'Selecione o Cargo',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Empresa>(
            value: _selectedEmpresa,
            hint: Text('Selecione a Empresa (opcional)', style: AppStyles.dropdownStyle.hintStyle),
            items: _empresas.map((empresa) {
              return DropdownMenuItem<Empresa>(
                value: empresa,
                child: Text(empresa.nome, style: AppStyles.dropdownStyle.itemStyle),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedEmpresa = value;
              });
            },
          decoration: AppStyles.textFieldDecoration
          ),
          const SizedBox(height: 10),
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
            controller: _emailController,
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
          const SizedBox(height: 10),
          if (!_isCliente)
            SwitchListTile(
              title: const Text('Quero alterar a senha'),
              value: _alterarSenha,
              onChanged: (value) {
                setState(() {
                  _alterarSenha = value;
                });
              },
              activeColor: AppStyles.primaryColor,
              inactiveThumbColor: AppStyles.secondaryColor,
              inactiveTrackColor: AppStyles.secondaryColor.withOpacity(0.3),
            ),
          if (!_isCliente && _alterarSenha)
            TextFormField(
              controller: _passwordController,
              decoration: AppStyles.textFieldDecoration.copyWith(
                hintText: 'Senha',
                hintStyle: AppStyles.formTextStyle,
              ),
              obscureText: true,
              validator: (value) {
                if (_alterarSenha && (value == null || value.isEmpty)) {
                  return 'Por favor, insira a senha';
                }
                return null;
              },
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitForm,
            style: AppStyles.elevatedButtonStyle,
            child: const Text('Atualizar Usuário'),
          ),
        ],
      ),
    );
  }
}

class Role {
  final int id;
  final String nome;

  Role({
    required this.id,
    required this.nome,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      nome: json['nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Role && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Empresa {
  final int id;
  final String nome;

  Empresa({
    required this.id,
    required this.nome,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'],
      nome: json['nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Empresa && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class User {
  final int id;
  final String nome;
  final String email;
  final String cpf;
  final Empresa? empresa;
  final Role role;
  final int? quantidadeDeCompras;

  User({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpf,
    this.empresa,
    required this.role,
    this.quantidadeDeCompras,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      cpf: json['cpf'],
      empresa:
          json['empresa'] != null ? Empresa.fromJson(json['empresa']) : null,
      role: Role.fromJson(json['role']),
      quantidadeDeCompras: json['quantidadeDeCompras'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'empresa': empresa,
      'role': role,
      'quantidadeDeCompras': quantidadeDeCompras,
    };
  }
}
