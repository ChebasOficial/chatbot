import 'package:chatbot/models/order_status.dart';
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
            content:
                const Text('Erro: Usuário da cozinha não está autenticado.'),
            backgroundColor: PoliedroFoodStyle.errorRed,
          ),
        );
        return; // Importante: retornar aqui para evitar continuar o carregamento
      }

      // Cancel any existing subscription just in case
      _ordersSubscription?.cancel();

      print('KitchenScreen: Iniciando carregamento de pedidos');

      // Get the stream of orders
      _ordersStream = orderProvider.getOrdersStream();

      // Subscribe to the stream
      _ordersSubscription = _ordersStream?.listen((orders) {
        if (mounted) {
          print('KitchenScreen: Recebidos ${orders.length} pedidos do stream');
          final pendingOrders = orders
              .where((order) => order.status == OrderStatus.pending.value)
              .toList();
          print(
              'KitchenScreen: Filtrados ${pendingOrders.length} pedidos pendentes');

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
    // Usar a lista filtrada de pedidos pendentes
    final pendingOrders = _orders
        .where((order) => order.status == OrderStatus.pending.value)
        .toList();
    if (index < 0 || index >= pendingOrders.length) return;

    final order = pendingOrders[index];
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      print('Confirmando pedido ${order.id} com status atual: ${order.status}');
      await orderProvider.confirmOrder(order.id);

      // Forçar atualização da lista após confirmação
      setState(() {
        // A lista será atualizada automaticamente pelo stream
      });

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
    // Filtrar apenas pedidos pendentes
    final pendingOrders = _orders
        .where((order) => order.status == OrderStatus.pending.value)
        .toList();

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
          : pendingOrders.isEmpty
              ? const Center(child: Text('Nenhum pedido pendente.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: pendingOrders.length,
                  itemBuilder: (context, index) {
                    final order = pendingOrders[index];
                    return _buildOrderCard(order, index);
                  },
                ),
    );
  }

  Widget _buildOrderCard(PoliedroOrder order, int index) {
    // Calcular o total do pedido
    double total = 0;
    for (var item in order.items) {
      total += item.price * item.quantity;
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do pedido
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido #${order.orderNumber}',
                  style: PoliedroFoodStyle.headingMedium.copyWith(
                    color: PoliedroFoodStyle.neutralDark,
                  ),
                ),
                Text(
                  order.formattedDate,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),

            // Informações do cliente
            Text('RA: ${order.user.ra}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (order.user.phone.isNotEmpty)
              Text('Telefone: ${order.user.phone}'),
            const Divider(),

            // Descrição/Observações
            if (order.notes.isNotEmpty) ...[
              Text(
                'Observações:',
                style: PoliedroFoodStyle.subtitleLarge,
              ),
              Text(order.notes),
              const Divider(),
            ],

            // Lista de itens
            Text(
              'Itens:',
              style: PoliedroFoodStyle.subtitleLarge,
            ),
            const SizedBox(height: 8.0),
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.quantity}x ${item.name}')),
                    Text(
                      'R\$ ${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(),

            // Total
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
            const SizedBox(height: 16.0),

            // Botão de confirmar
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmOrder(index),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('CONFIRMAR PEDIDO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PoliedroFoodStyle.neutralDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mantido para compatibilidade, mas não usado mais diretamente
  Widget _buildOrderDetails(PoliedroOrder order) {
    return Container(); // Método vazio, não usado mais
  }
}
