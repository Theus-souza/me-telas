import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MedControlApp());
}

const Color fundoEscuro = Color(0xFF050816);
const Color fundoCard = Color(0xFF111827);
const Color azulNeon = Color(0xFF00B4D8);
const Color azulForte = Color(0xFF0077B6);
const Color textoClaro = Color(0xFFF8FAFC);

class MedControlApp extends StatelessWidget {
  const MedControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedControl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: fundoEscuro,
        primaryColor: azulNeon,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: azulForte,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const SistemaMedControl(),
    );
  }
}

class SistemaMedControl extends StatefulWidget {
  const SistemaMedControl({super.key});

  @override
  State<SistemaMedControl> createState() => _SistemaMedControlState();
}

class _SistemaMedControlState extends State<SistemaMedControl> {
  String telaAtual = 'login';
  bool logado = false;
  bool carregando = false;

  String usuarioNome = '';

  final loginKey = GlobalKey<FormState>();
  final cadastroUsuarioKey = GlobalKey<FormState>();
  final cadastroIdosoKey = GlobalKey<FormState>();
  final cadastroResponsavelKey = GlobalKey<FormState>();
  final cadastroRemedioKey = GlobalKey<FormState>();

  final loginUsuarioController = TextEditingController();
  final loginSenhaController = TextEditingController();

  final usuarioNomeController = TextEditingController();
  final usuarioEmailController = TextEditingController();
  final usuarioSenhaController = TextEditingController();

  final idosoNomeController = TextEditingController();
  final idosoIdadeController = TextEditingController();
  final idosoCpfController = TextEditingController();
  final idosoAlergiaController = TextEditingController();

  final responsavelNomeController = TextEditingController();
  final responsavelTelefoneController = TextEditingController();
  final responsavelParentescoController = TextEditingController();

  final remedioNomeController = TextEditingController();
  final remedioDosagemController = TextEditingController();
  final remedioHorarioController = TextEditingController();
  final remedioIdosoController = TextEditingController();
  final remedioObservacaoController = TextEditingController();

  List<Map<String, dynamic>> idosos = [];
  List<Map<String, dynamic>> responsaveis = [];
  List<Map<String, dynamic>> remedios = [];

  @override
  void initState() {
    super.initState();
    carregarDadosFirebase();
  }

