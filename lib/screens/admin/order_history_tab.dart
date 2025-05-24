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

  // Função segura para ler orderNumber (aceita int ou String)
  int _parseOrderNumber(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Função segura para converter timestamp para DateTime
  DateTime _parseTimestamp(dynamic timestampData) {
    if (timestampData == null) {
      return DateTime.now();
    } else if (timestampData is Timestamp) {
      return timestampData.toDate();
    } else if (timestampData is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestampData);
    } else if (timestampData is String) {
      try {
        return DateTime.parse(timestampData);
      } catch (e) {
        print('Erro ao converter timestamp string: $e');
        return DateTime.now();
      }
    } else {
      print('Tipo de timestamp desconhecido: ${timestampData.runtimeType}');
      return DateTime.now();
    }
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
        // Tratamento de nulos e tipos para todos os campos relevantes
        final orderNumber = _parseOrderNumber(data['orderNumber']); // Usar função segura
        final userEmail = (data['ra'] as String?) ?? ''; // Usar RA em vez de email
        final timestampData = data['timestamp']; // Obter o timestamp sem cast
        final DateTime dateTime = _parseTimestamp(timestampData); // Converter com segurança
        final itemsData = (data['items'] as List<dynamic>?) ?? [];
        final total = (data['total'] as num?)?.toDouble() ?? 0.0;
        final description = (data['notes'] as String?) ?? ''; // Usar notes em vez de description

        // Mapear itens com tratamento de nulos interno e estrutura aninhada
        final items = itemsData.map((itemData) {
          final itemMap = itemData as Map<String, dynamic>? ?? {};
          final quantity = itemMap['quantity'] as int? ?? 0;
          
          // Verificar se existe o objeto menuItem aninhado
          final menuItemMap = itemMap['menuItem'] as Map<String, dynamic>? ?? {};
          final name = (menuItemMap['name'] as String?) ?? 'Item desconhecido';
          final price = (menuItemMap['price'] as num?)?.toDouble() ?? 0.0;
          
          return {
            'name': name,
            'quantity': quantity,
            'price': price,
          };
        }).toList();

        return {
          'id': doc.id,
          'orderNumber': orderNumber,
          'userEmail': userEmail, // Usar RA como email
          'timestamp': dateTime, // Usar DateTime já convertido
          'items': items,
          'total': total,
          'description': description, // Salvar descrição
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
        // Acessar userEmail com segurança
        final email = order['userEmail'] as String? ?? '';
        final ra = _extractRA(email);
        return ra.toLowerCase().contains(_filterText.toLowerCase());
      }).toList();
    }
  }

  // Função segura para extrair RA do email
  String _extractRA(String? email) {
    if (email == null || email.isEmpty || !email.contains('@')) {
      return 'RA N/A'; // Retornar valor padrão se email for inválido
    }
    return email.split('@')[0];
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

                            // Acessar dados com segurança usando valores padrão definidos no _loadOrders
                            final orderNumber = order['orderNumber'] as int; // Já tratado
                            final dateTime = order['timestamp'] as DateTime; // Já convertido para DateTime
                            final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
                            final email = order['userEmail'] as String; // Já tratado
                            final ra = _extractRA(email);
                            final items = order['items'] as List<Map<String, dynamic>>; // Já tratado
                            final total = order['total'] as double; // Já tratado
                            final description = order['description'] as String; // Já tratado

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
                                          // Formatar número do pedido
                                          'Pedido #${orderNumber.toString().padLeft(3, '0')}',
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
                                      // Acessar dados do item com segurança
                                      final name = item['name'] as String; // Já tratado
                                      final quantity = item['quantity'] as int; // Já tratado
                                      final price = item['price'] as double; // Já tratado
                                      final itemTotal = price * quantity;

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: Text('$quantity x $name')),
                                            const SizedBox(width: 8),
                                            Text('R\$ ${itemTotal.toStringAsFixed(2)}'),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    // Exibir descrição se houver
                                    if (description.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text('Observação: $description'),
                                      ),
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
                                            color: Colors.blue,
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

