import 'package:flutter/material.dart';
import 'package:chatbot/config/style_guide.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configurar animações
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));
    
    // Iniciar animação
    _controller.forward();
    
    // Verificar autenticação e redirecionar para a tela apropriada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
      
      if (authProvider.isLoggedIn) {
        if (authProvider.isAdminLoggedIn) {
          // Se for admin, ir para a tela de gerenciamento
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          // Se for aluno, ir para a tela de chatbot
          Navigator.pushReplacementNamed(context, '/chatbot');
        }
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: PoliedroFoodStyle.white,
      body: SafeArea(
        child: Container(
          decoration: PoliedroFoodStyle.gradientContainerDecoration,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Section (Logo e Título)
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: PoliedroFoodStyle.spacingXXL),
                        // Logo do Poliedro em SVG para alta qualidade
                        SvgPicture.asset(
                          'lib/images/poliedro_logo.svg',
                          height: screenSize.height * 0.15,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: PoliedroFoodStyle.spacingL),
                        // Título do App
                        const Text(
                          'Poliedro Food',
                          style: PoliedroFoodStyle.headingLarge,
                        ),
                        const SizedBox(height: PoliedroFoodStyle.spacingS),
                        // Subtítulo
                        const Text(
                          'Seu pedido a um clique de distância',
                          textAlign: TextAlign.center,
                          style: PoliedroFoodStyle.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Middle Section (Botão de Login)
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Column(
                    children: [
                      Consumer<ChatbotAuthProvider>(
                        builder: (context, authProvider, child) {
                          if (authProvider.isLoggedIn) {
                            if (authProvider.isAdminLoggedIn) {
                              return ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, '/admin');
                                },
                                style: PoliedroFoodStyle.primaryButtonStyle,
                                child: const Text('Gerenciar Produtos'),
                              );
                            } else {
                              return ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, '/chatbot');
                                },
                                style: PoliedroFoodStyle.primaryButtonStyle,
                                child: const Text('Acessar Chatbot'),
                              );
                            }
                          } else {
                            return Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(PoliedroFoodStyle.radiusM),
                                    boxShadow: PoliedroFoodStyle.shadowMedium,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/login');
                                    },
                                    style: PoliedroFoodStyle.primaryButtonStyle,
                                    child: const Text('Fazer Login'),
                                  ),
                                ),
                                const SizedBox(height: PoliedroFoodStyle.spacingM),
                                const Text(
                                  'Faça login para acessar o cardápio e realizar pedidos',
                                  textAlign: TextAlign.center,
                                  style: PoliedroFoodStyle.bodySmall,
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                
                // Bottom Section (Rodapé)
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: PoliedroFoodStyle.spacingM),
                      Text(
                        '© ${DateTime.now().year} Poliedro',
                        style: PoliedroFoodStyle.caption,
                      ),
                    ],
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
