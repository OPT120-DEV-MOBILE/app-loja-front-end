import 'package:app_lojas/styles/styles_app.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onFormSubmitted;

  const LoginScreen({super.key, required this.onFormSubmitted});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await Dio().post(
          'http://localhost:3300/users/login/',
          data: {
            'email': _emailController.text.trim(),
            'senha': _senhaController.text.trim(),
          },
        );
        
        if (response.statusCode == 201) {
          final responseData = response.data;
          final token = responseData['JWT'];
          final role = responseData['roles'].toString();
          final idUsuario = responseData['id'].toString();

          // Salvando o token e a role localmente
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('role', role);
          await prefs.setString('idUsuario', idUsuario);

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
    return Container(
      color: const Color.fromARGB(255, 255, 135, 7), // Cor de fundo da tela
      child: Center(
        child: SizedBox(
          width: 400.0,
          height: 400.0,
          child: Card(
            shape: AppStyles.cardTheme.shape,
            margin: AppStyles.cardTheme.margin,
            elevation: AppStyles.cardTheme.elevation,
            color: AppStyles.cardTheme.color,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      'logo_2.png',
                      width: 200,
                      height: 150,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: AppStyles.textFieldDecoration.copyWith(
                        hintText: 'Email',
                        hintStyle: AppStyles.formTextStyle,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20.0),
                    TextFormField(
                      controller: _senhaController,
                      decoration: AppStyles.textFieldDecoration.copyWith(
                        hintText: 'Senha',
                        hintStyle: AppStyles.formTextStyle,
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua senha';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20.0),
                    ElevatedButton(
                      style: AppStyles.elevatedButtonStyle,
                      onPressed: _login,
                      child: Text('Login', style: AppStyles.smallTextStyle),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}