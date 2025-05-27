import 'package:chatbot/models/order_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for keyboard keys
import 'package:chatbot/config/style_guide.dart';
import 'package:chatbot/models/order.dart'; // Certifique-se que PoliedroOrder tem um campo DateTime createdAt
import 'package:chatbot/providers/order_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({Key? key}) : super(key: key);

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  int _selectedOrderIndex = 0; // Start with the first item selected
  bool _isLoading = true;
  List<PoliedroOrder> _orders = [];
  Stream<List<PoliedroOrder>>? _ordersStream;
  StreamSubscription<List<PoliedroOrder>>? _ordersSubscription;

  final FocusNode _listFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.authenticateKitchen(true);
      _loadOrders();
      FocusScope.of(context).requestFocus(_listFocusNode);
    });
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _listFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper function to get sorted pending orders
  List<PoliedroOrder> _getSortedPendingOrders() {
    final pending = _orders
        .where((order) => order.status == OrderStatus.pending.value)
        .toList();
    // Ordena do mais antigo para o mais recente (assuming createdAt exists)
    pending.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return pending;
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _selectedOrderIndex = 0;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      if (!orderProvider.isKitchenAuthenticated) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _orders = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Erro: Usuário da cozinha não está autenticado.'),
              backgroundColor: PoliedroFoodStyle.errorRed,
            ),
          );
        }
        return;
      }

      _ordersSubscription?.cancel();
      _ordersStream = orderProvider.getOrdersStream();

      _ordersSubscription = _ordersStream?.listen((orders) {
        if (mounted) {
          // Atualiza a lista principal
          _orders = orders;
          // Recalcula a lista ordenada de pendentes
          final sortedPendingOrders = _getSortedPendingOrders();

          setState(() {
            _isLoading = false;
            // Ajusta o índice selecionado baseado na nova lista ordenada
            if (_selectedOrderIndex >= sortedPendingOrders.length) {
              _selectedOrderIndex = sortedPendingOrders.isNotEmpty
                  ? sortedPendingOrders.length - 1
                  : -1;
            }
            if (sortedPendingOrders.isNotEmpty && _selectedOrderIndex < 0) {
              _selectedOrderIndex = 0;
            }
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToSelected();
          });
        }
      }, onError: (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _orders = [];
            _selectedOrderIndex = -1;
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
          _selectedOrderIndex = -1;
        });
        print('Erro ao carregar pedidos: $e');
      }
    }
  }

  Future<void> _confirmOrder(int index) async {
    // Usa a lista JÁ ORDENADA para pegar o pedido correto pelo índice
    final sortedPendingOrders = _getSortedPendingOrders();
    if (index < 0 || index >= sortedPendingOrders.length) return;

    final order = sortedPendingOrders[index];
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      print('Confirmando pedido ${order.id} com status atual: ${order.status}');
      await orderProvider.confirmOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pedido confirmado com sucesso!'),
            backgroundColor: PoliedroFoodStyle.neutralDark,
          ),
        );
        // Foca novamente na lista após a confirmação para continuar navegando
        FocusScope.of(context).requestFocus(_listFocusNode);
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

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Usa a lista JÁ ORDENADA para navegação
      final sortedPendingOrders = _getSortedPendingOrders();
      if (sortedPendingOrders.isEmpty) return;

      int newIndex = _selectedOrderIndex;

      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        newIndex = (_selectedOrderIndex + 1) % sortedPendingOrders.length;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        newIndex = (_selectedOrderIndex - 1 + sortedPendingOrders.length) %
            sortedPendingOrders.length;
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.select) {
        if (_selectedOrderIndex >= 0 &&
            _selectedOrderIndex < sortedPendingOrders.length) {
          _confirmOrder(_selectedOrderIndex);
        }
        return;
      }

      if (newIndex != _selectedOrderIndex) {
        setState(() {
          _selectedOrderIndex = newIndex;
        });
        _scrollToSelected();
      }
    }
  }

  void _scrollToSelected() {
    if (_selectedOrderIndex < 0 || !_scrollController.hasClients) return;
    const double itemHeight = 350.0; // Ajuste se necessário
    final offset = _selectedOrderIndex * itemHeight;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtém a lista de pedidos pendentes JÁ ORDENADA
    final sortedPendingOrders = _getSortedPendingOrders();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: PoliedroFoodStyle.primaryBlue,
        title: const Text('Cozinha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: PoliedroFoodStyle.white),
            onPressed: () {
              _listFocusNode.unfocus();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Focus(
        focusNode: _listFocusNode,
        onKeyEvent: (node, event) {
          _handleKeyEvent(event);
          return KeyEventResult.handled;
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : sortedPendingOrders.isEmpty
                ? const Center(child: Text('Nenhum pedido pendente.'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    // Usa a lista ordenada
                    itemCount: sortedPendingOrders.length,
                    itemBuilder: (context, index) {
                      // Pega o pedido da lista ordenada
                      final order = sortedPendingOrders[index];
                      // Passa o estado de seleção correto
                      return _buildOrderCard(
                          order, index, index == _selectedOrderIndex);
                    },
                  ),
      ),
    );
  }

  Widget _buildOrderCard(PoliedroOrder order, int index, bool isSelected) {
    double total =
        order.items.fold(0, (sum, item) => sum + (item.price * item.quantity));

    return Card(
      margin: const EdgeInsets.all(8.0),
      color: isSelected ? PoliedroFoodStyle.primaryBlue.withOpacity(0.1) : null,
      shape: isSelected
          ? RoundedRectangleBorder(
              side: const BorderSide(
                  color: PoliedroFoodStyle.primaryBlue, width: 2),
              borderRadius: BorderRadius.circular(4.0),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido #${order.orderNumber}',
                  style: PoliedroFoodStyle.headingMedium.copyWith(
                    color: PoliedroFoodStyle.neutralDark,
                  ),
                ),
                // Mostra a data formatada do pedido
                Text(
                  order
                      .formattedDate, // Ou use order.createdAt se precisar formatar aqui
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text('RA: ${order.user.ra.replaceAll("@p4ed.com.br", "")}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (order.user.phone.isNotEmpty)
              Text('Telefone: ${order.user.phone}'),
            const Divider(),
            if (order.notes.isNotEmpty) ...[
              Text('Observações:', style: PoliedroFoodStyle.subtitleLarge),
              Text(order.notes),
              const Divider(),
            ],
            Text('Itens:', style: PoliedroFoodStyle.subtitleLarge),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: PoliedroFoodStyle.subtitleLarge),
                Text('R\$ ${total.toStringAsFixed(2)}',
                    style: PoliedroFoodStyle.totalText),
              ],
            ),
            const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  focusNode: isSelected ? FocusNode(skipTraversal: true) : null,
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
}
