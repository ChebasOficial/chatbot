import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/models/chat_message.dart';
import 'package:chatbot/providers/auth_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    // Verificar se o usuário está logado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider =
          Provider.of<ChatbotAuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      // Adicionar mensagem de boas-vindas
      _addBotMessage(
          'Olá, ${authProvider.currentUser?.ra}! Bem-vindo ao Restaurante Escola Poliedro. Como posso ajudar você hoje?');
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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

    if (lowerText.contains('olá') ||
        lowerText.contains('oi') ||
        lowerText.contains('bom dia') ||
        lowerText.contains('boa tarde')) {
      _addBotMessage('Olá! Como posso ajudar você hoje?');
    } else if (lowerText.contains('cardápio') ||
        lowerText.contains('menu') ||
        lowerText.contains('comida')) {
      _addBotMessage('Aqui está o cardápio de hoje:\n\n'
          '🍽️ Prato Principal:\n'
          '- Arroz, feijão, bife grelhado, batata frita\n'
          '- Opção vegetariana: Risoto de cogumelos\n\n'
          '🥗 Saladas:\n'
          '- Mix de folhas verdes\n'
          '- Salada de tomate e pepino\n\n'
          '🥤 Bebidas:\n'
          '- Suco de laranja\n'
          '- Suco de uva\n'
          '- Refrigerante\n'
          '- Água');
    } else if (lowerText.contains('horário') ||
        lowerText.contains('funcionamento')) {
      _addBotMessage('Nosso horário de funcionamento é:\n\n'
          '🕐 Segunda a Sexta: 11h às 14h30\n'
          '🕐 Sábado: 11h às 14h\n'
          '🕐 Domingo: Fechado');
    } else if (lowerText.contains('preço') ||
        lowerText.contains('valor') ||
        lowerText.contains('quanto')) {
      _addBotMessage('Nossos preços:\n\n'
          '💰 Prato Executivo: R\$ 15,90\n'
          '💰 Opção Vegetariana: R\$ 14,90\n'
          '💰 Bebidas: R\$ 5,00\n'
          '💰 Sobremesa: R\$ 7,00');
    } else if (lowerText.contains('pedido') ||
        lowerText.contains('pedir') ||
        lowerText.contains('quero')) {
      _addBotMessage('Obrigado pelo seu pedido! Vou registrá-lo para você.\n\n'
          'Por favor, confirme os dados do seu pedido:\n\n'
          'Itens solicitados: $text\n\n'
          'Está correto? Se sim, digite "confirmar". Se não, você pode refazer o pedido.');
    } else if (lowerText.contains('confirmar') &&
        _messages.length > 1 &&
        _messages[_messages.length - 2].text.contains('Está correto?')) {
      final pedidoNumero =
          10000 + (DateTime.now().millisecondsSinceEpoch % 90000);

      _addBotMessage(
          'Pedido confirmado! Seu número de pedido é #$pedidoNumero.\n\n'
          'Resumo do pedido:\n'
          '- 1x Prato Executivo: R\$ 15,90\n'
          '- 1x Suco de Laranja: R\$ 5,00\n\n'
          'Total: R\$ 20,90\n\n'
          'Seu pedido estará pronto em aproximadamente 15 minutos.\n'
          'Você pode retirá-lo no balcão do restaurante.\n\n'
          'Deseja algo mais?');
    } else {
      _addBotMessage(
          'Desculpe, não entendi. Como posso ajudar você? Você pode perguntar sobre nosso cardápio, horário de funcionamento, preços ou fazer um pedido.');
    }
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
            onPressed: () {
              Navigator.pop(context);
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
                    _addBotMessage('Aqui está o cardápio de hoje:\n\n'
                        '🍽️ Prato Principal:\n'
                        '- Arroz, feijão, bife grelhado, batata frita\n'
                        '- Opção vegetariana: Risoto de cogumelos\n\n'
                        '🥗 Saladas:\n'
                        '- Mix de folhas verdes\n'
                        '- Salada de tomate e pepino\n\n'
                        '🥤 Bebidas:\n'
                        '- Suco de laranja\n'
                        '- Suco de uva\n'
                        '- Refrigerante\n'
                        '- Água');
                  }),
                  const SizedBox(width: 8),
                  _buildOptionButton('Horário', () {
                    _addBotMessage('Nosso horário de funcionamento é:\n\n'
                        '🕐 Segunda a Sexta: 11h às 14h30\n'
                        '🕐 Sábado: 11h às 14h\n'
                        '🕐 Domingo: Fechado');
                  }),
                  const SizedBox(width: 8),
                  _buildOptionButton('Preços', () {
                    _addBotMessage('Nossos preços:\n\n'
                        '💰 Prato Executivo: R\$ 15,90\n'
                        '💰 Opção Vegetariana: R\$ 14,90\n'
                        '💰 Bebidas: R\$ 5,00\n'
                        '💰 Sobremesa: R\$ 7,00');
                  }),
                  const SizedBox(width: 8),
                  _buildOptionButton('Fazer Pedido', () {
                    _addBotMessage(
                        'Para fazer um pedido, por favor informe:\n1. O item que deseja pedir\n2. Quantidade\n3. Observações (se houver)\n\nExemplo: "Quero 1 Prato Executivo e 1 Suco de Laranja"');
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
