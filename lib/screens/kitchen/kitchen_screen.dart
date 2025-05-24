import 'package:flutter/material.dart';
import 'package:chatbot/config/style_guide.dart';
import 'package:chatbot/models/order.dart';
import 'package:chatbot/providers/order_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({Key? key}) : super(key: key);

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  int _selectedOrderIndex = -1;
  bool _isLoading = true;
  List<PoliedroOrder> _orders = [];
  Stream<List<PoliedroOrder>>? _ordersStream;
  StreamSubscription<List<PoliedroOrder>>? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    // Autenticar a cozinha ao iniciar a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.authenticateKitchen(true);
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      // Verificar se o usuário da cozinha está autenticado
      if (!orderProvider.isKitchenAuthenticated) {
        setState(() {
          _isLoading = false;
          _orders = [];
        });
        // Optionally show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro: Usuário da cozinha não está autenticado.'),
            backgroundColor: PoliedroFoodStyle.errorRed,
          ),
        );
      }
      // Cancel any existing subscription just in case
      _ordersSubscription?.cancel();
      
      // Get the stream of orders
      _ordersStream = orderProvider.getOrdersStream();
      
      // Subscribe to the stream
      _ordersSubscription = _ordersStream?.listen((orders) {
        if (mounted) {
          setState(() {
            _orders = orders;
            _isLoading = false;
          });
        }
      }, onError: (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _orders = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao carregar pedidos: ${e.toString()}'),
              backgroundColor: PoliedroFoodStyle.errorRed,
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'FECHAR',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                textColor: PoliedroFoodStyle.white,
              ),
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _orders = [];
        });
        print('Erro ao carregar pedidos: $e');
      }
    }
  }

  Future<void> _confirmOrder(int index) async {
    if (index < 0 || index >= _orders.length) return;
    
    final order = _orders[index];
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    try {
      await orderProvider.confirmOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pedido confirmado com sucesso!'),
            backgroundColor: PoliedroFoodStyle.neutralDark,
          ),
        );
      }
    } catch (e) {
      print('Erro ao confirmar pedido: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao confirmar pedido: $e'),
            backgroundColor: PoliedroFoodStyle.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove a seta de voltar
        backgroundColor: PoliedroFoodStyle.primaryBlue,
        title: const Text('Cozinha - Pedidos Pendentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: PoliedroFoodStyle.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('Nenhum pedido pendente.'))
              : Row(
                  children: [
                    // Lista de pedidos (lado esquerdo)
                    Expanded(
                      flex: 2,
                      child: ListView.builder(
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text('Pedido #${order.id}'),
                              subtitle: Text('RA: ${order.user.ra}'),
                              selected: index == _selectedOrderIndex,
                              selectedTileColor: PoliedroFoodStyle.backgroundLight,
                              onTap: () {
                                setState(() {
                                  _selectedOrderIndex = index;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    // Detalhes do pedido selecionado (lado direito)
                    Expanded(
                      flex: 3,
                      child: _selectedOrderIndex >= 0 && _selectedOrderIndex < _orders.length
                          ? _buildOrderDetails(_orders[_selectedOrderIndex])
                          : const Center(child: Text('Selecione um pedido para ver os detalhes.')),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOrderDetails(PoliedroOrder order) {
    // Calcular o total do pedido
    double total = 0;
    for (var item in order.items) {
      total += item.price * item.quantity;
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedido #${order.id}',
              style: PoliedroFoodStyle.headingMedium.copyWith(
                color: PoliedroFoodStyle.neutralDark,
              ),
            ),
            const SizedBox(height: 8.0),
            Text('RA: ${order.user.ra}'),
            Text('Telefone: ${order.user.phone}'),
            Text('Data: ${order.formattedDate}'),
            const Divider(),
            Text(
              'Descrição:',
              style: PoliedroFoodStyle.subtitleLarge,
            ),
            Text(order.description),
            const Divider(),
            Text(
              'Itens:',
              style: PoliedroFoodStyle.subtitleLarge,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('Quantidade: ${item.quantity}'),
                    trailing: Text(
                      'R\$ ${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: PoliedroFoodStyle.subtitleLarge,
                ),
                Text(
                  'R\$ ${total.toStringAsFixed(2)}',
                  style: PoliedroFoodStyle.totalText,
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmOrder(_selectedOrderIndex),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('CONFIRMAR PEDIDO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PoliedroFoodStyle.neutralDark,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
