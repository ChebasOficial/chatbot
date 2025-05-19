import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/utils/validators.dart';
import 'package:chatbot/widgets/custom_button.dart';
import 'package:chatbot/widgets/custom_text_field.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _adminLogin() async {
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
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      
      // Fazer login administrativo no provider
      final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
      await authProvider.adminLogin(username, password);
      
      // Navegar para a tela de cozinha se o login for bem-sucedido
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/kitchen');
      }
    } catch (e) {
      // Mostrar erro se ocorrer
      setState(() {
        _errorMessage = e.toString();
      });
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
                        'Restaurante Escola Palidro',
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
                // Formulário de login administrativo
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
                            'Acesso Administrativo',
                            style: Theme.of(context).textTheme.displayMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Acesso restrito para funcionários da cozinha.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Campo de usuário
                          CustomTextField(
                            controller: _usernameController,
                            label: 'Usuário',
                            hintText: 'admin@p4ed.com.br',
                            prefixIcon: Icons.person,
                            validator: Validators.validateAdminUsername,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          // Campo de senha
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Senha',
                            hintText: 'Digite sua senha',
                            prefixIcon: Icons.lock,
                            obscureText: _obscurePassword,
                            validator: Validators.validatePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _adminLogin(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Botão de login
                          CustomButton(
                            text: 'Entrar',
                            isLoading: _isLoading,
                            onPressed: _adminLogin,
                          ),
                          const SizedBox(height: 16),
                          // Link para login de aluno
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/');
                            },
                            child: Text(
                              'Voltar para login de aluno',
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