  String? campoObrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }

  String valorTexto(dynamic valor) {
    if (valor == null || valor.toString().trim().isEmpty) {
      return 'Não informado';
    }

    return valor.toString();
  }

  void mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> carregarDadosFirebase() async {
    setState(() {
      carregando = true;
    });

    try {
      final idososSnap = await FirebaseFirestore.instance
          .collection('idosos')
          .get();

      final responsaveisSnap = await FirebaseFirestore.instance
          .collection('responsaveis')
          .get();

      final remediosSnap = await FirebaseFirestore.instance
          .collection('remedios')
          .get();

      idosos = idososSnap.docs.map((doc) {
        final dados = doc.data();
        dados['id'] = doc.id;
        return dados;
      }).toList();

      responsaveis = responsaveisSnap.docs.map((doc) {
        final dados = doc.data();
        dados['id'] = doc.id;
        return dados;
      }).toList();

      remedios = remediosSnap.docs.map((doc) {
        final dados = doc.data();
        dados['id'] = doc.id;
        return dados;
      }).toList();

      remedios.sort((a, b) {
        return valorTexto(a['horario']).compareTo(valorTexto(b['horario']));
      });
    } catch (erro) {
      mostrarMensagem('Erro ao carregar dados do Firebase.');
    }

    setState(() {
      carregando = false;
    });
  }

  Future<void> entrar() async {
    if (loginKey.currentState!.validate()) {
      final usuario = loginUsuarioController.text.trim();
      final senha = loginSenhaController.text.trim();

      if (usuario == 'admin' && senha == '1234') {
        setState(() {
          usuarioNome = 'Administrador';
          logado = true;
          telaAtual = 'inicio';
        });

        await carregarDadosFirebase();
        return;
      }

      final consulta = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: usuario)
          .where('senha', isEqualTo: senha)
          .get();

      if (consulta.docs.isNotEmpty) {
        final dados = consulta.docs.first.data();

        setState(() {
          usuarioNome = dados['nome'] ?? 'Usuário';
          logado = true;
          telaAtual = 'inicio';
        });

        await carregarDadosFirebase();
      } else {
        mostrarMensagem('Usuário ou senha incorretos.');
      }
    }
  }

  void sair() {
    setState(() {
      logado = false;
      telaAtual = 'login';
      loginUsuarioController.clear();
      loginSenhaController.clear();
    });
  }

  Future<void> salvarUsuario() async {
    if (cadastroUsuarioKey.currentState!.validate()) {
      final dadosUsuario = {
        'nome': usuarioNomeController.text.trim(),
        'email': usuarioEmailController.text.trim(),
        'senha': usuarioSenhaController.text.trim(),
        'criadoEm': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance.collection('usuarios').add(dadosUsuario);

      usuarioNomeController.clear();
      usuarioEmailController.clear();
      usuarioSenhaController.clear();

      setState(() {
        telaAtual = 'login';
      });

      mostrarMensagem('Usuário cadastrado no Firebase com sucesso.');
    }
  }

  Future<void> salvarIdoso() async {
    if (cadastroIdosoKey.currentState!.validate()) {
      final dadosIdoso = {
        'nome': idosoNomeController.text.trim(),
        'idade': idosoIdadeController.text.trim(),
        'cpf': idosoCpfController.text.trim(),
        'alergia': idosoAlergiaController.text.trim(),
        'criadoEm': DateTime.now().toIso8601String(),
      };

      final doc = await FirebaseFirestore.instance
          .collection('idosos')
          .add(dadosIdoso);

      dadosIdoso['id'] = doc.id;

      setState(() {
        idosos.add(dadosIdoso);
      });

      idosoNomeController.clear();
      idosoIdadeController.clear();
      idosoCpfController.clear();
      idosoAlergiaController.clear();

      mostrarMensagem('Idoso salvo no Firebase com sucesso.');
    }
  }

  Future<void> salvarResponsavel() async {
    if (cadastroResponsavelKey.currentState!.validate()) {
      final dadosResponsavel = {
        'nome': responsavelNomeController.text.trim(),
        'telefone': responsavelTelefoneController.text.trim(),
        'parentesco': responsavelParentescoController.text.trim(),
        'criadoEm': DateTime.now().toIso8601String(),
      };

      final doc = await FirebaseFirestore.instance
          .collection('responsaveis')
          .add(dadosResponsavel);

      dadosResponsavel['id'] = doc.id;

      setState(() {
        responsaveis.add(dadosResponsavel);
      });

      responsavelNomeController.clear();
      responsavelTelefoneController.clear();
      responsavelParentescoController.clear();

      mostrarMensagem('Responsável salvo no Firebase com sucesso.');
    }
  }

  Future<void> salvarRemedio() async {
    if (cadastroRemedioKey.currentState!.validate()) {
      final dadosRemedio = {
        'nome': remedioNomeController.text.trim(),
        'dosagem': remedioDosagemController.text.trim(),
        'horario': remedioHorarioController.text.trim(),
        'idoso': remedioIdosoController.text.trim(),
        'observacao': remedioObservacaoController.text.trim(),
        'tomado': false,
        'criadoEm': DateTime.now().toIso8601String(),
      };

      final doc = await FirebaseFirestore.instance
          .collection('remedios')
          .add(dadosRemedio);

      dadosRemedio['id'] = doc.id;

      setState(() {
        remedios.add(dadosRemedio);

        remedios.sort((a, b) {
          return valorTexto(a['horario']).compareTo(valorTexto(b['horario']));
        });
      });

      remedioNomeController.clear();
      remedioDosagemController.clear();
      remedioHorarioController.clear();
      remedioIdosoController.clear();
      remedioObservacaoController.clear();

      mostrarMensagem('Remédio salvo no Firebase com sucesso.');
    }
  }

  Future<void> marcarTomado(int index) async {
    final id = remedios[index]['id'];

    if (id != null) {
      await FirebaseFirestore.instance.collection('remedios').doc(id).update({
        'tomado': true,
      });
    }

    setState(() {
      remedios[index]['tomado'] = true;
    });

    mostrarMensagem('Remédio marcado como tomado.');
  }

  Future<void> marcarPendente(int index) async {
    final id = remedios[index]['id'];

    if (id != null) {
      await FirebaseFirestore.instance.collection('remedios').doc(id).update({
        'tomado': false,
      });
    }

    setState(() {
      remedios[index]['tomado'] = false;
    });

    mostrarMensagem('Remédio marcado como pendente.');
  }

  Future<void> excluirRemedio(int index) async {
    final id = remedios[index]['id'];

    if (id != null) {
      await FirebaseFirestore.instance.collection('remedios').doc(id).delete();
    }

    setState(() {
      remedios.removeAt(index);
    });

    mostrarMensagem('Remédio excluído do Firebase.');
  }

  Future<void> limparTudo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content: const Text('Deseja apagar todos os remédios?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      final snap = await FirebaseFirestore.instance
          .collection('remedios')
          .get();

      for (final doc in snap.docs) {
        await doc.reference.delete();
      }

      setState(() {
        remedios.clear();
      });

      mostrarMensagem('Todos os remédios foram apagados.');
    }
  }

  int get totalTomados {
    return remedios.where((r) => r['tomado'] == true).length;
  }

  int get totalPendentes {
    return remedios.where((r) => r['tomado'] == false).length;
  }

  String get proximoRemedio {
    final pendentes = remedios.where((r) => r['tomado'] == false).toList();

    if (pendentes.isEmpty) {
      return 'Nenhum remédio pendente.';
    }

    pendentes.sort((a, b) {
      return valorTexto(a['horario']).compareTo(valorTexto(b['horario']));
    });

    return '${pendentes.first['nome']} às ${pendentes.first['horario']}';
  }

  @override
  Widget build(BuildContext context) {
    if (!logado && telaAtual == 'cadastroUsuario') {
      return telaCadastroUsuario();
    }

    if (!logado) {
      return telaLogin();
    }

    if (telaAtual == 'inicio') return telaInicio();
    if (telaAtual == 'cadastroIdoso') return telaCadastroIdoso();
    if (telaAtual == 'cadastroResponsavel') return telaCadastroResponsavel();
    if (telaAtual == 'cadastroRemedio') return telaCadastroRemedio();
    if (telaAtual == 'listagemRemedios') return telaListagemRemedios();
    if (telaAtual == 'listagemIdosos') return telaListagemIdosos();
    if (telaAtual == 'agenda') return telaAgenda();
    if (telaAtual == 'relatorio') return telaRelatorio();

    return telaInicio();
  }

  Widget fundo({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }

  Widget painel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: azulNeon.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: azulNeon.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration decoracaoCampo(String texto) {
    return InputDecoration(
      labelText: texto,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: azulNeon, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget campo({
    required TextEditingController controller,
    required String label,
    bool senha = false,
    bool obrigatorio = true,
    TextInputType tipo = TextInputType.text,
    int linhas = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: senha,
        keyboardType: tipo,
        maxLines: senha ? 1 : linhas,
        style: const TextStyle(color: Colors.white),
        decoration: decoracaoCampo(label),
        validator: obrigatorio ? campoObrigatorio : null,
      ),
    );
  }

  Widget botao(String texto, Future<void> Function() acao) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await acao();
        },
        child: Text(texto),
      ),
    );
  }

  Widget telaLogin() {
    return Scaffold(
      body: fundo(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: painel(
              child: Form(
                key: loginKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '💊 MedControl',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: azulNeon,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sistema de controle de remédios para idosos',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: textoClaro),
                    ),
                    const SizedBox(height: 24),
                    campo(
                      controller: loginUsuarioController,
                      label: 'Usuário ou e-mail',
                    ),
                    campo(
                      controller: loginSenhaController,
                      label: 'Senha',
                      senha: true,
                    ),
                    botao('Entrar', entrar),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          telaAtual = 'cadastroUsuario';
                        });
                      },
                      child: const Text('Criar cadastro'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Acesso padrão: admin | Senha: 1234',
                      style: TextStyle(color: Colors.white70),
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

  Widget telaCadastroUsuario() {
    return Scaffold(
      body: fundo(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: painel(
              child: Form(
                key: cadastroUsuarioKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Cadastro de Usuário',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: azulNeon,
                      ),
                    ),
                    const SizedBox(height: 20),
                    campo(
                      controller: usuarioNomeController,
                      label: 'Nome do usuário',
                    ),
                    campo(
                      controller: usuarioEmailController,
                      label: 'E-mail',
                      tipo: TextInputType.emailAddress,
                    ),
                    campo(
                      controller: usuarioSenhaController,
                      label: 'Senha',
                      senha: true,
                    ),
                    botao('Salvar cadastro', salvarUsuario),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          telaAtual = 'login';
                        });
                      },
                      child: const Text('Voltar para login'),
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

  Widget estruturaApp(String titulo, Widget conteudo) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        title: Text(titulo),
        actions: [
          TextButton(
            onPressed: sair,
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: fundoCard,
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💊 MedControl',
                    style: TextStyle(
                      color: azulNeon,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    usuarioNome.isEmpty ? 'Usuário logado' : usuarioNome,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            itemMenu('Início', Icons.dashboard, 'inicio'),
            itemMenu('Cadastro de Idoso', Icons.person_add, 'cadastroIdoso'),
            itemMenu(
              'Cadastro de Responsável',
              Icons.people,
              'cadastroResponsavel',
            ),
            itemMenu(
              'Cadastro de Remédio',
              Icons.medical_services,
              'cadastroRemedio',
            ),
            itemMenu(
              'Listagem de Remédios',
              Icons.list_alt,
              'listagemRemedios',
            ),
            itemMenu('Listagem de Idosos', Icons.group, 'listagemIdosos'),
            itemMenu('Agenda', Icons.schedule, 'agenda'),
            itemMenu('Relatório', Icons.analytics, 'relatorio'),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Sair', style: TextStyle(color: Colors.white)),
              onTap: sair,
            ),
          ],
        ),
      ),
      body: fundo(
        child: carregando
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: conteudo,
              ),
      ),
    );
  }

  Widget itemMenu(String titulo, IconData icone, String tela) {
    return ListTile(
      leading: Icon(icone, color: azulNeon),
      title: Text(titulo, style: const TextStyle(color: Colors.white)),
      selected: telaAtual == tela,
      selectedTileColor: Colors.white.withOpacity(0.08),
      onTap: () {
        setState(() {
          telaAtual = tela;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget telaInicio() {
    return estruturaApp(
      'Início',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          painel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bem-vindo ao MedControl',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: azulNeon,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gerencie idosos, responsáveis, remédios, horários e acompanhamento de uso.',
                  style: TextStyle(fontSize: 17, color: textoClaro),
                ),
                const SizedBox(height: 16),
                Text(
                  'Próximo remédio: $proximoRemedio',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              atalho('Cadastrar Idoso', Icons.person_add, 'cadastroIdoso'),
              atalho(
                'Cadastrar Responsável',
                Icons.people,
                'cadastroResponsavel',
              ),
              atalho(
                'Cadastrar Remédio',
                Icons.medical_services,
                'cadastroRemedio',
              ),
              atalho('Ver Remédios', Icons.list_alt, 'listagemRemedios'),
              atalho('Ver Idosos', Icons.group, 'listagemIdosos'),
              atalho('Relatório', Icons.analytics, 'relatorio'),
            ],
          ),
        ],
      ),
    );
  }

  Widget atalho(String titulo, IconData icone, String tela) {
    return InkWell(
      onTap: () {
        setState(() {
          telaAtual = tela;
        });
      },
      child: Container(
        width: 180,
        height: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: azulNeon.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: azulNeon, size: 34),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: textoClaro, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget telaCadastroIdoso() {
    return estruturaApp(
      'Cadastro de Idoso',
      painel(
        child: Form(
          key: cadastroIdosoKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tituloSecao('Cadastrar Idoso'),
              campo(controller: idosoNomeController, label: 'Nome completo'),
              campo(
                controller: idosoIdadeController,
                label: 'Idade',
                tipo: TextInputType.number,
              ),
              campo(controller: idosoCpfController, label: 'CPF'),
              campo(
                controller: idosoAlergiaController,
                label: 'Alergias ou observações de saúde',
                obrigatorio: false,
                linhas: 3,
              ),
              botao('Salvar idoso no Firebase', salvarIdoso),
            ],
          ),
        ),
      ),
    );
  }

  Widget telaCadastroResponsavel() {
    return estruturaApp(
      'Cadastro de Responsável',
      painel(
        child: Form(
          key: cadastroResponsavelKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tituloSecao('Cadastrar Responsável'),
              campo(
                controller: responsavelNomeController,
                label: 'Nome do responsável',
              ),
              campo(
                controller: responsavelTelefoneController,
                label: 'Telefone',
                tipo: TextInputType.phone,
              ),
              campo(
                controller: responsavelParentescoController,
                label: 'Parentesco',
              ),
              botao('Salvar responsável no Firebase', salvarResponsavel),
            ],
          ),
        ),
      ),
    );
  }

  Widget telaCadastroRemedio() {
    return estruturaApp(
      'Cadastro de Remédio',
      painel(
        child: Form(
          key: cadastroRemedioKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tituloSecao('Cadastrar Remédio'),
              campo(
                controller: remedioNomeController,
                label: 'Nome do remédio',
              ),
              campo(controller: remedioDosagemController, label: 'Dosagem'),
              campo(
                controller: remedioHorarioController,
                label: 'Horário. Ex: 08:00',
              ),
              campo(controller: remedioIdosoController, label: 'Nome do idoso'),
              campo(
                controller: remedioObservacaoController,
                label: 'Observação',
                obrigatorio: false,
                linhas: 3,
              ),
              botao('Salvar remédio no Firebase', salvarRemedio),
            ],
          ),
        ),
      ),
    );
  }

  Widget telaListagemRemedios() {
    return estruturaApp(
      'Listagem de Remédios',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          painel(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total: ${remedios.length}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Tomados: $totalTomados',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Pendentes: $totalPendentes',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          remedios.isEmpty
              ? painel(
                  child: const Text(
                    'Nenhum remédio cadastrado.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Column(
                  children: List.generate(remedios.length, (index) {
                    final r = remedios[index];

                    return painel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            valorTexto(r['nome']),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: azulNeon,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Dosagem: ${valorTexto(r['dosagem'])}'),
                          Text('Horário: ${valorTexto(r['horario'])}'),
                          Text('Idoso: ${valorTexto(r['idoso'])}'),
                          Text('Observação: ${valorTexto(r['observacao'])}'),
                          Text(
                            'Status: ${r['tomado'] == true ? 'Tomado' : 'Pendente'}',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await marcarTomado(index);
                                },
                                child: const Text('Tomado'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  await marcarPendente(index);
                                },
                                child: const Text('Pendente'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  await excluirRemedio(index);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                child: const Text('Excluir'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ),
          if (remedios.isNotEmpty)
            ElevatedButton(
              onPressed: limparTudo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Limpar todos os remédios'),
            ),
        ],
      ),
    );
  }

  Widget telaListagemIdosos() {
    return estruturaApp(
      'Listagem de Idosos e Responsáveis',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tituloSecao('Idosos cadastrados'),
          const SizedBox(height: 10),
          idosos.isEmpty
              ? painel(child: const Text('Nenhum idoso cadastrado.'))
              : Column(
                  children: idosos.map((i) {
                    return painel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            valorTexto(i['nome']),
                            style: const TextStyle(
                              fontSize: 22,
                              color: azulNeon,
                            ),
                          ),
                          Text('Idade: ${valorTexto(i['idade'])} anos'),
                          Text('CPF: ${valorTexto(i['cpf'])}'),
                          Text(
                            'Alergias/observações: ${valorTexto(i['alergia'])}',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 20),
          tituloSecao('Responsáveis cadastrados'),
          const SizedBox(height: 10),
          responsaveis.isEmpty
              ? painel(child: const Text('Nenhum responsável cadastrado.'))
              : Column(
                  children: responsaveis.map((r) {
                    return painel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            valorTexto(r['nome']),
                            style: const TextStyle(
                              fontSize: 22,
                              color: azulNeon,
                            ),
                          ),
                          Text('Telefone: ${valorTexto(r['telefone'])}'),
                          Text('Parentesco: ${valorTexto(r['parentesco'])}'),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget telaAgenda() {
    final agenda = [...remedios];

    agenda.sort((a, b) {
      return valorTexto(a['horario']).compareTo(valorTexto(b['horario']));
    });

    return estruturaApp(
      'Agenda de Horários',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          painel(
            child: Text(
              'Próximo remédio: $proximoRemedio',
              style: const TextStyle(fontSize: 20, color: azulNeon),
            ),
          ),
          agenda.isEmpty
              ? painel(child: const Text('Nenhum horário cadastrado.'))
              : Column(
                  children: agenda.map((r) {
                    return painel(
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: azulNeon),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${valorTexto(r['horario'])} - ${valorTexto(r['nome'])} (${valorTexto(r['idoso'])})',
                              style: const TextStyle(fontSize: 17),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget telaRelatorio() {
    return estruturaApp(
      'Relatório',
      Column(
        children: [
          painel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tituloSecao('Resumo do Sistema'),
                Text(
                  'Idosos cadastrados: ${idosos.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Responsáveis cadastrados: ${responsaveis.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Remédios cadastrados: ${remedios.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Remédios tomados: $totalTomados',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Remédios pendentes: $totalPendentes',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          painel(
            child: const Text(
              'O sistema utiliza Scaffold para estruturar as telas, Text para exibir informações, TextFormField para cadastrar dados e ElevatedButton para ações como entrar, salvar, marcar e excluir. O Firebase Firestore foi usado como banco de dados para armazenar usuários, idosos, responsáveis e remédios.',
              style: TextStyle(fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }

  Widget tituloSecao(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: azulNeon,
      ),
    );
  }
}
