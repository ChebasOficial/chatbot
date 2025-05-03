import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import all screen files
import 'package:chatbot/screens/inicio_screen.dart';
import 'package:chatbot/screens/login_screen.dart';
import 'package:chatbot/screens/cardapio_screen.dart';
import 'package:chatbot/screens/coluna_selection_screen.dart';
import 'package:chatbot/screens/confirmation_ok_screen.dart';
import 'package:chatbot/screens/linha_coluna_selection_screen.dart';
import 'package:chatbot/screens/yes_no_confirmation_screen.dart';
import 'package:chatbot/screens/contact_message_screen.dart';
import 'package:chatbot/screens/finalizacao_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
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
        '/cardapio': (context) => const CardapioScreen(),
        '/coluna_selection': (context) => const ColunaSelectionScreen(),
        '/confirmation_ok': (context) => const ConfirmationOkScreen(),
        '/linha_coluna': (context) => const LinhaColunaSelectionScreen(),
        '/yes_no': (context) => const YesNoConfirmationScreen(),
        '/contact': (context) => const ContactMessageScreen(),
        '/finalizacao': (context) => const FinalizacaoScreen(),
      },
    );
  }
}

