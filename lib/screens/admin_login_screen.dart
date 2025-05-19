import 'package:flutter/material.dart';
import 'package:chatbot/models/user.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/utils/validators.dart';
import 'package:chatbot/widgets/custom_button.dart';
import 'package:chatbot/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Verificar se o administrador já está logado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
      if (authProvider.isAdminLoggedIn) {
        Navigator.pushReplacementNamed(context, '/cardapio');
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _adminLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
        await authProvider.adminLogin(
          _usernameController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/cardapio');
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer login: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
                    Icon(Icons.admin_panel_settings, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      'Acesso Administrativo',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
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
                            'Acesso Restrito',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Acesso restrito para funcionários.',
                            style: TextStyle(
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
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          
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
                              Navigator.pushReplacementNamed(context, '/login');
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
