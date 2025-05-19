import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// Import all screen files
import 'package:chatbot/screens/inicio_screen.dart';
import 'package:chatbot/screens/login_screen.dart';
import 'package:chatbot/screens/admin_login_screen.dart';
import 'package:chatbot/screens/cardapio_screen.dart';
import 'package:chatbot/screens/coluna_selection_screen.dart';
import 'package:chatbot/screens/confirmation_ok_screen.dart';
import 'package:chatbot/screens/linha_coluna_selection_screen.dart';
import 'package:chatbot/screens/yes_no_confirmation_screen.dart';
import 'package:chatbot/screens/contact_message_screen.dart';
import 'package:chatbot/screens/finalizacao_screen.dart';
import 'package:chatbot/screens/test_screen.dart';

// Import providers
import 'package:chatbot/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar o ChatbotAuthProvider
  final chatbotAuthProvider = ChatbotAuthProvider();
  await chatbotAuthProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => chatbotAuthProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      // Set InicioScreen as the initial route
      initialRoute: '/',
      // Define named routes for navigation
      routes: {
        '/': (context) => const InicioScreen(),
        '/login': (context) => const LoginScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/cardapio': (context) => const CardapioScreen(),
        '/coluna_selection': (context) => const ColunaSelectionScreen(),
        '/confirmation_ok': (context) => const ConfirmationOkScreen(),
        '/linha_coluna': (context) => const LinhaColunaSelectionScreen(),
        '/yes_no': (context) => const YesNoConfirmationScreen(),
        '/contact': (context) => const ContactMessageScreen(),
        '/finalizacao': (context) => const FinalizacaoScreen(),
        '/test': (context) => const TestScreen(),
      },
      // Adicionar observador de rotas para verificar autenticação
      navigatorObservers: [
        RouteObserver<PageRoute>(),
      ],
    );
  }
}

// Classe para verificar autenticação em rotas protegidas
class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool requireAdmin;

  const AuthGuard({
    Key? key,
    required this.child,
    this.requireAdmin = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<ChatbotAuthProvider>(context);

    // Verificar se o usuário está logado
    if (!authProvider.isLoggedIn) {
      // Redirecionar para a tela de login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Verificar se é necessário ser admin
    if (requireAdmin && !authProvider.isAdminLoggedIn) {
      // Redirecionar para a tela de login admin
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/admin-login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Se estiver autenticado, mostrar a tela
    return child;
  }
}
