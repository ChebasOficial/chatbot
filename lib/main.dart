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
import 'package:chatbot/utils/account_initializer.dart';
import 'package:chatbot/config/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar contas especiais (admin e cozinha)
  final accountInitializer = AccountInitializer();
  await accountInitializer.initializeSpecialAccounts();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatbotAuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
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
        },
      ),
    );
  }
}
