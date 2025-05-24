import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  @override
  void initState() {
    super.initState();
    
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar removida conforme solicitado
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Section (Logo)
              Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo do Poliedro
                  Column(
                    children: [
                      // Imagem removida conforme solicitado
                      const SizedBox(height: 16),
                      // Título removido conforme solicitado
                    ],
                  ),
                ],
              ),
              // Middle Section (Botão de Login)
              Column(
                children: [
                  Consumer<ChatbotAuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.isLoggedIn) {
                        if (authProvider.isAdminLoggedIn) {
                          return ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/admin');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Gerenciar Produtos',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          );
                        } else {
                          return ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/chatbot');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Acessar Chatbot',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          );
                        }
                      } else {
                        return ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          // Usando o estilo do tema Poliedro
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 60),
                          ),
                          child: const Text(
                            'Fazer Login',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        );
                      }
                    },
                  ),
                  // Removidas as informações abaixo do botão central de login
                ],
              ),
              // Espaço vazio para manter o layout equilibrado
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
