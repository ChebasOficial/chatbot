import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:chatbot/providers/auth_provider.dart'; // Certifique-se que este caminho está correto
import 'package:chatbot/utils/validators.dart'; // Certifique-se que este caminho está correto
import 'package:chatbot/models/user.dart'; // Certifique-se que este caminho está correto
import 'package:chatbot/config/style_guide.dart'; // Certifique-se que este caminho está correto
import 'package:flutter_svg/flutter_svg.dart'; // Certifique-se que este caminho está correto

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
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final ra = _raController.text.trim();
      final phone = _phoneController.text.trim();
      final user = User(ra: ra, phone: phone);
      final authProvider =
          Provider.of<ChatbotAuthProvider>(context, listen: false);
      await authProvider.login(user);
      if (mounted) {
        if (authProvider.isAdminLoggedIn) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/chatbot');
        }
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (mounted) {
        setState(() {
          _errorMessage = errorMsg.replaceAll('Exception: ', '');
        });
      }
      print('Erro durante login na tela: $e');
    } finally {
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
      // *** AJUSTE: Garante que o Scaffold não tenha cor de fundo própria ***
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Container(
        // *** AJUSTE: Garante que o Container ocupe todo o espaço disponível ***
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: PoliedroFoodStyle.mainGradient, // Seu gradiente
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(PoliedroFoodStyle.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo e título
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: PoliedroFoodStyle.spacingXL),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'lib/images/poliedro_logo.svg', // Verifique o caminho
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
                        mainAxisSize: MainAxisSize.min,
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
                          TextButton(
                            style: PoliedroFoodStyle.textButtonStyle,
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                        context, '/admin-login');
                                  },
                            child: const Text('Acesso Administrativo'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Espaço extra no final para garantir que o último elemento
                // possa rolar completamente para cima do teclado, se necessário.
                const SizedBox(height: PoliedroFoodStyle.spacingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
