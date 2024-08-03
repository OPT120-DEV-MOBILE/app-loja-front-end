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
  late List<User> _users;
  String? jwt;
  String? role;

  @override
  void initState() {
    super.initState();
    _getStoredValues();
    _isMounted = true;
    _users = [];
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // const SizedBox(height: 20),
              _buildList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: _fetchUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
          return const Center(
            child: Text(
                'Erro: Não foi possível carregar os usuários. Por favor, tente novamente mais tarde.'),
          );
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
                      Text(
                          'Quantidade de Compras: ${user.quantidadeDeCompras}'),
                      // Text('Role: ${user.roles}'),
                      ButtonBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openEditUserForm(context, user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _confirmDelete(context, user.id),
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

  void _openEditUserForm(BuildContext context, User user) {}

  void _confirmDelete(BuildContext context, int userId) {}

  Future<List<User>> _fetchUsers() async {
    try {
      final dio = Dio();
      final options = Options(headers: {'jwt': '$jwt'});
      final response = await dio.get(
        'http://localhost:3000/exemplo',
        options: options,
      );

      if (response.statusCode == 200 && _isMounted) {
        final List<dynamic> responseData = response.data;
        return responseData
            .map((json) => User(
                  id: json['id'],
                  idEmpresa: json['idEmpresa'],
                  nome: json['nome'] ?? '',
                  email: json['email'] ?? '',
                  senha: json['senha'] ?? '',
                  roles: json['roles'] ?? 0,
                  cpf: json['cpf'] ?? '',
                  quantidadeDeCompras: json['quantidadeDeCompras'] ?? 0,
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
}

class User {
  final int id;
  final int idEmpresa;
  String nome;
  String email;
  String senha;
  final int roles;
  final String cpf;
  final int quantidadeDeCompras;

  User({
    required this.id,
    required this.idEmpresa,
    required this.nome,
    required this.email,
    required this.senha,
    required this.roles,
    required this.cpf,
    required this.quantidadeDeCompras,
  });
}
