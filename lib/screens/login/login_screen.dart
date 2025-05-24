import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/utils/validators.dart';
import 'package:chatbot/widgets/custom_button.dart';
import 'package:chatbot/widgets/custom_text_field.dart';
import 'package:chatbot/models/user.dart';
import 'package:chatbot/config/style_guide.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  String? _errorMessage;

  @override
  void dispose() {
    _raController.dispose();
    _phoneController.dispose();
    super.dispose();
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
      final authProvider =
          Provider.of<ChatbotAuthProvider>(context, listen: false);
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

      setState(() {
        _errorMessage = errorMsg.replaceAll('Exception: ', '');
      });
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
          gradient: PoliedroFoodStyle.mainGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(PoliedroFoodStyle.spacingL),
            child: Column(
              children: [
                // Logo e título
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: PoliedroFoodStyle.spacingXL),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'lib/images/poliedro_logo.svg',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: PoliedroFoodStyle.spacingM),
                      const Text(
                        'Poliedro Food',
                        style: PoliedroFoodStyle.headingLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: PoliedroFoodStyle.spacingS),
                      const Text(
                        'Restaurante Escola Poliedro',
                        style: PoliedroFoodStyle.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: PoliedroFoodStyle.spacingL),
                // Formulário de login
                Container(
                  decoration: PoliedroFoodStyle.cardDecoration,
                  child: Padding(
                    padding: const EdgeInsets.all(PoliedroFoodStyle.spacingL),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Acesso ao Chatbot',
                            style: PoliedroFoodStyle.headingMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: PoliedroFoodStyle.spacingS),
                          const Text(
                            'Por favor, faça login para acessar o chatbot.',
                            style: PoliedroFoodStyle.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: PoliedroFoodStyle.spacingL),
                          // Campo de R.A.
                          TextFormField(
                            controller: _raController,
                            decoration: PoliedroFoodStyle.inputDecoration(
                              labelText: 'Registro Acadêmico (R.A.)',
                              hintText: '12345678@p4ed.com.br',
                              prefixIcon: Icons.person,
                            ),
                            validator: Validators.validateRA,
                            textInputAction: TextInputAction.next,
                          ),

                          // Campo de telefone - sempre visível
                          const SizedBox(height: PoliedroFoodStyle.spacingM),
                          TextFormField(
                            controller: _phoneController,
                            decoration: PoliedroFoodStyle.inputDecoration(
                              labelText: 'Telefone',
                              hintText: '(11) 98765-4321',
                              prefixIcon: Icons.phone,
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [_phoneMask],
                            validator: Validators.validatePhone,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: PoliedroFoodStyle.spacingS),

                          // Mensagem de erro
                          if (_errorMessage != null) ...[
                            const SizedBox(height: PoliedroFoodStyle.spacingM),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: PoliedroFoodStyle.errorRed,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          const SizedBox(height: PoliedroFoodStyle.spacingL),
                          // Botão de login
                          ElevatedButton(
                            style: PoliedroFoodStyle.primaryButtonStyle,
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Continuar'),
                          ),
                          const SizedBox(height: PoliedroFoodStyle.spacingM),
                          // Link para login administrativo
                          TextButton(
                            style: PoliedroFoodStyle.textButtonStyle,
                            onPressed: () {
                              Navigator.pushNamed(context, '/admin-login');
                            },
                            child: const Text('Acesso Administrativo'),
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
