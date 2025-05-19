import 'package:flutter/material.dart';
import 'package:chatbot/models/chat_message.dart';
import 'package:chatbot/models/menu_item.dart';
import 'package:chatbot/models/order.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/providers/order_provider.dart';
import 'package:chatbot/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  // Dados do cardápio
  final List<MenuItem> _menuItems = [
    MenuItem(
      id: '1',
      name: 'Prato Executivo',
      description: 'Arroz, feijão, salada e proteína do dia',
      price: 15.90,
    ),
    MenuItem(
      id: '2',
      name: 'Salada Caesar',
      description: 'Alface, croutons, frango e molho caesar',
      price: 12.50,
    ),
    MenuItem(
      id: '3',
      name: 'Sanduíche Natural',
      description: 'Pão integral, frango, alface, tomate e cenoura',
      price: 8.90,
    ),
    MenuItem(
      id: '4',
      name: 'Suco Natural',
      description: 'Laranja, maracujá ou abacaxi',
      price: 5.00,
    ),
    MenuItem(
      id: '5',
      name: 'Sobremesa do dia',
      description: 'Pudim ou mousse de chocolate',
      price: 6.50,
    ),
  ];
  
  // Promoções
  final List<MenuItem> _promotions = [
    MenuItem(
      id: '6',
      name: 'Combo Estudante',
      description: 'Prato executivo + suco + sobremesa',
      price: 22.90,
    ),
    MenuItem(
      id: '7',
      name: 'Combo Funcionário',
      description: 'Sanduíche + suco',
      price: 12.90,
    ),
  ];
  
  // Horário de funcionamento
  final Map<String, String> _schedule = {
    'diasUteis': 'Segunda a Sexta: 07:00 às 19:00',
    'sabados': 'Sábados: 08:00 às 14:00',
    'domingos': 'Fechado',
  };
  
  // Pedido atual
  Order? _currentOrder;

  @override
  void initState() {
    super.initState();
    
    // Verificar se o usuário está logado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      
      // Adicionar mensagem de boas-vindas
      _addBotMessage('Olá, ${authProvider.currentUser?.ra}! Bem-vindo ao Restaurante da Escola Palidro.\nComo posso ajudar você hoje?');
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Adicionar mensagem do bot
  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  // Adicionar mensagem do usuário
  void _addUserMessage(String text) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
    });
    _scrollToBottom();
    
    // Simular digitação do bot
    setState(() {
      _isTyping = true;
    });
    
    // Processar a mensagem após um delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isTyping = false;
      });
      _processMessage(text);
    });
  }

  // Processar a mensagem do usuário
  void _processMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Verificar se é uma confirmação de pedido
    if (lowerMessage.contains('confirmar') && _currentOrder != null) {
      _confirmOrder();
      return;
    }
    
    // Verificar o tipo de mensagem
    if (lowerMessage.contains('cardápio') || lowerMessage.contains('menu')) {
      _showMenu();
    } else if (lowerMessage.contains('promoção') || lowerMessage.contains('oferta')) {
      _showPromotions();
    } else if (lowerMessage.contains('horário') || lowerMessage.contains('funcionamento')) {
      _showSchedule();
    } else if (lowerMessage.contains('pedido') || lowerMessage.contains('pedir') || lowerMessage.contains('quero')) {
      _processOrder(message);
    } else {
      _addBotMessage('Desculpe, não entendi. Você pode escolher uma das opções abaixo ou perguntar sobre nosso cardápio, promoções ou horário de funcionamento.');
    }
  }

  // Mostrar cardápio
  void _showMenu() {
    String menuText = '<strong>📋 Cardápio do Restaurante:</strong>\n\n';
    
    for (var item in _menuItems) {
      menuText += '<strong>${item.name}</strong> - R\$ ${item.price.toStringAsFixed(2)}\n';
      menuText += '${item.description}\n\n';
    }
    
    _addBotMessage(menuText);
  }

  // Mostrar promoções
  void _showPromotions() {
    String promoText = '<strong>🎉 Promoções Especiais:</strong>\n\n';
    
    for (var promo in _promotions) {
      promoText += '<strong>${promo.name}</strong> - R\$ ${promo.price.toStringAsFixed(2)}\n';
      promoText += '${promo.description}\n\n';
    }
    
    _addBotMessage(promoText);
  }

  // Mostrar horário de funcionamento
  void _showSchedule() {
    String scheduleText = '<strong>⏰ Horário de Funcionamento:</strong>\n\n';
    scheduleText += '${_schedule['diasUteis']}\n';
    scheduleText += '${_schedule['sabados']}\n';
    scheduleText += '${_schedule['domingos']}';
    
    _addBotMessage(scheduleText);
  }

  // Processar pedido
  void _processOrder(String message) {
    // Inicializar novo pedido
    _currentOrder = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ra: Provider.of<AuthProvider>(context, listen: false).currentUser!.ra,
      timestamp: DateTime.now(),
      items: [],
      total: 0,
      status: 'pending',
    );
    
    // Analisar o pedido (simplificado para demonstração)
    if (message.toLowerCase().contains('prato executivo')) {
      final menuItem = _menuItems.firstWhere((item) => item.name == 'Prato Executivo');
      _currentOrder!.items.add(OrderItem(
        menuItem: menuItem,
        quantity: 1,
      ));
      _currentOrder!.total += menuItem.price;
    }
    
    if (message.toLowerCase().contains('salada caesar')) {
      final menuItem = _menuItems.firstWhere((item) => item.name == 'Salada Caesar');
      _currentOrder!.items.add(OrderItem(
        menuItem: menuItem,
        quantity: 1,
      ));
      _currentOrder!.total += menuItem.price;
    }
    
    if (message.toLowerCase().contains('sanduíche') || message.toLowerCase().contains('sanduiche')) {
      final menuItem = _menuItems.firstWhere((item) => item.name == 'Sanduíche Natural');
      _currentOrder!.items.add(OrderItem(
        menuItem: menuItem,
        quantity: 1,
      ));
      _currentOrder!.total += menuItem.price;
    }
    
    if (message.toLowerCase().contains('suco')) {
      final menuItem = _menuItems.firstWhere((item) => item.name == 'Suco Natural');
      _currentOrder!.items.add(OrderItem(
        menuItem: menuItem,
        quantity: 1,
      ));
      _currentOrder!.total += menuItem.price;
    }
    
    if (message.toLowerCase().contains('sobremesa')) {
      final menuItem = _menuItems.firstWhere((item) => item.name == 'Sobremesa do dia');
      _currentOrder!.items.add(OrderItem(
        menuItem: menuItem,
        quantity: 1,
      ));
      _currentOrder!.total += menuItem.price;
    }
    
    if (message.toLowerCase().contains('combo estudante')) {
      final menuItem = _promotions.firstWhere((item) => item.name == 'Combo Estudante');
      _currentOrder!.items.add(OrderItem(
        menuItem: menuItem,
        quantity: 1,
      ));
      _currentOrder!.total += menuItem.price;
    }
    
    if (message.toLowerCase().contains('combo funcionário') || message.toLowerCase().contains('combo funcionario')) {
      final menuItem = _promotions.firstWhere((item) => item.name == 'Combo Funcionário');
      _currentOrder!.items.add(OrderItem(
        menuItem: menuItem,
        quantity: 1,
      ));
      _currentOrder!.total += menuItem.price;
    }
    
    // Verificar se o pedido está vazio
    if (_currentOrder!.items.isEmpty) {
      _addBotMessage('Desculpe, não consegui identificar os itens do seu pedido. Por favor, tente novamente especificando os itens do cardápio.');
      _currentOrder = null;
      return;
    }
    
    // Formatar a mensagem de confirmação
    String confirmationMessage = 'Obrigado pelo seu pedido! Vou registrá-lo para você.\n\nPor favor, confirme os dados do seu pedido:\n\n';
    
    // Adicionar R.A.
    confirmationMessage += '<strong>R.A.:</strong> ${_currentOrder!.ra}\n\n';
    
    // Adicionar itens
    confirmationMessage += '<strong>Itens solicitados:</strong>\n';
    for (var item in _currentOrder!.items) {
      confirmationMessage += '- ${item.quantity}x ${item.menuItem.name}: R\$ ${(item.menuItem.price * item.quantity).toStringAsFixed(2)}\n';
    }
    
    // Adicionar total
    confirmationMessage += '\n<strong>Total: R\$ ${_currentOrder!.total.toStringAsFixed(2)}</strong>\n\n';
    
    confirmationMessage += 'Está correto? Se sim, digite "confirmar". Se não, você pode refazer o pedido.';
    
    _addBotMessage(confirmationMessage);
  }

  // Confirmar pedido
  void _confirmOrder() {
    if (_currentOrder == null) return;
    
    // Gerar ID único para o pedido
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentOrder!.id = orderId;
    
    // Salvar o pedido
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.addOrder(_currentOrder!);
    
    // Formatar mensagem de confirmação
    String confirmationMessage = '<strong>Pedido confirmado!</strong> Seu número de pedido é #${orderId.substring(orderId.length - 5)}.\n\n';
    confirmationMessage += '<strong>Resumo do pedido:</strong>\n';
    
    // Adicionar itens
    for (var item in _currentOrder!.items) {
      confirmationMessage += '- ${item.quantity}x ${item.menuItem.name}: R\$ ${(item.menuItem.price * item.quantity).toStringAsFixed(2)}\n';
    }
    
    // Adicionar total e instruções
    confirmationMessage += '\n<strong>Total: R\$ ${_currentOrder!.total.toStringAsFixed(2)}</strong>\n\n';
    confirmationMessage += 'Seu pedido estará pronto em aproximadamente 15 minutos.\n';
    confirmationMessage += 'Você pode retirá-lo no balcão do restaurante.\n\n';
    confirmationMessage += 'Deseja algo mais?';
    
    _addBotMessage(confirmationMessage);
    
    // Resetar o pedido atual
    _currentOrder = null;
  }

  // Rolar para o final da lista de mensagens
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Restaurante Escola Palidro'),
            if (authProvider.currentUser != null)
              Text(
                authProvider.currentUser!.ra,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de mensagens
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                // Indicador de digitação
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                
                // Mensagem normal
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Opções rápidas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildOptionButton('Ver Cardápio', () => _showMenu()),
                  const SizedBox(width: 8),
                  _buildOptionButton('Promoções', () => _showPromotions()),
                  const SizedBox(width: 8),
                  _buildOptionButton('Horário de Funcionamento', () => _showSchedule()),
                  const SizedBox(width: 8),
                  _buildOptionButton('Fazer Pedido', () {
                    _addBotMessage('Para fazer um pedido, por favor informe:\n1. O item que deseja pedir\n2. Quantidade\n3. Observações (se houver)\n\nExemplo: "Quero 1 Prato Executivo e 1 Suco de Laranja"');
                  }),
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
