import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';

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
  StreamSubscription<QuerySnapshot>? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    // Usar stream em vez de chamada única para atualização automática
    _setupOrdersStream();
  }

  @override
  void dispose() {
    // Cancelar a assinatura ao destruir o widget
    _ordersSubscription?.cancel();
    super.dispose();
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

  void _setupOrdersStream() {
    setState(() {
      _isLoading = true;
    });

    // Get auth provider instance
    final authProvider =
        Provider.of<ChatbotAuthProvider>(context, listen: false);

    // Check if kitchen user is logged in BEFORE attempting to fetch data
    if (!authProvider.isKitchenLoggedIn) {
      print('Kitchen user not logged in. Aborting order fetch.');
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading indicator
          _pendingOrders = []; // Clear any old orders
          _selectedOrderIndex = -1;
        });
        // Optionally show a message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: Usuário da cozinha não está autenticado.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Cancel any existing subscription just in case
      _ordersSubscription?.cancel();
      _ordersSubscription = null;
      return; // Stop execution if not logged in
    }

    // Proceed with fetching if logged in
    // Cancel previous subscription if exists before creating a new one
    _ordersSubscription?.cancel();

    // Configurar stream para atualização em tempo real
    _ordersSubscription = _firestore
        .collection("orders")
        .where("status", isEqualTo: "pending")
        .orderBy("timestamp", descending: false)
        .snapshots()
        .listen((snapshot) {
      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        // Tratamento de nulos e tipos para todos os campos relevantes
        final orderNumber = _parseOrderNumber(data['orderNumber']);
        final userEmail = (data['userEmail'] as String?) ?? '';
        final timestamp = data['timestamp'] as Timestamp?;
        final itemsData = (data['items'] as List<dynamic>?) ?? [];
        final total = (data['total'] as num?)?.toDouble() ?? 0.0;
        final description = (data['description'] as String?) ?? '';

        // Mapear itens com tratamento de nulos interno
        final items = itemsData.map((itemData) {
          final itemMap = itemData as Map<String, dynamic>? ?? {};
          return {
            'name': (itemMap['name'] as String?) ?? 'Item desconhecido',
            'quantity': (itemMap['quantity'] as int?) ?? 0,
            'price': (itemMap['price'] as num?)?.toDouble() ?? 0.0,
          };
        }).toList();

        return {
          'id': doc.id,
          'orderNumber': orderNumber,
          'userEmail': userEmail,
          'timestamp': timestamp,
          'items': items,
          'total': total,
          'description': description,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _pendingOrders = orders;
          _isLoading = false;
          // Lógica corrigida para selecionar o primeiro pedido se necessário
          if (_pendingOrders.isNotEmpty) {
            // Se há pedidos
            if (_selectedOrderIndex < 0 ||
                _selectedOrderIndex >= _pendingOrders.length) {
              // Se o índice era inválido (-1) ou ficou fora dos limites, seleciona o primeiro (0)
              _selectedOrderIndex = 0;
            }
            // Se o índice já era válido e continua dentro dos limites, ele é mantido
          } else {
            // Se não há pedidos
            _selectedOrderIndex = -1; // Garante que o índice seja -1
          }
        });
      }
    }, onError: (e) {
      print('Erro ao carregar pedidos pendentes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar pedidos: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'FECHAR',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    });
  }

  // Função segura para extrair RA do email
  String _extractRA(String? email) {
    if (email == null || email.isEmpty || !email.contains('@')) {
      return 'RA N/A'; // Retornar valor padrão se email for inválido
    }
    return email.split('@')[0];
  }

  Future<void> _confirmOrder(int index) async {
    if (index < 0 || index >= _pendingOrders.length) return;

    final order = _pendingOrders[index];
    final orderId = order['id'] as String;

    setState(() {
      _isLoading = true;
    });

    try {
      // Atualizar o status do pedido para 'concluido'
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'concluido',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // A atualização da lista será feita automaticamente pelo stream
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido confirmado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erro ao confirmar pedido: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao confirmar pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectPreviousOrder() {
    if (_pendingOrders.isEmpty) return;
    setState(() {
      _selectedOrderIndex = (_selectedOrderIndex - 1);
      if (_selectedOrderIndex < 0)
        _selectedOrderIndex = _pendingOrders.length - 1;
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
        automaticallyImplyLeading: false, // Remove o botão de voltar
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _setupOrdersStream, // Usar o método de stream para atualização manual também
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // 1. Cancelar a assinatura do stream PRIMEIRO
              _ordersSubscription?.cancel();
              _ordersSubscription =
                  null; // Garantir que a referência seja limpa

              // 2. Fazer o logout
              await Provider.of<ChatbotAuthProvider>(context, listen: false)
                  .logout();

              // 3. Navegar (verificando se o widget ainda está montado)
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
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
              : SingleChildScrollView(
                  // Simplificado: Remove Column e Expanded
                  padding: const EdgeInsets.all(16.0),
                  child: _selectedOrderIndex >= 0 &&
                          _selectedOrderIndex < _pendingOrders.length
                      ? Container(
                          // <--- Envolver com Container
                          constraints: const BoxConstraints(
                              maxWidth: 600), // Define largura máxima
                          child: _buildSelectedOrderCard(),
                        ) // Mostra o card diretamente dentro do Container
                      : const Center(
                          child: Text(
                              "Nenhum pedido selecionado ou disponível.")), // Mensagem se não houver pedido
                ),
    );
  }

  Widget _buildSelectedOrderCard() {
    final order = _pendingOrders[_selectedOrderIndex];

    // Acessar dados com segurança usando valores padrão definidos no _loadPendingOrders
    final orderNumber =
        order['orderNumber'] as int; // Já tratado pela função _parseOrderNumber
    final timestamp = order['timestamp'] as Timestamp?;
    final dateTime = timestamp?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    final email = order['userEmail'] as String; // Já tratado
    final ra = _extractRA(email);
    final items = order['items'] as List<Map<String, dynamic>>; // Já tratado
    final total = order['total'] as double; // Já tratado
    final description = order['description'] as String; // Já tratado
    final formattedOrderNumber =
        orderNumber.toString().padLeft(3, '0'); // Formatar número

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
                  'Pedido #$formattedOrderNumber', // Usar número formatado
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
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
              // Acessar dados do item com segurança
              final name = item['name'] as String; // Já tratado
              final quantity = item['quantity'] as int; // Já tratado
              final price = item['price'] as double; // Já tratado
              final itemTotal = price * quantity;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      // <--- Adicionar Flexible
                      child: Text(
                        '$quantity x $name',
                        style: const TextStyle(fontSize: 16.0),
                        overflow: TextOverflow
                            .ellipsis, // Adicionado para evitar overflow
                      ),
                    ), // <--- Fechar Flexible
                    const SizedBox(width: 8),
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
            Align(
              // <--- Envolver com Align
              alignment: Alignment.center, // Alinha o botão no centro
              child: SizedBox(
                // width: double.infinity, // Mantém comentado/removido
                height: 50.0,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmOrder(_selectedOrderIndex),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('CONFIRMAR PEDIDO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ), // <--- Fechar Align
          ],
        ),
      ),
    );
  }
}
