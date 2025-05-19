import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chatbot/models/order.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/providers/order_provider.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({Key? key}) : super(key: key);

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Cozinha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                // Fazer logout no provider
                final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
                await authProvider.logout();
                
                if (context.mounted) {
                  // Navegar para a tela de login
                  Navigator.pushReplacementNamed(context, '/admin-login');
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendentes'),
            Tab(text: 'Em Preparo'),
            Tab(text: 'Concluídos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pedidos pendentes
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              final pendingOrders = orderProvider.orders
                  .where((order) => order.status == OrderStatus.pending)
                  .toList();
              
              return _buildOrderList(
                pendingOrders,
                'Nenhum pedido pendente',
                (order) => _buildOrderCard(
                  order,
                  [
                    ElevatedButton(
                      onPressed: () {
                        orderProvider.updateOrderStatus(
                          order.id,
                          OrderStatus.preparing,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Iniciar Preparo'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        orderProvider.updateOrderStatus(
                          order.id,
                          OrderStatus.cancelled,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Pedidos em preparo
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              final preparingOrders = orderProvider.orders
                  .where((order) => order.status == OrderStatus.preparing)
                  .toList();
              
              return _buildOrderList(
                preparingOrders,
                'Nenhum pedido em preparo',
                (order) => _buildOrderCard(
                  order,
                  [
                    ElevatedButton(
                      onPressed: () {
                        orderProvider.updateOrderStatus(
                          order.id,
                          OrderStatus.completed,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Concluir'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Pedidos concluídos
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              final completedOrders = orderProvider.orders
                  .where((order) => 
                      order.status == OrderStatus.completed || 
                      order.status == OrderStatus.cancelled)
                  .toList();
              
              return _buildOrderList(
                completedOrders,
                'Nenhum pedido concluído',
                (order) => _buildOrderCard(
                  order,
                  [],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // Construir lista de pedidos
  Widget _buildOrderList(
    List<Order> orders,
    String emptyMessage,
    Widget Function(Order) itemBuilder,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return itemBuilder(order);
      },
    );
  }
  
  // Construir cartão de pedido
  Widget _buildOrderCard(Order order, List<Widget> actions) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do pedido
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido #${order.id.substring(order.id.length - 5)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateFormat.format(order.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Detalhes do pedido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // R.A. do cliente
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      order.ra,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Itens do pedido
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity}x ${item.menuItem.name}'),
                      Text(currencyFormat.format(item.total)),
                    ],
                  ),
                )),
                
                // Total
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currencyFormat.format(order.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Ações
          if (actions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions.map((action) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: action,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
