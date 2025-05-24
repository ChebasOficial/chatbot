import 'package:flutter/material.dart';
import 'package:chatbot/screens/admin/admin_products_screen.dart';
import 'package:chatbot/screens/admin/order_history_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        automaticallyImplyLeading: false, // Remove o botão de voltar
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Produtos'),
            Tab(text: 'Histórico de Pedidos'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdminProductsScreen(),
          OrderHistoryTab(),
        ],
      ),
    );
  }
}
