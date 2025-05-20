import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({Key? key}) : super(key: key);

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingOrders = [];
  int _selectedOrderIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadPendingOrders();
  }

  Future<void> _loadPendingOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'pendente')
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
          'description': data['description'] ?? '',
        };
      }).toList();

      setState(() {
        _pendingOrders = orders;
        _isLoading = false;
        _selectedOrderIndex = _pendingOrders.isNotEmpty ? 0 : -1;
      });
    } catch (e) {
      print('Erro ao carregar pedidos pendentes: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar pedidos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _extractRA(String email) {
    // Extrai o RA do email (assumindo que o email é no formato RA@dominio.com)
    final parts = email.split('@');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return 'RA desconhecido';
  }

  Future<void> _confirmOrder(int index) async {
    if (index < 0 || index >= _pendingOrders.length) return;

    final order = _pendingOrders[index];
    final orderId = order['id'] as String;

    setState(() {
      _isLoading = true;
    });

    try {
      // Atualizar o status do pedido para 'concluído'
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'concluido',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Remover o pedido da lista local
      setState(() {
        _pendingOrders.removeAt(index);
        _selectedOrderIndex = _pendingOrders.isNotEmpty ? 0 : -1;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido confirmado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Erro ao confirmar pedido: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao confirmar pedido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectPreviousOrder() {
    if (_pendingOrders.isEmpty) return;
    setState(() {
      _selectedOrderIndex = (_selectedOrderIndex - 1) % _pendingOrders.length;
      if (_selectedOrderIndex < 0) _selectedOrderIndex = _pendingOrders.length - 1;
    });
  }

  void _selectNextOrder() {
    if (_pendingOrders.isEmpty) return;
    setState(() {
      _selectedOrderIndex = (_selectedOrderIndex + 1) % _pendingOrders.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cozinha - Pedidos Pendentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingOrders,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingOrders.isEmpty
              ? const Center(
                  child: Text('Não há pedidos pendentes no momento.'),
                )
              : Column(
                  children: [
                    // Contador de pedidos pendentes
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.amber[100],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant, color: Colors.amber),
                          const SizedBox(width: 8.0),
                          Text(
                            'Pedidos pendentes: ${_pendingOrders.length}',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Navegação entre pedidos
                    if (_pendingOrders.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _selectPreviousOrder,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Anterior'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Text(
                              'Pedido ${_selectedOrderIndex + 1} de ${_pendingOrders.length}',
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            ElevatedButton.icon(
                              onPressed: _selectNextOrder,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Próximo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Detalhes do pedido selecionado
                    if (_selectedOrderIndex >= 0 && _selectedOrderIndex < _pendingOrders.length)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildSelectedOrderCard(),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildSelectedOrderCard() {
    final order = _pendingOrders[_selectedOrderIndex];
    final timestamp = order['timestamp'] as Timestamp?;
    final dateTime = timestamp?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    final ra = _extractRA(order['userEmail'] as String);
    final items = order['items'] as List<dynamic>;
    final total = order['total'] as double;
    final description = order['description'] as String;
    final orderNumber = (order['orderNumber'] as int).toString().padLeft(3, '0');

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: Colors.amber, width: 2.0),
      ),
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
                  'Pedido #$orderNumber',
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            
            // RA do aluno
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'RA: $ra',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Descrição do pedido (se houver)
            if (description.isNotEmpty) ...[
              const Text(
                'Descrição:',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.yellow[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.amber),
                ),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
            ],
            
            // Lista de itens
            const Text(
              'Itens:',
              style: TextStyle(
                fontSize: 16.0,
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
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$quantity x $name',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    Text(
                      'R\$ ${itemTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(thickness: 1.5),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'R\$ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            
            // Botão de confirmar pedido
            SizedBox(
              width: double.infinity,
              height: 50.0,
              child: ElevatedButton.icon(
                onPressed: () => _confirmOrder(_selectedOrderIndex),
                icon: const Icon(Icons.check_circle),
                label: const Text('CONFIRMAR PEDIDO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
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
