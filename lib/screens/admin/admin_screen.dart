import 'package:flutter/material.dart';
import 'package:chatbot/screens/admin/admin_products_screen.dart';
import 'package:chatbot/screens/admin/order_history_tab.dart';
import 'package:chatbot/config/style_guide.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
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
        backgroundColor: PoliedroFoodStyle.primaryBlue,
        title: const Text(
          'Painel Administrativo',
          style: TextStyle(
            color: PoliedroFoodStyle.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false, // Remove o botão de voltar
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: PoliedroFoodStyle.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: PoliedroFoodStyle.white,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: 'Produtos'),
            Tab(text: 'Histórico de Pedidos'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: PoliedroFoodStyle.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PoliedroFoodStyle.white,
              PoliedroFoodStyle.backgroundLight,
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: const [
            AdminProductsScreen(),
            OrderHistoryTab(),
          ],
        ),
      ),
    );
  }
}
