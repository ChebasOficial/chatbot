import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderHistoryTab extends StatefulWidget {
  const OrderHistoryTab({Key? key}) : super(key: key);

  @override
  State<OrderHistoryTab> createState() => _OrderHistoryTabState();
}

class _OrderHistoryTabState extends State<OrderHistoryTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _filterController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _allOrders = []; // Lista com todos os pedidos carregados
  List<Map<String, dynamic>> _filteredOrders = []; // Lista filtrada para exibição
  String _filterText = "";

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _filterController.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _filterController.removeListener(_onFilterChanged);
    _filterController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    setState(() {
      _filterText = _filterController.text.trim();
      _applyFilter();
    });
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('timestamp', descending: true)
          .get();

      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'orderNumber': data['orderNumber'] ?? 0,
          'userEmail': data['userEmail'] ?? 'Usuário desconhecido',
          'timestamp': data['timestamp'] as Timestamp?,
          'items': data['items'] as List<dynamic>? ?? [],
          'total': (data['total'] ?? 0).toDouble(),
        };
      }).toList();

      setState(() {
        _allOrders = orders;
        _applyFilter(); // Aplicar filtro inicial (se houver)
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar pedidos: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar pedidos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilter() {
    if (_filterText.isEmpty) {
      _filteredOrders = List.from(_allOrders);
    } else {
      _filteredOrders = _allOrders.where((order) {
        final ra = _extractRA(order['userEmail'] as String);
        return ra.toLowerCase().contains(_filterText.toLowerCase());
      }).toList();
    }
  }

  String _extractRA(String email) {
    final parts = email.split('@');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return 'RA desconhecido';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Campo de filtro
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _filterController,
            decoration: InputDecoration(
              labelText: 'Filtrar por RA',
              hintText: 'Digite o RA do aluno...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              suffixIcon: _filterText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _filterController.clear();
                      },
                    )
                  : null,
            ),
          ),
        ),
        // Lista de pedidos
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: _filteredOrders.isEmpty
                      ? Center(
                          child: Text(
                            _filterText.isEmpty
                                ? 'Nenhum pedido encontrado.'
                                : 'Nenhum pedido encontrado para o RA "$_filterText".',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            final timestamp = order['timestamp'] as Timestamp?;
                            final dateTime = timestamp?.toDate() ?? DateTime.now();
                            final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
                            final ra = _extractRA(order['userEmail'] as String);
                            final items = order['items'] as List<dynamic>;
                            final total = order['total'] as double;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Pedido #${(order['orderNumber'] as int).toString().padLeft(3, '0')}',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          formattedDate,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'RA: $ra',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    const Text(
                                      'Itens:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    ...items.map((item) {
                                      final name = item['name'] as String;
                                      final quantity = item['quantity'] as int;
                                      final price = (item['price'] as num).toDouble();
                                      final itemTotal = price * quantity;

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('$quantity x $name'),
                                            Text('R\$ ${itemTotal.toStringAsFixed(2)}'),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    const Divider(),
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
                                          'R\$ ${total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

