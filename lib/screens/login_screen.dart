import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chatbot/models/user.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/utils/validators.dart';
import 'package:chatbot/widgets/custom_button.dart';
import 'package:chatbot/widgets/custom_text_field.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _raController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isFirstLogin = false;
  bool _isCheckingFirstLogin = false;
  String? _infoMessage;
  String? _errorMessage;

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    // Verificar se o usuário já está logado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider =
          Provider.of<ChatbotAuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn && !authProvider.isAdminLoggedIn) {
        Navigator.pushReplacementNamed(context, '/cardapio');
      }
    });
  }

  @override
  void dispose() {
    _raController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Verificar automaticamente se é o primeiro login quando o RA é alterado
  void _onRAChanged(String value) {
    // Limpar mensagens anteriores
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });

    // Verificar se o RA está no formato correto
    final raRegex = RegExp(r'^\d{8}@p4ed\.com\.br$');
    if (raRegex.hasMatch(value.trim())) {
      // Formato válido, verificar se é primeiro login
      _checkIfFirstLogin();
    } else {
      // Formato inválido, limpar estado de primeiro login
      setState(() {
        _isFirstLogin = false;
      });
    }
  }

  // Verificar se é o primeiro login do usuário
  Future<void> _checkIfFirstLogin() async {
    if (_raController.text.isEmpty) return;

    setState(() {
      _isCheckingFirstLogin = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      // Validar formato do RA antes de verificar
      final raRegex = RegExp(r'^\d{8}@p4ed\.com\.br$');
      if (!raRegex.hasMatch(_raController.text.trim())) {
        setState(() {
          _errorMessage = 'R.A. inválido. Use o formato: 12345678@p4ed.com.br';
          _isCheckingFirstLogin = false;
        });
        return;
      }

      // Verificar no armazenamento local primeiro
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('user_email');

      if (storedEmail == _raController.text.trim()) {
        // Usuário já existe localmente
        setState(() {
          _isFirstLogin = false;
          _isCheckingFirstLogin = false;
        });
        return;
      }

      try {
        // Buscar usuário pelo email no Firestore
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('ra', isEqualTo: _raController.text.trim())
            .limit(1)
            .get();

        final isFirstLogin = querySnapshot.docs.isEmpty;

        if (!isFirstLogin) {
          // Usuário já existe, recuperar o telefone
          final userData = querySnapshot.docs.first.data();
          final phone = userData['phone'] as String?;

          if (phone != null && phone.isNotEmpty) {
            // Preencher o campo de telefone automaticamente
            _phoneController.text = phone;

            // Salvar localmente para uso futuro
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_email', _raController.text.trim());
            await prefs.setString('user_phone', phone);

            print('Telefone recuperado do Firestore: $phone');
          }
        }

        setState(() {
          _isFirstLogin = isFirstLogin;
          _isCheckingFirstLogin = false;

          // Mostrar mensagem informativa se for primeiro login
          if (isFirstLogin) {
            _infoMessage = 'Por favor, informe seu telefone para continuar.';
          } else {
            // Se não for primeiro login, mostrar mensagem que o telefone foi recuperado
            _infoMessage = 'Telefone recuperado automaticamente.';
          }
        });
      } catch (firestoreError) {
        // Tratar erros específicos do Firestore de forma amigável
        print('Erro do Firestore: $firestoreError');

        // Assumir que é primeiro login para permitir que o usuário continue
        setState(() {
          _isFirstLogin = true;
          _isCheckingFirstLogin = false;
          _infoMessage = 'Por favor, informe seu telefone para continuar.';
        });
      }
    } catch (e) {
      print('Erro geral ao verificar primeiro login: $e');
      setState(() {
        _isFirstLogin =
            true; // Em caso de erro, assumir primeiro login para pedir telefone
        _isCheckingFirstLogin = false;
        _infoMessage = 'Por favor, informe seu telefone para continuar.';
      });
    }
  }

  Future<void> _login() async {
    // Validar formulário
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Se for primeiro login, verificar se o telefone foi informado
        if (_isFirstLogin && _phoneController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Por favor, informe seu telefone para continuar.';
            _isLoading = false;
          });
          return;
        }

        final authProvider =
            Provider.of<ChatbotAuthProvider>(context, listen: false);

        // Criar objeto de usuário com os dados informados
        final user = User(
          ra: _raController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        // Tentar fazer login
        await authProvider.login(user);

        // Se chegou aqui, login foi bem-sucedido
        if (!mounted) return;

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar para o cardápio imediatamente após login bem-sucedido
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/cardapio',
          ModalRoute.withName('/'), // Mantém apenas a rota inicial (/) na pilha
        );
      } catch (e) {
        print('Erro durante login na tela: $e');
        if (!mounted) return;

        // Tratar mensagens de erro de forma amigável
        String errorMessage =
            'Não foi possível fazer login. Verifique sua conexão com a internet.';

        // Personalizar mensagens para erros específicos
        if (e.toString().contains('R.A. inválido')) {
          errorMessage = 'R.A. inválido. Use o formato: 12345678@p4ed.com.br';
        } else if (e.toString().contains('Telefone inválido')) {
          errorMessage = 'Telefone inválido. Use o formato: (11) 98765-4321';
        } else if (e.toString().contains('Telefone é obrigatório')) {
          errorMessage = 'Por favor, informe seu telefone para continuar.';
        } else if (e.toString().contains('permission-denied') ||
            e.toString().contains('Erro de permissão')) {
          errorMessage =
              'Erro de permissão ao acessar o banco de dados. Verifique as regras de segurança.';
        } else if (e.toString().contains('network') ||
            e.toString().contains('Sem conexão')) {
          errorMessage =
              'Sem conexão com a internet. O login requer conexão ativa.';
        } else if (e.toString().contains('wrong-password') ||
            e.toString().contains('invalid-credential') ||
            e.toString().contains('Senha incorreta')) {
          errorMessage =
              'Senha incorreta. Verifique se o telefone está correto.';
        } else if (e.toString().contains('Erro de autenticação')) {
          errorMessage =
              'Erro de autenticação. Verifique sua conexão e tente novamente.';
        } else if (e.toString().contains('Por favor, informe o telefone')) {
          errorMessage = 'Por favor, informe o telefone para fazer login.';
        } else if (e.toString().contains('Erro ao verificar existência')) {
          errorMessage =
              'Erro ao verificar usuário. Verifique sua conexão com a internet.';
        } else if (e
            .toString()
            .contains('GooglePlayServicesNotAvailableException')) {
          errorMessage =
              'Google Play Services não disponível. Verifique se está instalado e atualizado.';
        } else if (e.toString().contains('email-already-in-use')) {
          // Tentar fazer login diretamente se o email já existe
          try {
            final authProvider =
                Provider.of<ChatbotAuthProvider>(context, listen: false);

            // Criar objeto de usuário com os dados informados
            final user = User(
              ra: _raController.text.trim(),
              phone: _phoneController.text.trim(),
            );

            // Tentar fazer login novamente (agora o provider vai tentar login direto)
            await authProvider.login(user);

            // Se chegou aqui, login foi bem-sucedido
            if (!mounted) return;

            // Mostrar mensagem de sucesso
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login realizado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );

            // Navegar para o cardápio imediatamente após login bem-sucedido
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/cardapio',
              ModalRoute.withName(
                  '/'), // Mantém apenas a rota inicial (/) na pilha
            );

            // Retornar para evitar mostrar mensagem de erro
            return;
          } catch (loginError) {
            print(
                'Erro ao tentar login após email-already-in-use: $loginError');
            errorMessage =
                'Este email já está em uso. Verifique se o telefone está correto.';
          }
        }

        // Atualizar estado com mensagem de erro amigável
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  // Função segura para voltar
  void _handleBackNavigation() {
    try {
      // Verificar se há rotas na pilha para voltar
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        // Se não houver rota anterior, ir para a tela inicial
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      print('Erro ao navegar para trás: $e');
      // Em caso de erro, garantir que vá para a tela inicial
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Interceptar o botão físico de voltar do Android
      onWillPop: () async {
        _handleBackNavigation();
        return false; // Impedir o comportamento padrão
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black54),
            onPressed: _handleBackNavigation,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Section (Icon and Title)
                  const Column(
                    children: [
                      SizedBox(height: 30),
                      Icon(Icons.lock_outline, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'Login',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Formulário de login
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Acesso ao Chatbot',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Por favor, faça login para acessar o chatbot.',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Campo de R.A.
                            CustomTextField(
                              controller: _raController,
                              label: 'Registro Acadêmico (R.A.)',
                              hintText: '12345678@p4ed.com.br',
                              prefixIcon: Icons.person,
                              validator: Validators.validateRA,
                              textInputAction: TextInputAction.next,
                              onChanged: _onRAChanged,
                            ),
                            const SizedBox(height: 16),

                            // Indicador de carregamento durante verificação
                            if (_isCheckingFirstLogin)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),

                            // Mensagem informativa
                            if (_infoMessage != null && !_isCheckingFirstLogin)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 8.0, bottom: 8.0),
                                child: Text(
                                  _infoMessage!,
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            // Campo de telefone (visível automaticamente no primeiro login)
                            if (_isFirstLogin && !_isCheckingFirstLogin)
                              Column(
                                children: [
                                  CustomTextField(
                                    controller: _phoneController,
                                    label: 'Telefone',
                                    hintText: '(11) 98765-4321',
                                    prefixIcon: Icons.phone,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [_phoneMask],
                                    validator: Validators.validatePhone,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _login(),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Telefone necessário apenas no primeiro login',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),

                            // Mensagem de erro
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Botão de login
                            CustomButton(
                              text: 'Continuar',
                              isLoading: _isLoading,
                              onPressed: _login,
                            ),
                            const SizedBox(height: 16),

                            // Link para login administrativo
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/admin-login');
                              },
                              child: Text(
                                'Acesso Administrativo',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Bottom Logo
                  Column(children: [
                    // Placeholder for Poliedro Colégio Logo
                    Image.asset("lib/images/logo_pequeno.png"),
                    const Text('Poliedro Colégio',
                        style: TextStyle(color: Colors.grey)),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
