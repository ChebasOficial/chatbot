import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/models/chat_message.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/models/menu_item.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isTyping = false;
  List<MenuItem> _menuItems = [];
  bool _isLoadingMenu = true;
  Map<String, int> _cartItems = {};
  double _cartTotal = 0.0;
  
  // Cardápio de exemplo para fallback quando o Firestore falhar
  final List<MenuItem> _fallbackMenuItems = [
    MenuItem(
      id: '1',
      name: 'Hambúrguer Clássico',
      description: 'Pão, hambúrguer, queijo, alface, tomate e molho especial',
      price: 15.90,
      imageUrl: '',
      quantity: 10,
    ),
    MenuItem(
      id: '2',
      name: 'Batata Frita',
      description: 'Porção de batatas fritas crocantes',
      price: 8.50,
      imageUrl: '',
      quantity: 15,
    ),
    MenuItem(
      id: '3',
      name: 'Refrigerante',
      description: 'Lata 350ml (Coca-Cola, Guaraná ou Sprite)',
      price: 5.00,
      imageUrl: '',
      quantity: 20,
    ),
    MenuItem(
      id: '4',
      name: 'Salada Caesar',
      description: 'Alface, croutons, parmesão e molho caesar',
      price: 12.90,
      imageUrl: '',
      quantity: 8,
    ),
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Verificar se o usuário está logado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      
      // Carregar itens do cardápio
      _loadMenuItems();
      
      // Adicionar mensagem de boas-vindas
      _addBotMessage('Olá, ${authProvider.currentUser?.ra}! Bem-vindo ao Restaurante Escola Poliedro. Como posso ajudar você hoje?');
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMenuItems() async {
    setState(() {
      _isLoadingMenu = true;
    });
    
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
        _isLoadingMenu = false;
      });
    } catch (e) {
      print('Erro ao carregar itens do cardápio: $e');
      
      // Usar cardápio de fallback em caso de erro
      setState(() {
        _menuItems = _fallbackMenuItems;
        _isLoadingMenu = false;
      });
      
      // Mostrar mensagem de erro apenas no console, não para o usuário
      print('Usando cardápio de fallback devido a erro: $e');
    }
  }
  
  void _addUserMessage(String text) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });
    
    // Simular resposta do bot após 1 segundo
    Future.delayed(const Duration(seconds: 1), () {
      _processMessage(text);
      setState(() {
        _isTyping = false;
      });
    });
  }
  
  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }
  
  void _processMessage(String text) {
    final lowerText = text.toLowerCase();
    
    // Verificar saudações
    if (_containsAny(lowerText, ['olá', 'oi', 'bom dia', 'boa tarde', 'boa noite', 'ola', 'ei', 'e ai'])) {
      _addBotMessage('Olá! Como posso ajudar você hoje? Você pode pedir o cardápio ou fazer um pedido.');
      return;
    }
    
    // Verificar pedido de cardápio
    if (_containsAny(lowerText, ['cardápio', 'cardapio', 'menu', 'comida', 'opções', 'opcoes', 'o que tem', 'pratos'])) {
      _showMenuItems();
      return;
    }
    
    // Verificar preços
    if (_containsAny(lowerText, ['preço', 'preco', 'valor', 'quanto', 'custa', 'custo'])) {
      if (_menuItems.isEmpty) {
        _addBotMessage('Estou carregando os preços do cardápio. Por favor, aguarde um momento e tente novamente.');
        _loadMenuItems();
      } else {
        _showMenuItems();
      }
      return;
    }
    
    // Verificar intenção de pedido
    if (_detectOrderIntent(lowerText)) {
      _processOrderRequest(text);
      return;
    }
    
    // Verificar confirmação
    if (_containsAny(lowerText, ['confirmar', 'confirmo', 'sim', 'correto', 'certo', 'ok']) && 
        _messages.length > 1 && 
        _messages[_messages.length - 2].text.contains('Está correto?')) {
      _confirmOrder();
      return;
    }
    
    // Resposta padrão
    _addBotMessage('Desculpe, não entendi completamente. Como posso ajudar você? Você pode pedir o cardápio ou fazer um pedido.');
  }
  
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  bool _detectOrderIntent(String text) {
    // Palavras que indicam intenção de pedido
    final orderKeywords = [
      'quero', 'pedir', 'pedido', 'comprar', 'vou querer', 'me vê', 'me traz', 
      'gostaria', 'desejo', 'preciso', 'queria', 'pode me trazer', 'vou levar'
    ];
    
    // Verificar intenção de pedido
    if (_containsAny(text, orderKeywords)) {
      return true;
    }
    
    // Verificar se mencionou algum item do cardápio
    if (_menuItems.isNotEmpty) {
      for (var item in _menuItems) {
        if (text.toLowerCase().contains(item.name.toLowerCase())) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  void _processOrderRequest(String text) {
    // Limpar carrinho para novo pedido
    _cartItems.clear();
    _cartTotal = 0.0;
    
    // Identificar itens mencionados
    if (_menuItems.isEmpty) {
      _addBotMessage('Estou carregando o cardápio. Por favor, aguarde um momento e tente novamente.');
      _loadMenuItems();
      return;
    }
    
    bool foundItems = false;
    
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
        
        // Adicionar ao carrinho
        _cartItems[item.id] = quantity;
        _cartTotal += item.price * quantity;
        foundItems = true;
      }
    }
    
    if (foundItems) {
      // Mostrar resumo do pedido
      String orderSummary = 'Entendi seu pedido! Aqui está o resumo:\n\n';
      
      for (var entry in _cartItems.entries) {
        final item = _menuItems.firstWhere((i) => i.id == entry.key);
        orderSummary += '- ${entry.value}x ${item.name}: R\$ ${(item.price * entry.value).toStringAsFixed(2)}\n';
      }
      
      orderSummary += '\nTotal: R\$ ${_cartTotal.toStringAsFixed(2)}\n\n';
      orderSummary += 'Está correto? Se sim, digite "confirmar". Se não, você pode refazer o pedido.';
      
      _addBotMessage(orderSummary);
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
    
    final pedidoNumero = 10000 + (DateTime.now().millisecondsSinceEpoch % 90000);
    
    String confirmationMessage = 'Pedido #$pedidoNumero confirmado! Obrigado pela sua compra.\n\n';
    confirmationMessage += 'Resumo do pedido:\n';
    
    for (var entry in _cartItems.entries) {
      final item = _menuItems.firstWhere((i) => i.id == entry.key);
      confirmationMessage += '- ${entry.value}x ${item.name}: R\$ ${(item.price * entry.value).toStringAsFixed(2)}\n';
    }
    
    confirmationMessage += '\nTotal: R\$ ${_cartTotal.toStringAsFixed(2)}\n\n';
    confirmationMessage += 'Seu pedido estará pronto em aproximadamente 15 minutos.\n';
    confirmationMessage += 'Você pode retirá-lo no balcão do restaurante.\n\n';
    confirmationMessage += 'Deseja algo mais?';
    
    _addBotMessage(confirmationMessage);
    
    // Limpar carrinho após confirmação
    _cartItems.clear();
    _cartTotal = 0.0;
  }
  
  void _showMenuItems() {
    if (_isLoadingMenu) {
      _addBotMessage('Estou carregando o cardápio. Por favor, aguarde um momento...');
      return;
    }
    
    if (_menuItems.isEmpty) {
      _addBotMessage('Desculpe, não encontrei itens no cardápio. Por favor, tente novamente mais tarde.');
      return;
    }
    
    String menuText = 'Aqui está nosso cardápio:\n\n';
    
    for (var item in _menuItems) {
      menuText += '🍽️ ${item.name}\n';
      menuText += '   ${item.description}\n';
      menuText += '   R\$ ${item.price.toStringAsFixed(2)}\n';
      if (item.quantity <= 0) {
        menuText += '   ❌ Indisponível no momento\n';
      } else {
        menuText += '   ✅ Disponível\n';
      }
      menuText += '\n';
    }
    
    menuText += 'Para fazer um pedido, basta me dizer o que você deseja. Por exemplo: "Quero 1 ${_menuItems.first.name}"';
    
    _addBotMessage(menuText);
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<ChatbotAuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              try {
                // Fazer logout
                await authProvider.logout();
                
                // Redirecionar para a página inicial
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // Opções rápidas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildOptionButton('Cardápio', () {
                    _showMenuItems();
                  }),
                  const SizedBox(width: 8),
                  _buildOptionButton('Fazer Pedido', () {
                    _addBotMessage('Para fazer um pedido, por favor informe:\n1. O item que deseja pedir\n2. Quantidade\n\nExemplo: "Quero 1 ${_menuItems.isNotEmpty ? _menuItems.first.name : "item do cardápio"}"');
                  })
                ],
              ),
            ),
          ),
          
          // Campo de mensagem
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      _addUserMessage(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () {
                    _addUserMessage(_messageController.text);
                  },
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Construir bolha de mensagem
  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: !message.isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conteúdo da mensagem
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black,
              ),
            ),
            
            // Horário da mensagem
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: message.isUser
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Construir indicador de digitação
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            _buildDot(1),
            _buildDot(2),
          ],
        ),
      ),
    );
  }
  
  // Construir ponto do indicador de digitação
  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: AnimatedOpacity(
          opacity: 0.6,
          duration: const Duration(milliseconds: 300),
          child: Container(),
        ),
      ),
    );
  }
  
  // Construir botão de opção
  Widget _buildOptionButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: Text(text),
    );
  }
}
