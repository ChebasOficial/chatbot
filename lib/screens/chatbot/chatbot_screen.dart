import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/models/menu_item.dart';
import 'package:chatbot/models/chat_message.dart';
import 'package:chatbot/screens/confirmation_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  List<MenuItem> _menuItems = [];
  Map<String, int> _cartItems = {};
  double _cartTotal = 0.0;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Verificar se o usuário está logado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      
      // Mensagem de boas-vindas
      _addBotMessage('Olá! Bem-vindo ao chatbot da cantina. Como posso ajudar?');
      
      // Carregar itens do cardápio
      _loadMenuItems();
    });
  }
  
  Future<void> _loadMenuItems() async {
    try {
      final snapshot = await _firestore.collection('menu_items').get();
      
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return MenuItem(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          quantity: data['quantity'] ?? 0,
        );
      }).toList();
      
      setState(() {
        _menuItems = items;
      });
    } catch (e) {
      print('Erro ao carregar itens do cardápio: $e');
      _addBotMessage('Desculpe, não consegui carregar o cardápio. Por favor, tente novamente mais tarde.');
    }
  }
  
  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    
    // Rolar para o final da lista
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _addUserMessage(String text) {
    if (text.trim().isEmpty) {
      return;
    }
    
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _textController.clear();
    });
    
    // Rolar para o final da lista
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    // Processar mensagem do usuário
    _processUserMessage(text);
  }
  
  void _processUserMessage(String text) {
    final lowerText = text.toLowerCase();
    
    // Verificar se é uma confirmação de pedido
    if (lowerText.contains('confirmar')) {
      _confirmOrder();
      return;
    }
    
    // Verificar se é um pedido
    if (_isOrderRequest(lowerText)) {
      _processOrderRequest(text);
      return;
    }
    
    // Verificar se quer ver o cardápio
    if (lowerText.contains('cardápio') || lowerText.contains('cardapio') || lowerText.contains('menu')) {
      _showMenuItems();
      return;
    }
    
    // Resposta padrão
    _addBotMessage('Desculpe, não entendi. Você gostaria de ver o cardápio ou fazer um pedido?');
    
    // Mostrar opções
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Cardápio',
          isUser: false,
          timestamp: DateTime.now(),
          isButton: true,
          onButtonPressed: () {
            _showMenuItems();
          },
        ));
        
        _messages.add(ChatMessage(
          text: 'Fazer Pedido',
          isUser: false,
          timestamp: DateTime.now(),
          isButton: true,
          onButtonPressed: () {
            _addBotMessage('O que você gostaria de pedir hoje?');
          },
        ));
      });
    });
  }
  
  void _showMenuItems() {
    if (_menuItems.isEmpty) {
      _addBotMessage('Estou carregando o cardápio. Por favor, aguarde um momento e tente novamente.');
      _loadMenuItems();
      return;
    }
    
    String menuText = 'Aqui está nosso cardápio:\n\n';
    
    for (var item in _menuItems) {
      menuText += '${item.name} - R\$ ${item.price.toStringAsFixed(2)}\n${item.description}\n\n';
    }
    
    menuText += 'Para fazer um pedido, basta digitar o nome do item e a quantidade desejada. Por exemplo: "Quero 2 hambúrgueres".';
    
    _addBotMessage(menuText);
  }
  
  bool _isOrderRequest(String text) {
    // Verificar se o texto contém palavras relacionadas a pedidos
    final orderKeywords = [
      'quero',
      'pedir',
      'comprar',
      'adicionar',
      'adiciona',
      'gostaria',
    ];
    
    for (var keyword in orderKeywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    
    return false;
  }
  
  void _processOrderRequest(String text) {
    // Identificar itens mencionados
    if (_menuItems.isEmpty) {
      _addBotMessage('Estou carregando o cardápio. Por favor, aguarde um momento e tente novamente.');
      _loadMenuItems();
      return;
    }
    
    bool foundItems = false;
    Map<String, int> newItems = {};
    double newItemsTotal = 0.0;
    
    // Procurar por itens do cardápio no texto
    for (var item in _menuItems) {
      if (text.toLowerCase().contains(item.name.toLowerCase())) {
        // Tentar identificar quantidade
        int quantity = 1; // Padrão
        
        // Procurar por números antes do nome do item
        final regex = RegExp(r'(\d+)\s*' + item.name, caseSensitive: false);
        final match = regex.firstMatch(text);
        if (match != null && match.groupCount >= 1) {
          quantity = int.tryParse(match.group(1) ?? '1') ?? 1;
        }
        
        // Adicionar ao mapa temporário
        newItems[item.id] = quantity;
        newItemsTotal += item.price * quantity;
        foundItems = true;
      }
    }
    
    if (foundItems) {
      // Sempre acumular itens no carrinho existente
      for (var entry in newItems.entries) {
        if (_cartItems.containsKey(entry.key)) {
          // Se o item já existe no carrinho, somar a quantidade
          _cartItems[entry.key] = (_cartItems[entry.key] ?? 0) + entry.value;
        } else {
          // Se o item não existe no carrinho, adicionar
          _cartItems[entry.key] = entry.value;
        }
      }
      
      // Recalcular o total
      _cartTotal = 0.0;
      for (var entry in _cartItems.entries) {
        final item = _menuItems.firstWhere((i) => i.id == entry.key);
        _cartTotal += item.price * entry.value;
      }
      
      // Mostrar resumo do pedido
      String orderSummary = 'Entendi seu pedido! Aqui está o resumo:\n\n';
      
      for (var entry in _cartItems.entries) {
        final item = _menuItems.firstWhere((i) => i.id == entry.key);
        orderSummary += '- ${entry.value}x ${item.name}: R\$ ${(item.price * entry.value).toStringAsFixed(2)}\n';
      }
      
      orderSummary += '\nTotal: R\$ ${_cartTotal.toStringAsFixed(2)}\n\n';
      orderSummary += 'Está correto? Se sim, digite "confirmar". Se não, você pode refazer o pedido.';
      
      _addBotMessage(orderSummary);
      
      // Adicionar botão para adicionar mais itens após um breve atraso
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _messages.add(ChatMessage(
            text: 'adiciona mais',
            isUser: false,
            timestamp: DateTime.now(),
            isButton: true,
            onButtonPressed: () {
              _addUserMessage('adiciona mais');
            },
          ));
        });
      });
    } else {
      // Não encontrou itens específicos
      _addBotMessage('Entendi que você quer fazer um pedido, mas não identifiquei exatamente quais itens. Aqui está nosso cardápio:');
      _showMenuItems();
    }
  }
  
  void _confirmOrder() {
    if (_cartItems.isEmpty) {
      _addBotMessage('Não há itens no seu pedido atual. Por favor, faça um novo pedido.');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Obter dados do usuário logado
    final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
    final userEmail = authProvider.user?.email ?? 'usuario@exemplo.com';
    
    // Preparar itens do pedido para salvar no Firestore
    final List<Map<String, dynamic>> orderItems = [];
    
    for (var entry in _cartItems.entries) {
      final item = _menuItems.firstWhere((i) => i.id == entry.key);
      orderItems.add({
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'quantity': entry.value,
      });
    }
    
    // Dados do pedido
    final orderData = {
      'userEmail': userEmail,
      'timestamp': FieldValue.serverTimestamp(),
      'items': orderItems,
      'total': _cartTotal,
    };
    
    // Salvar pedido no Firestore
    _firestore.collection('orders').add(orderData).then((docRef) {
      final totalValue = _cartTotal; // Salvar o valor total antes de limpar o carrinho
      
      setState(() {
        _isLoading = false;
        _cartItems.clear();
        _cartTotal = 0.0;
      });
      
      // Adicionar mensagem de confirmação
      _addBotMessage('Pedido confirmado com sucesso! Obrigado pela sua compra.');
      
      // Navegar para a tela de confirmação
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationScreen(
            orderId: docRef.id,
            totalValue: totalValue,
          ),
        ),
      );
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      
      print('Erro ao confirmar pedido: $error');
      _addBotMessage('Ocorreu um erro ao confirmar seu pedido. Por favor, tente novamente.');
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot da Cantina'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              try {
                // Fazer logout
                await Provider.of<ChatbotAuthProvider>(context, listen: false).logout();
                
                // Redirecionar para a página de login
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
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
      body: Column(
        children: [
          // Lista de mensagens
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      
                      if (message.isButton) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ElevatedButton(
                              onPressed: message.onButtonPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Text(message.text),
                              ),
                            ),
                          ),
                        );
                      }
                      
                      return Align(
                        alignment: message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? Colors.grey[300]
                                : Colors.deepPurple[100],
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.text,
                                style: const TextStyle(fontSize: 16.0),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                DateFormat('HH:mm').format(message.timestamp),
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Campo de entrada de texto
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Campo de texto
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                    onSubmitted: (text) => _addUserMessage(text),
                  ),
                ),
                
                // Botão de enviar
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.deepPurple,
                  onPressed: () => _addUserMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
