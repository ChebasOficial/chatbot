import 'package:flutter/material.dart';
import 'package:chatbot/models/order.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/providers/order_provider.dart';
import 'package:chatbot/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
    
    // Verificar se o administrador está logado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAdminLoggedIn) {
        Navigator.pushReplacementNamed(context, '/admin-login');
        return;
      }
      
      // Carregar pedidos
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.initialize();
    });
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
        title: const Text('Painel da Cozinha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/admin-login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Pendentes',
            ),
            Tab(
              icon: Icon(Icons.restaurant),
              text: 'Em Preparo',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Concluídos',
            ),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          return Column(
            children: [
              // Resumo financeiro
              _buildFinancialSummary(orderProvider),
              
              // Lista de pedidos
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Pedidos pendentes
                    _buildOrdersList(
                      orderProvider.pendingOrders,
                      'Nenhum pedido pendente no momento.',
                      (order) => _buildOrderCard(
                        order,
                        [
                          CustomButton(
                            text: 'Em Preparo',
                            backgroundColor: Colors.blue,
                            onPressed: () {
                              orderProvider.updateOrderStatus(order.id, 'preparing');
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Pedidos em preparo
                    _buildOrdersList(
                      orderProvider.preparingOrders,
                      'Nenhum pedido em preparo no momento.',
                      (order) => _buildOrderCard(
                        order,
                        [
                          CustomButton(
                            text: 'Concluído',
                            backgroundColor: Colors.green,
                            onPressed: () {
                              orderProvider.updateOrderStatus(order.id, 'completed');
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Pedidos concluídos
                    _buildOrdersList(
                      orderProvider.completedOrders,
                      'Nenhum pedido concluído no momento.',
                      (order) => _buildOrderCard(order, []),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Construir resumo financeiro
  Widget _buildFinancialSummary(OrderProvider orderProvider) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Resumo Financeiro',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pedidos Pendentes:'),
                Text(currencyFormat.format(orderProvider.pendingTotal)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pedidos Em Preparo:'),
                Text(currencyFormat.format(orderProvider.preparingTotal)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pedidos Concluídos:'),
                Text(currencyFormat.format(orderProvider.completedTotal)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total do Dia:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  currencyFormat.format(orderProvider.dayTotal),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Construir lista de pedidos
  Widget _buildOrdersList(
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
