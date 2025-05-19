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
      final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
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

  // Verificar se é o primeiro login do usuário
  Future<void> _checkIfFirstLogin() async {
    if (_raController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Validar formato do RA antes de verificar
      final raRegex = RegExp(r'^\d{8}@p4ed\.com\.br$');
      if (!raRegex.hasMatch(_raController.text.trim())) {
        setState(() {
          _errorMessage = 'R.A. inválido. Use o formato: 12345678@p4ed.com.br';
          _isLoading = false;
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
        
        setState(() {
          _isFirstLogin = querySnapshot.docs.isEmpty;
          _isLoading = false;
        });
        
        // Se for primeiro login, mostrar mensagem informativa
        if (_isFirstLogin && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Primeiro acesso detectado. Por favor, informe seu telefone.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (firestoreError) {
        // Tratar erros específicos do Firestore de forma amigável
        print('Erro do Firestore: $firestoreError');
        
        // Assumir que é primeiro login para permitir que o usuário continue
        setState(() {
          _isFirstLogin = true;
          _isLoading = false;
          
          // Mensagem amigável em vez de detalhes técnicos
          if (firestoreError.toString().contains('permission-denied')) {
            // Não mostrar mensagem de erro, apenas habilitar o campo de telefone
            _errorMessage = null;
            
            // Mostrar mensagem informativa
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, informe seu telefone para continuar.'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            });
          } else {
            _errorMessage = 'Não foi possível verificar o cadastro. Verifique sua conexão.';
          }
        });
      }
    } catch (e) {
      print('Erro geral ao verificar primeiro login: $e');
      setState(() {
        _isFirstLogin = true; // Em caso de erro, assumir primeiro login para pedir telefone
        _isLoading = false;
        _errorMessage = 'Não foi possível verificar o cadastro. Tente novamente mais tarde.';
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
            _errorMessage = 'Telefone é obrigatório no primeiro login';
            _isLoading = false;
          });
          return;
        }
        
        final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
        
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
        
        // Navegar para a próxima tela
        Navigator.pushReplacementNamed(context, '/cardapio');
      } catch (e) {
        print('Erro durante login na tela: $e');
        if (!mounted) return;
        
        // Tratar mensagens de erro de forma amigável
        String errorMessage = 'Erro ao fazer login. Tente novamente mais tarde.';
        
        // Personalizar mensagens para erros específicos
        if (e.toString().contains('R.A. inválido')) {
          errorMessage = 'R.A. inválido. Use o formato: 12345678@p4ed.com.br';
        } else if (e.toString().contains('Telefone inválido')) {
          errorMessage = 'Telefone inválido. Use o formato: (11) 98765-4321';
        } else if (e.toString().contains('Telefone é obrigatório')) {
          errorMessage = 'Telefone é obrigatório no primeiro login';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = 'Não foi possível acessar o banco de dados. Verifique sua conexão.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Erro de conexão. Verifique sua internet e tente novamente.';
        }
        
        // Atualizar estado com mensagem de erro amigável
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
        
        // Mostrar snackbar com erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                            onFieldSubmitted: (_) => _checkIfFirstLogin(),
                          ),
                          const SizedBox(height: 16),
                          
                          // Campo de telefone (visível apenas no primeiro login)
                          if (_isFirstLogin)
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
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Botão para verificar se é primeiro login
                          if (!_isFirstLogin && _raController.text.isNotEmpty)
                            OutlinedButton(
                              onPressed: _checkIfFirstLogin,
                              child: const Text('Verificar Cadastro'),
                            ),
                          
                          const SizedBox(height: 16),
                          
                          // Botão de login
                          CustomButton(
                            text: 'Continuar',
                            isLoading: _isLoading,
                            onPressed: () {
                              if (!_isFirstLogin && _raController.text.isNotEmpty) {
                                _login();
                              } else if (_isFirstLogin) {
                                _login();
                              } else {
                                _checkIfFirstLogin();
                              }
                            },
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
    );
  }
}
