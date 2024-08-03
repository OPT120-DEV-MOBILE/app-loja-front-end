// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
        title: const Text('Usuário'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
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
                      _openCreateUserForm(context);
                    },
                    child: const Text('Criar Usuário', style: TextStyle(fontSize: 12)),
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
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nome: ${user.nome}',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text('Email: ${user.email}'),
                      Text('CPF: ${user.cpf}'),
                      // Text('Quantidade de Compras: ${user.quantidadeDeCompras}'),
                      ButtonBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openEditUserForm(context, user, jwt!, role!),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteUser(user.id),
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

  Future<List<User>> _fetchUsers() async {
    try {
      final dio = Dio();
      final options = Options(headers: {'JWT': jwt});
      final response = await dio.get(
        'http://localhost:3300/users/',
        options: options,
      );

      if (response.statusCode == 201 && _isMounted) {
        print(response.data.usuarios);
        final List<dynamic> responseData = response.data.usuarios;
        return responseData
            .map((json) => User(
                  id: json['id'],
                  empresa: json['idEmpresa'],
                  nome: json['nome'] ?? '',
                  email: json['email'] ?? '',
                  role: json['roles'] ?? 0,
                  cpf: json['cpf'] ?? '',
                  quantidadeDeCompras: json['quantidadeDeCompras'] ?? 0
                ))
            .toList();
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
          title: const Text('Criar Usuário'),
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openEditUserForm(BuildContext context, User user, String jwt, String role) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Usuário'),
          content: IntrinsicHeight(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 600,
                child: EditUserForm(
                  user: user,
                  jwt: jwt,
                  role: role,
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

  void _deleteUser(int userId) async {
    try {
      final dio = Dio();
      final options = Options(headers: {'jwt': jwt});
      final response = await dio.put(
        'http://localhost:3000/users/$userId?roleUser=$role',
        data: {'desabilitado': true},
        options: options,
      );

      if (response.statusCode == 200) {
        setState(() {
          _userFuture = _fetchUsers();
        });
      } else {
        // Handle error
      }
    } catch (error) {
      // Handle error
    }
  }
}

class UserForm extends StatefulWidget {
  final Function onFormSubmitted;

  const UserForm({super.key, required this.onFormSubmitted});

  @override
  _UserFormState createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cpfController = TextEditingController();
  final _idEmpresaController = TextEditingController();
  final _rolesController = TextEditingController();
  final _quantidadeDeComprasController = TextEditingController();

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
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o email';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Senha'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira a senha';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _cpfController,
            decoration: const InputDecoration(labelText: 'CPF'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o CPF';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _idEmpresaController,
            decoration: const InputDecoration(labelText: 'ID Empresa'),
          ),
          TextFormField(
            controller: _rolesController,
            decoration: const InputDecoration(labelText: 'Roles'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira os Roles';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _quantidadeDeComprasController,
            decoration: const InputDecoration(labelText: 'Quantidade de Compras'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _submitForm();
              }
            },
            child: const Text('Criar Usuário'),
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
            'email': _emailController.text,
            'senha': _passwordController.text,
            'cpf': _cpfController.text,
            'idEmpresa': _idEmpresaController.text.isEmpty 
              ? null : int.parse(_idEmpresaController.text),
            'roles': int.parse(_rolesController.text),
            'quantidadeDeCompras': _quantidadeDeComprasController.text.isEmpty
              ? null
              : int.parse(_quantidadeDeComprasController.text),
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
    _emailController.dispose();
    _passwordController.dispose();
    _cpfController.dispose();
    _idEmpresaController.dispose();
    _rolesController.dispose();
    _quantidadeDeComprasController.dispose();
    super.dispose();
  }
}

class EditUserForm extends StatefulWidget {
  final User user;
  final String jwt;
  final String role;
  final Function onFormSubmitted;

  const EditUserForm({
    super.key,
    required this.user,
    required this.jwt,
    required this.role,
    required this.onFormSubmitted,
  });

  @override
  _EditUserFormState createState() => _EditUserFormState();
}

class _EditUserFormState extends State<EditUserForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _cpfController;
  late TextEditingController _idEmpresaController;
  late TextEditingController _rolesController;
  late TextEditingController _quantidadeDeComprasController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.nome);
    _emailController = TextEditingController(text: widget.user.email);
    _cpfController = TextEditingController(text: widget.user.cpf);
    _idEmpresaController = TextEditingController(text: widget.user.empresa);
    _rolesController = TextEditingController(text: widget.user.role);
    _quantidadeDeComprasController = TextEditingController(
      text: widget.user.quantidadeDeCompras.toString(),
    );
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
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o email';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _cpfController,
            decoration: const InputDecoration(labelText: 'CPF'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o CPF';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _idEmpresaController,
            decoration: const InputDecoration(labelText: 'ID Empresa'),
          ),
          TextFormField(
            controller: _rolesController,
            decoration: const InputDecoration(labelText: 'Roles'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira os Roles';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _quantidadeDeComprasController,
            decoration: const InputDecoration(labelText: 'Quantidade de Compras'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _submitForm();
              }
            },
            child: const Text('Atualizar Usuário'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    final dio = Dio();

    final updatedUser = User(
      id: widget.user.id,
      nome: _nameController.text,
      email: _emailController.text,
      cpf: _cpfController.text,
      empresa: _idEmpresaController.text,
      role: _rolesController.text,
      quantidadeDeCompras: int.tryParse(_quantidadeDeComprasController.text) ?? 0,
    );

    try {
      final response = await dio.put(
        'http://localhost:3000/users/${widget.user.id}?roleUser=${widget.role}',
        data: updatedUser.toJson(),
        options: Options(headers: {'jwt': widget.jwt}),
      );

      if (response.statusCode == 200) {
        widget.onFormSubmitted();
      } else {
        // Handle error
      }
    } catch (error) {
      // Handle error
    }
  }
}

class User {
  final int id;
  final String nome;
  final String email;
  final String cpf;
  final String empresa;
  final String role;
  final int quantidadeDeCompras;

  User({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.empresa,
    required this.role,
    required this.quantidadeDeCompras,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      cpf: json['cpf'],
      empresa: json['idEmpresa'],
      role: json['role'],
      quantidadeDeCompras: json['quantidadeDeCompras'],
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
