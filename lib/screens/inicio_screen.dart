import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatbot/screens/login_screen.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Poliedro Food', style: TextStyle(color: Colors.black)),
        actions: [
          // Botão de Logout no AppBar para maior visibilidade
          TextButton.icon(
            onPressed: () async {
              try {
                // Mostrar indicador de carregamento
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fazendo logout...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Fazer logout no provider
                final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
                await authProvider.logout();
                
                // Garantir que o Firebase Auth também faça logout
                await FirebaseAuth.instance.signOut();
                
                if (context.mounted) {
                  // Mostrar mensagem de sucesso
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logout realizado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Navegar para a tela de login usando pushNamed
                  // Isso mantém a tela inicial na pilha, permitindo voltar para ela
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => route.isFirst, // Mantém apenas a primeira rota (tela inicial)
                  );
                }
              } catch (e) {
                // Mostrar erro se ocorrer
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao fazer logout: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Section (Time and Logo)
              const Column(
                children: [
                  SizedBox(height: 20),
                  Text(
                    '04:28:21 PM', // Placeholder time
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  SizedBox(height: 20),
                  // Placeholder for Poliedro Food Logo
                  Column(
                    children: [
                      Icon(Icons.restaurant_menu,
                          size: 50, color: Colors.orange), // Placeholder logo
                      Text(
                        'Poliedro Food',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              // Middle Section (Buttons and Info)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to Login Screen usando push normal para manter a pilha
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Pedidos',
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Botão de Logout para Teste (grande e visível)
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          // Mostrar indicador de carregamento
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fazendo logout...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          
                          // Fazer logout no provider
                          final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
                          await authProvider.logout();
                          
                          // Garantir que o Firebase Auth também faça logout
                          await FirebaseAuth.instance.signOut();
                          
                          if (context.mounted) {
                            // Mostrar mensagem de sucesso
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logout realizado com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            
                            // Navegar para a tela de login usando pushNamedAndRemoveUntil
                            // Isso mantém a tela inicial na pilha, permitindo voltar para ela
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => route.isFirst, // Mantém apenas a primeira rota (tela inicial)
                            );
                          }
                        } catch (e) {
                          // Mostrar erro se ocorrer
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao fazer logout: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'LOGOUT (TESTE)',
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Placeholder for Weather/Info Card
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.wb_sunny,
                                color: Colors.orange, size: 30),
                            SizedBox(width: 10),
                            Text(
                              '16°',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Sábado, 12 Agosto',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text('São Caetano do Sul',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
      // Botão flutuante de logout para garantir visibilidade
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            // Fazer logout no provider
            final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
            await authProvider.logout();
            
            // Garantir que o Firebase Auth também faça logout
            await FirebaseAuth.instance.signOut();
            
            if (context.mounted) {
              // Navegar para a tela de login usando pushNamedAndRemoveUntil
              // Isso mantém a tela inicial na pilha, permitindo voltar para ela
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => route.isFirst, // Mantém apenas a primeira rota (tela inicial)
              );
            }
          } catch (e) {
            // Mostrar erro se ocorrer
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao fazer logout: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.logout),
        label: const Text('LOGOUT'),
      ),
    );
  }
}
