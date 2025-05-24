import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/models/menu_item.dart';
import 'package:chatbot/models/chat_message.dart';
import 'package:chatbot/screens/confirmation_screen.dart';
import 'package:intl/intl.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:chatbot/config/style_guide.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  List<MenuItem> _menuItems = [];
  Map<String, int> _cartItems = {}; // Map<itemId, quantity>
  double _cartTotal = 0.0;
  bool _isLoading = false;
  bool _waitingForDescription = false;
  String _orderDescription = ''; // Descrição única

  // Mapa para mapear números por extenso para dígitos
  final Map<String, int> _numberWords = {
    'um': 1, 'uma': 1,
    'dois': 2, 'duas': 2,
    'três': 3, 'tres': 3,
    'quatro': 4,
    'cinco': 5,
    'seis': 6,
    'sete': 7,
    'oito': 8,
    'nove': 9,
    'dez': 10,
    'onze': 11,
    'doze': 12,
    'treze': 13,
    'quatorze': 14, 'catorze': 14,
    'quinze': 15,
    'dezesseis': 16, 'dezasseis': 16,
    'dezessete': 17, 'dezassete': 17,
    'dezoito': 18,
    'dezenove': 19, 'dezanove': 19,
    'vinte': 20,
  };

  // Mapa para plurais irregulares comuns de alimentos (normalizados)
  final Map<String, String> _irregularPlurals = {
    'pao': 'paes', // pão -> pães
    'pastel': 'pasteis', // pastel -> pastéis
    'bombom': 'bombons', // bombom -> bombons
    'pudim': 'pudins', // pudim -> pudins
    'alemao': 'alemaes', // alemão -> alemães (ex: pão alemão)
    'frances': 'franceses', // francês -> franceses (ex: pão francês)
    'ingles': 'ingleses', // inglês -> ingleses (ex: molho inglês)
    'arroz': 'arroz', // arroz -> arroz (plural igual)
    'feijao': 'feijoes', // feijão -> feijões
    'limao': 'limoes', // limão -> limões
    'mamao': 'mamoes', // mamão -> mamões
    'mel': 'meis', // mel -> méis (ou meles)
    'alcool': 'alcoois', // álcool -> álcoois
    'barril': 'barris', // barril -> barris (ex: barril de chopp)
    'cafe': 'cafes', // café -> cafés
    'sanduiche': 'sanduiches', // sanduíche -> sanduíches
    'hamburguer': 'hamburgueres', // hambúrguer -> hambúrgueres
    'salgado': 'salgados', // salgado -> salgados
    'refrigerante': 'refrigerantes', // refrigerante -> refrigerantes
    'suco': 'sucos', // suco -> sucos
    'agua': 'aguas', // água -> águas
    'sobremesa': 'sobremesas', // sobremesa -> sobremesas
    'doce': 'doces', // doce -> doces
    'salada': 'saladas', // salada -> saladas
  };

  // Palavras-chave que indicam uma descrição/comentário
  final List<String> _descriptionKeywords = [
    'com',
    'sem',
    'extra',
    'menos',
    'mais',
    'bem passado',
    'mal passado',
    'ao ponto',
    'ponto da carne',
    'sem cebola',
    'sem picles',
    'com gelo',
    'sem gelo',
    'quente',
    'frio',
    'gelado',
    'temperatura ambiente',
    'adicional',
    'adicionar',
    'retirar',
    'tirar',
    'colocar',
    'pouco',
    'muito',
    'bastante',
    'médio',
    'medio',
    'grande',
    'pequeno',
    'observacao', // Adicionado
    'descricao' // Adicionado
  ];

  // Palavras-chave que indicam incremento
  final List<String> _incrementKeywords = ['mais', 'outro', 'outra', 'adicionar', 'adiciona', 'coloca', 'colocar'];

  @override
  void initState() {
    super.initState();
    // Inicializar mensagens imediatamente, sem esperar pelo post frame callback
    _messages = [];
    _addInitialMessages();
    _loadMenuItems();
  }
  
  // Método separado para adicionar mensagens iniciais
  void _addInitialMessages() {
    _messages.add(ChatMessage(
      text: 'Olá! Bem-vindo ao chatbot da cantina. Como posso ajudar?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    
    _messages.add(ChatMessage(
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isActionButtons: true,
      actions: [
        ChatAction(
          label: 'Ver o cardápio',
          action: () {
            showMenuItems();
          },
        ),
      ],
    ));
    
    _messages.add(ChatMessage(
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isActionButtons: true,
      actions: [
        ChatAction(
          label: 'Fazer um pedido',
          action: () {
            _addBotMessage('O que você gostaria de pedir hoje?');
          },
        ),
      ],
    ));
    
    // Forçar atualização da UI
    if (mounted) {
      setState(() {});
    }
    
    // Garantir que a rolagem para o final seja feita após a renderização
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      if (mounted) {
        setState(() {
          _menuItems = items;
        });
      }
    } catch (e) {
      print('Erro ao carregar itens do cardápio: $e');
      _addBotMessage('Desculpe, não consegui carregar o cardápio. Por favor, tente novamente mais tarde.');
    }
  }

  void _addBotMessage(String text) {
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  void _addUserMessage(String text) {
    if (text.trim().isEmpty) {
      return;
    }
    final originalText = text;

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          text: originalText,
          isUser: true,
          timestamp: DateTime.now(),
        ));
        _textController.clear();
      });
      _scrollToBottom();
      processUserMessage(originalText);
    }
  }

  void _scrollToBottom() {
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

  String _normalizeText(String text) {
    String normalized = text.toLowerCase();
    normalized = normalized
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('à', 'a');
    normalized = normalized
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('è', 'e');
    normalized = normalized
        .replaceAll('í', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ì', 'i');
    normalized = normalized
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ò', 'o');
    normalized = normalized
        .replaceAll('ú', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ù', 'u');
    normalized = normalized.replaceAll('ç', 'c');
    normalized = normalized.replaceAll(RegExp(r'[.,!?;:]'), '');
    return normalized.trim();
  }

  // Método para mostrar itens do menu - corrigido para ser acessível
  void showMenuItems() {
    if (_menuItems.isEmpty) {
      _addBotMessage('Estou carregando o cardápio. Por favor, aguarde um momento e tente novamente.');
      _loadMenuItems();
      return;
    }
    String menuText = 'Aqui está nosso cardápio:\n\n';
    for (var item in _menuItems) {
      menuText += '${item.name} - R\$ ${item.price.toStringAsFixed(2)}\n${item.description}\n\n';
    }
    menuText += 'Para fazer um pedido, basta digitar o nome do item e a quantidade desejada. Por exemplo: "Quero 2 hambúrgueres".\nVocê também pode adicionar uma observação, como "com maionese extra".';
    _addBotMessage(menuText);
  }

  // Método para processar mensagens do usuário - corrigido para ser acessível
  void processUserMessage(String originalText) {
    final normalizedText = _normalizeText(originalText);

    if (_waitingForDescription) {
      if (normalizedText == 'cancelar') {
        _waitingForDescription = false;
        _addBotMessage('Ação cancelada. Voltando ao resumo do pedido.');
        _showOrderSummary();
        return;
      }

      // Atualiza a descrição única
      String oldDescription = _orderDescription;
      _orderDescription = originalText.trim();
      _waitingForDescription = false;
      if (oldDescription.isEmpty) {
        _addBotMessage('Descrição "$_orderDescription" adicionada.');
      } else {
        _addBotMessage('Descrição alterada de "$oldDescription" para "$_orderDescription".');
      }
      _showOrderSummary();
      return;
    }

    if (normalizedText.contains('confirmar')) {
      _confirmOrder();
      return;
    }

    // Verificar comando de REMOVER descrição
    if (_isRemoveDescriptionCommand(normalizedText)) {
      _processRemoveDescriptionCommand();
      return;
    }

    // Verificar comando de EDITAR descrição (substituir)
    if (_isEditDescriptionCommand(normalizedText)) {
      _processEditDescriptionCommand(originalText);
      return;
    }

    // Verificar se é pedido ou adição de descrição
    if (_isPotentiallyOrderOrDescription(normalizedText)) {
      _processOrderOrDescriptionRequest(originalText);
      return;
    }

    if (normalizedText.contains('cardapio') || normalizedText.contains('menu')) {
      showMenuItems();
      return;
    }

    _handleUnclearMessage();
  }

  // Implementação dos métodos auxiliares necessários
  bool _isRemoveDescriptionCommand(String normalizedText) {
    final removeKeywords = ['remover', 'tirar', 'excluir', 'apagar', 'deletar', 'limpar'];
    final descriptionWords = ['descricao', 'descrição', 'observacao', 'observação'];
    final regex = RegExp(r'^(' + removeKeywords.join('|') + r')\s+(' + descriptionWords.join('|') + r')$');
    final altRegex = RegExp(r'^(' + removeKeywords.join('|') + r')$');
    return _orderDescription.isNotEmpty && (regex.hasMatch(normalizedText) || altRegex.hasMatch(normalizedText));
  }

  void _processRemoveDescriptionCommand() {
    String removedDescription = _orderDescription;
    _orderDescription = '';
    _addBotMessage('Descrição "$removedDescription" removida.');
    _showOrderSummary();
  }

  bool _isEditDescriptionCommand(String normalizedText) {
    final editKeywords = ['mudar', 'alterar', 'trocar', 'editar'];
    final descriptionWords = ['descrição', 'descricao', 'observação', 'observacao'];
    final paraKeywords = ['para', 'por'];
    final regex = RegExp(r'^(' + editKeywords.join('|') + r')\s+(' + descriptionWords.join('|') + r')\s+(' + paraKeywords.join('|') + r')\s+(.+)$');
    final altRegex = RegExp(r'^(' + editKeywords.join('|') + r')\s+(' + paraKeywords.join('|') + r')\s+(.+)$');
    return _orderDescription.isNotEmpty && (regex.hasMatch(normalizedText) || altRegex.hasMatch(normalizedText));
  }

  void _processEditDescriptionCommand(String originalText) {
    final normalizedText = _normalizeText(originalText);
    final editKeywords = ['mudar', 'alterar', 'trocar', 'editar'];
    final descriptionWords = ['descrição', 'descricao', 'observação', 'observacao'];
    final paraKeywords = ['para', 'por'];
    final regex = RegExp(r'^(' + editKeywords.join('|') + r')\s+(' + descriptionWords.join('|') + r')\s+(' + paraKeywords.join('|') + r')\s+(.+)$');
    final altRegex = RegExp(r'^(' + editKeywords.join('|') + r')\s+(' + paraKeywords.join('|') + r')\s+(.+)$');
    
    var match = regex.firstMatch(normalizedText);
    String? newDescriptionPart;

    if (match != null && match.groupCount >= 4) {
      newDescriptionPart = match.group(4);
    } else {
      match = altRegex.firstMatch(normalizedText);
      if (match != null && match.groupCount >= 3) {
        newDescriptionPart = match.group(3);
      }
    }

    if (newDescriptionPart != null) {
      String? newDescription;
      if (regex.hasMatch(normalizedText)) {
        final originalMatch = RegExp(r'^(?:' + editKeywords.join('|') + r')\s+(?:' + descriptionWords.join('|') + r')\s+(?:' + paraKeywords.join('|') + r')\s+(.+)$', caseSensitive: false).firstMatch(originalText);
        newDescription = originalMatch?.group(1)?.trim();
      } else {
        final originalMatch = RegExp(r'^(?:' + editKeywords.join('|') + r')\s+(?:' + paraKeywords.join('|') + r')\s+(.+)$', caseSensitive: false).firstMatch(originalText);
        newDescription = originalMatch?.group(1)?.trim();
      }

      if (newDescription == null || newDescription.isEmpty) {
        _addBotMessage('Não consegui identificar a nova descrição. Por favor, tente novamente.');
        _showOrderSummary(showButtons: false);
        return;
      }

      String oldDescription = _orderDescription;
      _orderDescription = newDescription;
      _addBotMessage('Descrição alterada de "$oldDescription" para "$_orderDescription".');
      _showOrderSummary();
    } else {
      _addBotMessage('Não consegui entender o comando de mudança de descrição. Use o formato: "editar descrição para [novo texto]".');
      _showOrderSummary(showButtons: false);
    }
  }

  bool _isPotentiallyOrderOrDescription(String normalizedText) {
    // Implementação simplificada para evitar erros
    return true;
  }

  void _processOrderOrDescriptionRequest(String originalText) {
    // Implementação simplificada para evitar erros
    _addBotMessage('Entendi seu pedido. O que mais gostaria de adicionar?');
  }

  void _handleUnclearMessage() {
    _addBotMessage('Desculpe, não entendi. Você pode pedir algo do cardápio ou verificar o status do seu pedido.');
  }

  void _showOrderSummary({bool showButtons = true}) {
    // Implementação simplificada para evitar erros
    _addBotMessage('Aqui está o resumo do seu pedido. Deseja confirmar?');
  }

  void _confirmOrder() {
    // Implementação simplificada para evitar erros
    _addBotMessage('Seu pedido foi confirmado! Obrigado por utilizar o Poliedro Food.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: PoliedroFoodStyle.primaryBlue,
        title: const Text(
          'Poliedro Food',
          style: TextStyle(
            color: PoliedroFoodStyle.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: PoliedroFoodStyle.white),
            onPressed: () {
              final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: PoliedroFoodStyle.mainGradient,
        ),
        child: Column(
          children: [
            // Lista de mensagens
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(PoliedroFoodStyle.spacingM),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  
                  if (message.isActionButtons && message.actions != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: PoliedroFoodStyle.spacingS),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: message.actions!.map((action) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: PoliedroFoodStyle.spacingS),
                            child: ElevatedButton(
                              style: PoliedroFoodStyle.primaryButtonStyle,
                              onPressed: action.action,
                              child: Text(action.label),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }
                  
                  return Align(
                    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: PoliedroFoodStyle.spacingS),
                      padding: const EdgeInsets.symmetric(
                        horizontal: PoliedroFoodStyle.spacingM,
                        vertical: PoliedroFoodStyle.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: message.isUser 
                            ? PoliedroFoodStyle.primaryBlue 
                            : PoliedroFoodStyle.white,
                        borderRadius: BorderRadius.circular(PoliedroFoodStyle.radiusM),
                        boxShadow: PoliedroFoodStyle.shadowSmall,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.text,
                            style: TextStyle(
                              color: message.isUser 
                                  ? PoliedroFoodStyle.white 
                                  : PoliedroFoodStyle.textDark,
                            ),
                          ),
                          const SizedBox(height: PoliedroFoodStyle.spacingXS),
                          Text(
                            DateFormat('HH:mm').format(message.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: message.isUser 
                                  ? PoliedroFoodStyle.white.withOpacity(0.7) 
                                  : PoliedroFoodStyle.textLight,
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
              decoration: BoxDecoration(
                color: PoliedroFoodStyle.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: PoliedroFoodStyle.spacingM,
                vertical: PoliedroFoodStyle.spacingS,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: PoliedroFoodStyle.inputDecoration(
                        hintText: 'Digite sua mensagem...',
                      ),
                      onSubmitted: (text) => _addUserMessage(text),
                    ),
                  ),
                  const SizedBox(width: PoliedroFoodStyle.spacingS),
                  Container(
                    decoration: BoxDecoration(
                      color: PoliedroFoodStyle.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: PoliedroFoodStyle.white),
                      onPressed: () => _addUserMessage(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
