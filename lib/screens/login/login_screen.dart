import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/utils/validators.dart';
import 'package:chatbot/widgets/custom_button.dart';
import 'package:chatbot/widgets/custom_text_field.dart';
import 'package:chatbot/models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _raController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  
  bool _isLoading = false;
  bool _showPhoneField = false; // Ocultar campo de telefone por padrão
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    // Verificar se há telefone salvo para o RA quando o usuário digitar
    _raController.addListener(_checkSavedPhone);
  }
  
  @override
  void dispose() {
    _raController.removeListener(_checkSavedPhone);
    _raController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  // Verificar se há telefone salvo para o RA digitado
  void _checkSavedPhone() async {
    final ra = _raController.text.trim();
    if (ra.isEmpty || !RegExp(r'^\d{8}@p4ed\.com\.br$').hasMatch(ra)) {
      return; // RA inválido, não verificar
    }
    
    final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
    final savedPhone = await authProvider.getPhoneForRA(ra);
    
    if (savedPhone != null && savedPhone.isNotEmpty) {
      // Telefone encontrado, ocultar campo
      if (mounted) {
        setState(() {
          _showPhoneField = false;
          _phoneController.text = savedPhone; // Preencher para uso no login
        });
      }
    } else {
      // Telefone não encontrado, mostrar campo
      if (mounted) {
        setState(() {
          _showPhoneField = true;
          _phoneController.clear();
        });
      }
    }
  }
  
  Future<void> _login() async {
    // Validar formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Mostrar loading
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Obter dados do formulário
      final ra = _raController.text.trim();
      final phone = _phoneController.text.trim();
      
      // Criar objeto User para passar ao provider
      final user = User(ra: ra, phone: phone);
      
      // Fazer login no provider
      final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
      await authProvider.login(user);
      
      // Navegar para a tela apropriada com base no tipo de usuário
      if (context.mounted) {
        if (authProvider.isAdminLoggedIn) {
          // Se for admin, ir para a tela de gerenciamento
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          // Se for aluno, ir para a tela de chatbot
          Navigator.pushReplacementNamed(context, '/chatbot');
        }
      }
    } catch (e) {
      // Mostrar erro se ocorrer
      String errorMsg = e.toString();
      
      // Verificar se o erro é sobre telefone necessário
      if (errorMsg.contains('Telefone necessário')) {
        setState(() {
          _showPhoneField = true;
          _errorMessage = 'Por favor, informe seu telefone para o primeiro login.';
        });
      } else {
        setState(() {
          _errorMessage = errorMsg;
        });
      }
      print('Erro durante login na tela: $e');
    } finally {
      // Esconder loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Logo e título
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'P',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Restaurante Escola Poliedro',
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: Colors.white,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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
                            style: Theme.of(context).textTheme.displayMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Por favor, faça login para acessar o chatbot.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
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
                            textInputAction: _showPhoneField ? TextInputAction.next : TextInputAction.done,
                            onFieldSubmitted: (_) => _showPhoneField ? null : _login(),
                          ),
                          
                          // Campo de telefone - visível apenas quando necessário
                          if (_showPhoneField) ...[
                            const SizedBox(height: 16),
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
                          
                          // Mensagem de erro
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
