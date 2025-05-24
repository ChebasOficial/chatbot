import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/providers/menu_provider.dart';
import 'package:chatbot/providers/order_provider.dart';
import 'package:chatbot/screens/inicio_screen.dart';
import 'package:chatbot/screens/login/login_screen.dart';
import 'package:chatbot/screens/login/admin_login_screen.dart';
import 'package:chatbot/screens/chatbot/chatbot_screen.dart';
import 'package:chatbot/screens/admin/admin_screen.dart';
import 'package:chatbot/screens/kitchen/kitchen_screen.dart';
import 'package:chatbot/screens/confirmation_screen.dart';
import 'package:chatbot/utils/account_initializer.dart';
import 'package:chatbot/config/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // // Inicializar contas especiais (admin e cozinha) - REMOVIDO/COMENTADO
  // final accountInitializer = AccountInitializer();
  // await accountInitializer.initializeSpecialAccounts();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ChatbotAuthProvider _authProvider = ChatbotAuthProvider();
  final OrderProvider _orderProvider = OrderProvider();
  final MenuProvider _menuProvider = MenuProvider();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    try {
      // Inicializar providers em ordem
      await _authProvider.initialize();
      await _orderProvider.initialize();
      // Não chamar initialize no MenuProvider pois ele não tem esse método
      // O carregamento dos itens do menu é feito sob demanda
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Erro ao inicializar providers: $e');
      // Mesmo com erro, marcar como inicializado para não bloquear a UI
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar indicador de carregamento enquanto inicializa
    if (!_isInitialized) {
      return MaterialApp(
        title: 'Carregando...',
        theme: PoliedroTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Inicializando aplicativo...'),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _orderProvider),
        ChangeNotifierProvider.value(value: _menuProvider),
      ],
      child: MaterialApp(
        title: 'Chatbot Poliedro',
        theme: PoliedroTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const InicioScreen(),
          '/inicio': (context) => const InicioScreen(),
          '/login': (context) => const LoginScreen(),
          '/admin-login': (context) => const AdminLoginScreen(),
          '/chatbot': (context) => const ChatbotScreen(),
          '/admin': (context) => const AdminScreen(),
          '/kitchen': (context) => const KitchenScreen(),
          '/confirmation': (context) {
            // Obter argumentos da navegação, se disponíveis
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            
            // Usar valores dos argumentos ou valores padrão
            return ConfirmationScreen(
              title: args?['title'] ?? 'Pedido Confirmado!',
              message: args?['message'] ?? 'Seu pedido foi registrado com sucesso.',
              buttonText: args?['buttonText'] ?? 'Voltar',
              onConfirm: args?['onConfirm'] as VoidCallback? ?? 
                         (() => Navigator.of(context).pushReplacementNamed('/chatbot')),
            );
          },
        },
      ),
    );
  }
}
