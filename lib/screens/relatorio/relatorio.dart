import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lojas/menu/menu.dart';
import 'package:app_lojas/styles/styles_app.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'dart:async';

import '../user/user.dart';

class RelatorioScreen extends StatefulWidget {
  const RelatorioScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RelatorioScreenState createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  late Future<Map<String, Map<String, dynamic>>> _vendaFuture =
      Future.value({});

  String? jwt;
  late bool _isMounted;

  String? role;
  String? idUsuario;

  String _selectedReportType = 'Funcionários';
  String? _dataInicialSelecionada;
  String? _dataFinalSelecionada;


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

  Future<void> _refreshVendas({String? dataInicial, String? dataFinal}) async {
    if (_isMounted) {
      setState(() {
        _dataInicialSelecionada = dataInicial;
        _dataFinalSelecionada = dataFinal;
      });

      try {
        final Map<String, String> cpfToNameMap = await _fetchUserCpfs();
        final Map<String, Map<String, dynamic>> vendasPorNome = {};

        for (String cpf in cpfToNameMap.keys) {
          final Map<String, dynamic> relatorio = await _fetchRelatorio(
            cpf: cpf,
            dataInicial: dataInicial,
            dataFinal: dataFinal,
          );

          vendasPorNome[cpfToNameMap[cpf] ?? 'Desconhecido'] = {
            'total': relatorio['valorTotalVendas'],
            'quantidade': relatorio['totalVendas'],
          };
        }

        setState(() {
          _vendaFuture = Future.value(vendasPorNome);
        });
      } catch (e) {
        // Handle error
        setState(() {
          _vendaFuture = Future.error('Failed to load vendas');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Relatórios', style: AppStyles.largeTextStyle),
        backgroundColor: AppStyles.primaryColor,
        actions: [
          ElevatedButton(
            style: AppStyles.elevatedButtonStyle,
            onPressed: () {
              _openSelectDates(context);
            },
            child: Text(
              'Fitrar',
              style: AppStyles.smallTextStyle,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: "Filtrar relatório",
            onSelected: (String value) {
              setState(() {
                _selectedReportType = value;
                _refreshVendas();
              });
            },
            itemBuilder: (BuildContext context) {
              return ['Funcionários', 'Clientes'].map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      drawer: const AppMenu(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_dataInicialSelecionada != null && _dataFinalSelecionada != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Período selecionado: $_dataInicialSelecionada a $_dataFinalSelecionada',
              style: AppStyles.listItemTitleStyle,
            ),
          ),
        FutureBuilder<Map<String, Map<String, dynamic>>>(
          future: _vendaFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhuma venda encontrada'));
            } else {
              final vendasPorNome = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vendasPorNome.length,
                itemBuilder: (context, index) {
                  final nome = vendasPorNome.keys.elementAt(index);
                  final totalVendas = vendasPorNome[nome]!['total'];
                  final quantidade = vendasPorNome[nome]!['quantidade'];

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
                          Text('Nome: $nome',
                              style: AppStyles.listItemTitleStyle),
                          const SizedBox(height: 10),
                          Text(
                              'Quantidade de ${_selectedReportType == 'Clientes' ? 'Compras' : 'Vendas'}: $quantidade',
                              style: AppStyles.listItemSubtitleStyle),
                          const SizedBox(height: 10),
                          Text(
                              'Total de ${_selectedReportType == 'Clientes' ? 'Compras' : 'Vendas'}: R\$ ${double.tryParse(totalVendas.toString())?.toStringAsFixed(2) ?? '0.00'}',
                              style: AppStyles.listItemSubtitleStyle),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }

  void _openSelectDates(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecione datas', style: AppStyles.formTitleStyle),
          content: IntrinsicHeight(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 600,
                child: FilterForm(
                  onFormSubmitted: (dataInicial, dataFinal) {
                    _refreshVendas(
                        dataInicial: dataInicial, dataFinal: dataFinal);
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

  Future<Map<String, dynamic>> _fetchRelatorio(
    {required String cpf, String? dataInicial, String? dataFinal}) async {
    try {
      final dio = Dio();
      final options = Options(headers: {'jwt-access': jwt});
      final String endpoint = _selectedReportType == 'Clientes'
          ? 'http://localhost:3300/vendas/relatorio/cliente'
          : 'http://localhost:3300/vendas/relatorio/funcionario';

      String? formattedDataInicio;
      String? formattedDataFim;

      if (dataInicial != null && dataInicial.isNotEmpty) {
        formattedDataInicio = '${dataInicial}T00:00:00';
      }

      if (dataFinal != null && dataFinal.isNotEmpty) {
        formattedDataFim = '${dataFinal}T23:59:59';
      }

      final response = await dio.get(
        endpoint,
        queryParameters: formattedDataInicio != null
            ? {
                'cpf': cpf,
                'dataInicio': formattedDataInicio,
                'dataFim': formattedDataFim,
              }
            : {
                'cpf': cpf,
              },
        options: options,
      );

      if (response.statusCode == 201 && _isMounted) {
        return response.data;
      } else {
        throw Exception('Failed to load vendas');
      }
    } catch (error) {
      if (_isMounted) {
        setState(() {});
      }
      throw Exception('Failed to load vendas: $error');
    }
  }


  Future<Map<String, String>> _fetchUserCpfs({String? query}) async {
    try {
      final dio = Dio();
      final options = Options(headers: {'jwt-access': jwt});
      final response = await dio.get(
        'http://localhost:3300/users/',
        queryParameters:
            query != null && query.isNotEmpty ? {'usuario': query} : null,
        options: options,
      );

      if (response.statusCode == 201 && _isMounted) {
        final List<dynamic> responseData = response.data['usuarios'];
        final Map<String, String> cpfToNameMap = {};
        final List<User> users =
            responseData.map((json) => User.fromJson(json)).toList();
        for (var user in users) {
          if (_selectedReportType == 'Funcionários' && user.role.id != 4) {
            cpfToNameMap[user.cpf] = user.nome;
          } else if (_selectedReportType == 'Clientes' && user.role.id == 4) {
            cpfToNameMap[user.cpf] = user.nome;
          }
        }
        return cpfToNameMap;
      } else {
        throw Exception('Failed to load users');
      }
    } catch (error) {
      if (_isMounted) {
        setState(() {
        });
      }
      throw Exception('Failed to load users: $error');
    }
  }
}

class FilterForm extends StatefulWidget {
  final Function onFormSubmitted;

  const FilterForm({super.key, required this.onFormSubmitted});

  @override
  // ignore: library_private_types_in_public_api
  _FilterFormState createState() => _FilterFormState();
}

class _FilterFormState extends State<FilterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _dataFinalController = TextEditingController();

  DateTime? _dateInicial;
  DateTime? _dateFinal;

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
          const Text("de"),
          const SizedBox(height: 5),
          TextFormField(
            controller: _dataInicioController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              suffixIcon: const Icon(
                Icons.calendar_today,
                color: AppStyles.primaryColor,
              ),
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
                    _dateInicial = pickeddate;
                    _dataInicioController.text =
                        DateFormat('dd-MM-yyyy').format(pickeddate);
                  },
                );
              }
            },
          ),
          const SizedBox(height: 10),
          const Text("para"),
          const SizedBox(height: 5),
          TextFormField(
            controller: _dataFinalController,
            decoration: AppStyles.textFieldDecoration.copyWith(
              suffixIcon: const Icon(
                Icons.calendar_today,
                color: AppStyles.primaryColor,
              ),
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
                    _dateFinal = pickeddate;
                    _dataFinalController.text =
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
            child: const Text('Mostrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_dateInicial == null || _dateFinal == null) {
        Fluttertoast.showToast(
          msg: 'Por favor, selecione ambas as datas.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
        );
        return;
      }

      if (_dateInicial!.isAfter(_dateFinal!)) {
        Fluttertoast.showToast(
          msg: 'A data inicial não pode ser posterior à data final.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
        );
        return;
      }

      if (_dateInicial!.isAfter(DateTime.now()) ||
          _dateFinal!.isAfter(DateTime.now())) {
        Fluttertoast.showToast(
          msg: 'A data inicial e final não pode ser posterior à data de hoje.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
        );
        return;
      }

      try {
        final dataInicial = DateFormat('yyyy-MM-dd').format(_dateInicial!);
        final dataFinal = DateFormat('yyyy-MM-dd').format(_dateFinal!);

        widget.onFormSubmitted(dataInicial, dataFinal);

        Fluttertoast.showToast(
          msg: 'Formulário enviado com sucesso!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Erro ao enviar formulário: $e',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dataInicioController.dispose();
    _dataFinalController.dispose();
    super.dispose();
  }
}
