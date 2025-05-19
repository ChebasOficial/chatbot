import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/providers/menu_provider.dart';
import 'package:chatbot/screens/admin/admin_products_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MenuProvider(),
      child: const AdminProductsScreen(),
    );
  }
}
