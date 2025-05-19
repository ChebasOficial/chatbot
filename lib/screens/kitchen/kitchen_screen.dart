import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chatbot/models/order.dart';
import 'package:chatbot/models/order_status.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/providers/order_provider.dart';
import 'package:chatbot/widgets/custom_button.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({Key? key}) : super(key: key);

  @override
  State<KitchenScreen> createState() => KitchenScreenState();
}

class KitchenScreenState extends State<KitchenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Verificar se o administrador está logado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
      if (!authProvider.isAdminLoggedIn) {
        Navigator.pushReplacementNamed(context, '/admin-login');
        return;
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final pendingOrders = orderProvider.pendingOrders;
    final inProgressOrders = orderProvider.inProgressOrders;
    final completedOrders = orderProvider.completedOrders;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cozinha - Gerenciamento de Pedidos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendentes'),
            Tab(text: 'Em Preparo'),
            Tab(text: 'Concluídos'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              try {
                // Fazer logout
                await Provider.of<ChatbotAuthProvider>(context, listen: false).logout();
                
                // Redirecionar para a página inicial
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
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
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(pendingOrders, OrderStatus.pending),
          _buildOrderList(inProgressOrders, OrderStatus.inProgress),
          _buildOrderList(completedOrders, OrderStatus.completed),
        ],
      ),
    );
  }
  
  Widget _buildOrderList(List<Order> orders, OrderStatus status) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('Nenhum pedido nesta categoria.'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pedido #${order.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(order.timestamp),
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity}x ${item.name}'),
                      Text(
                        'R\$ ${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'R\$ ${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (order.notes.isNotEmpty) ...[
                  Text(
                    'Observações:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.notes,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _buildActionButtons(order, status),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  List<Widget> _buildActionButtons(Order order, OrderStatus status) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    switch (status) {
      case OrderStatus.pending:
        return [
          CustomButton(
            text: 'Iniciar Preparo',
            onPressed: () {
              orderProvider.updateOrderStatus(order.id, OrderStatus.inProgress);
            },
            backgroundColor: Colors.blue,
          ),
          CustomButton(
            text: 'Cancelar',
            onPressed: () {
              orderProvider.cancelOrder(order.id);
            },
            backgroundColor: Colors.red,
          ),
        ];
      case OrderStatus.inProgress:
        return [
          CustomButton(
            text: 'Concluir',
            onPressed: () {
              orderProvider.updateOrderStatus(order.id, OrderStatus.completed);
            },
            backgroundColor: Colors.green,
          ),
        ];
      case OrderStatus.completed:
        return [
          CustomButton(
            text: 'Arquivar',
            onPressed: () {
              orderProvider.archiveOrder(order.id);
            },
            backgroundColor: Colors.grey,
          ),
        ];
      default:
        return [];
    }
  }
}
