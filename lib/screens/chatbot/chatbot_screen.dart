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
// import 'dart:math'; // Removido - não usaremos número aleatório

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      _addBotMessage('Olá! Bem-vindo ao chatbot da cantina. Como posso ajudar?');
      _loadMenuItems();
      
      // Adicionar botões de opções iniciais após a mensagem de boas-vindas
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
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
          
          _messages.add(ChatMessage(
            text: '',
            isUser: false,
            timestamp: DateTime.now(),
            isActionButtons: true,
            actions: [
              ChatAction(
                label: 'Ver o cardápio',
                action: () {
                  _showMenuItems();
                },
              ),
            ],
          ));
        });
        _scrollToBottom();
      });
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
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    if (text.trim().isEmpty) {
      return;
    }
    final originalText = text;

    setState(() {
      _messages.add(ChatMessage(
        text: originalText,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _textController.clear();
    });
    _scrollToBottom();
    _processUserMessage(originalText);
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

  String _getPluralForm(String singularNormalized) {
    if (_irregularPlurals.containsKey(singularNormalized)) {
      return _irregularPlurals[singularNormalized]!;
    }
    if (RegExp(r'[aeiou]$').hasMatch(singularNormalized)) {
      return singularNormalized + 's';
    }
    if (singularNormalized.endsWith('l'))
      return singularNormalized.substring(0, singularNormalized.length - 1) + 'is';
    if (singularNormalized.endsWith('r') || singularNormalized.endsWith('z'))
      return singularNormalized + 'es';
    if (singularNormalized.endsWith('m'))
      return singularNormalized.substring(0, singularNormalized.length - 1) + 'ns';
    if (singularNormalized.endsWith('s') && singularNormalized.length > 3)
      return singularNormalized;
    if (singularNormalized.endsWith('s')) return singularNormalized + 'es';
    return singularNormalized + 's';
  }

  void _processUserMessage(String originalText) {
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
      _showMenuItems();
      return;
    }

    _handleUnclearMessage();
  }

  // Função para verificar se é comando de REMOVER descrição
  bool _isRemoveDescriptionCommand(String normalizedText) {
    final removeKeywords = ['remover', 'tirar', 'excluir', 'apagar', 'deletar', 'limpar'];
    final descriptionWords = ['descricao', 'descrição', 'observacao', 'observação'];
    // Padrão: (remover|tirar|...) (descrição|observação)
    final regex = RegExp(r'^(' +
        removeKeywords.join('|') +
        r')\s+(' +
        descriptionWords.join('|') +
        r')$');
    // Padrão alternativo: (remover|tirar|...) descricao
    final altRegex = RegExp(r'^(' + removeKeywords.join('|') + r')$');

    // Só considera se já existe uma descrição
    return _orderDescription.isNotEmpty && (regex.hasMatch(normalizedText) || altRegex.hasMatch(normalizedText));
  }

  // Função para processar comando de REMOVER descrição
  void _processRemoveDescriptionCommand() {
    String removedDescription = _orderDescription;
    _orderDescription = '';
    _addBotMessage('Descrição "$removedDescription" removida.');
    _showOrderSummary();
  }

  // Função para verificar se é comando de EDITAR descrição (substituir)
  bool _isEditDescriptionCommand(String normalizedText) {
    final editKeywords = ['mudar', 'alterar', 'trocar', 'editar'];
    final descriptionWords = ['descrição', 'descricao', 'observação', 'observacao'];
    final paraKeywords = ['para', 'por'];

    // Padrão: (mudar|alterar|...) (descrição|observação) (para|por) [novo texto]
    final regex = RegExp(r'^(' +
        editKeywords.join('|') +
        r')\s+(' +
        descriptionWords.join('|') +
        r')\s+(' +
        paraKeywords.join('|') +
        r')\s+(.+)$');

    // Padrão alternativo: (editar|mudar|...) (para|por) [novo texto]
    final altRegex = RegExp(r'^(' +
        editKeywords.join('|') +
        r')\s+(' +
        paraKeywords.join('|') +
        r')\s+(.+)$');

    // Só considera se já existe uma descrição para editar
    return _orderDescription.isNotEmpty && (regex.hasMatch(normalizedText) || altRegex.hasMatch(normalizedText));
  }

  // Função para processar comando de EDITAR descrição (substituir)
  void _processEditDescriptionCommand(String originalText) {
    final normalizedText = _normalizeText(originalText);
    final editKeywords = ['mudar', 'alterar', 'trocar', 'editar'];
    final descriptionWords = ['descrição', 'descricao', 'observação', 'observacao'];
    final paraKeywords = ['para', 'por'];

    // Padrão completo
    final regex = RegExp(r'^(' +
        editKeywords.join('|') +
        r')\s+(' +
        descriptionWords.join('|') +
        r')\s+(' +
        paraKeywords.join('|') +
        r')\s+(.+)$');

    // Padrão alternativo
    final altRegex = RegExp(r'^(' +
        editKeywords.join('|') +
        r')\s+(' +
        paraKeywords.join('|') +
        r')\s+(.+)$');

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
      // Extrair a nova descrição do texto original para manter a capitalização
      String? newDescription;
      if (regex.hasMatch(normalizedText)) {
        final originalMatch = RegExp(
          r'^(?:' + editKeywords.join('|') + r')\s+(?:' +
          descriptionWords.join('|') + r')\s+(?:' + paraKeywords.join('|') + r')\s+(.+)$',
          caseSensitive: false
        ).firstMatch(originalText);
        newDescription = originalMatch?.group(1)?.trim();
      } else {
         final originalMatch = RegExp(
          r'^(?:' + editKeywords.join('|') + r')\s+(?:' + paraKeywords.join('|') + r')\s+(.+)$',
          caseSensitive: false
        ).firstMatch(originalText);
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
    menuText += 'Para fazer um pedido, basta digitar o nome do item e a quantidade desejada. Por exemplo: "Quero 2 hambúrgueres".\nVocê também pode adicionar uma observação, como "com maionese extra".';
    _addBotMessage(menuText);
  }

  bool _isPotentiallyOrderOrDescription(String normalizedText) {
    final orderKeywords = [
      'quero',
      'queria',
      'gostaria',
      'pedir',
      'pedido',
      'comprar',
      'adicionar',
      'adiciona',
      'incluir',
      'coloca',
      'colocar',
      'poe',
      'põe',
      'me ve',
      'me vê',
      'manda',
      'traz'
    ];

    // Incluir palavras de incremento como potenciais pedidos
    if (orderKeywords.any((keyword) => normalizedText.contains(keyword)) ||
        _incrementKeywords.any((keyword) => normalizedText.startsWith(keyword))) {
      return true;
    }

    for (var item in _menuItems) {
      final normalizedSingular = _normalizeText(item.name);
      final normalizedPlural = _getPluralForm(normalizedSingular);
      if (RegExp('\\b' + RegExp.escape(normalizedSingular) + '\\b').hasMatch(normalizedText) ||
          RegExp('\\b' + RegExp.escape(normalizedPlural) + '\\b').hasMatch(normalizedText)) {
        return true;
      }
    }

    // Verifica se a frase contém palavras-chave de descrição E já existe um pedido em andamento
    if (_cartItems.isNotEmpty) {
      for (var keyword in _descriptionKeywords) {
        bool partOfItemName = _menuItems.any((item) => _normalizeText(item.name).contains(keyword));
        if (normalizedText.contains(keyword) && !partOfItemName) {
          return true;
        }
      }
    }

    final numberItemRegex = RegExp(r'^(\d+|' + _numberWords.keys.join('|') + r')\s+([\w\s]+)$');
    if (numberItemRegex.hasMatch(normalizedText)) {
      final match = numberItemRegex.firstMatch(normalizedText);
      if (match != null && match.groupCount >= 2) {
        final itemNamePart = _normalizeText(match.group(2)!);
        for (var item in _menuItems) {
          final normalizedSingular = _normalizeText(item.name);
          final normalizedPlural = _getPluralForm(normalizedSingular);
          if (itemNamePart == normalizedSingular || itemNamePart == normalizedPlural) {
            return true;
          }
        }
      }
    }

    return false;
  }

  int _extractQuantity(String text, String itemName) {
    final normalizedText = _normalizeText(text);
    final normalizedSingular = _normalizeText(itemName);
    final normalizedPlural = _getPluralForm(normalizedSingular);
    final escapedSingular = RegExp.escape(normalizedSingular);
    final escapedPlural = RegExp.escape(normalizedPlural);

    // Verifica se começa com palavra de incremento (ex: "mais 1 pao")
    for (var incKeyword in _incrementKeywords) {
      final incRegex = RegExp(r'^' + incKeyword + r'\s+(\d+)\s+(?:' + escapedSingular + r'|' + escapedPlural + r')\b');
      var incMatch = incRegex.firstMatch(normalizedText);
      if (incMatch != null) return int.tryParse(incMatch.group(1) ?? '1') ?? 1;

      for (var entry in _numberWords.entries) {
        final incRegexWord = RegExp(r'^' + incKeyword + r'\s+' + entry.key + r'\s+(?:' + escapedSingular + r'|' + escapedPlural + r')\b');
        if (incRegexWord.hasMatch(normalizedText)) return entry.value;
      }
      // Caso "mais pao" (sem número explícito)
      final incRegexNoNum = RegExp(r'^' + incKeyword + r'\s+(?:' + escapedSingular + r'|' + escapedPlural + r')\b');
      if (incRegexNoNum.hasMatch(normalizedText)) return 1;
    }

    // Verifica padrão "quero 2 paes"
    final regexBefore = RegExp(r'(\d+)\s+(?:' + escapedSingular + r'|' + escapedPlural + r')\b');
    var match = regexBefore.firstMatch(normalizedText);
    if (match != null) return int.tryParse(match.group(1) ?? '1') ?? 1;

    // Verifica padrão "quero dois paes"
    for (var entry in _numberWords.entries) {
      final regexWordBefore = RegExp(r'\b' + entry.key + r'\s+(?:' + escapedSingular + r'|' + escapedPlural + r')\b');
      if (regexWordBefore.hasMatch(normalizedText)) return entry.value;
    }

    final regexAfter = RegExp(r'\b(?:' + escapedSingular + r'|' + escapedPlural + r')\s+(\d+)\b');
    match = regexAfter.firstMatch(normalizedText);
    if (match != null) return int.tryParse(match.group(1) ?? '1') ?? 1;

    for (var entry in _numberWords.entries) {
      final regexWordAfter = RegExp(r'\b(?:' + escapedSingular + r'|' + escapedPlural + r')\s+\b' + entry.key + r'\b');
      if (regexWordAfter.hasMatch(normalizedText)) return entry.value;
    }

    // Caso "pao" (sem número explícito e sem incremento)
    if (RegExp('\\b' + escapedSingular + '\\b').hasMatch(normalizedText) ||
        RegExp('\\b' + escapedPlural + '\\b').hasMatch(normalizedText)) {
      final hasLooseNumber = RegExp(r'\b\d+\b').hasMatch(normalizedText);
      final hasLooseNumberWord = _numberWords.keys.any((word) => RegExp('\\b$word\\b').hasMatch(normalizedText));
      if (!hasLooseNumber && !hasLooseNumberWord && !_incrementKeywords.any((kw) => normalizedText.contains(kw)))
        return 1;
    }

    // Caso "1 pao" (apenas número e item)
    final numberItemRegex = RegExp(r'^(\d+|' + _numberWords.keys.join('|') + r')\s+(?:' + escapedSingular + r'|' + escapedPlural + r')$');
    match = numberItemRegex.firstMatch(normalizedText);
    if (match != null) {
      final numberPart = match.group(1)!;
      return int.tryParse(numberPart) ?? _numberWords[numberPart] ?? 1;
    }

    return 0; // Não encontrou quantidade clara
  }

  void _processOrderOrDescriptionRequest(String originalText) {
    if (_menuItems.isEmpty) {
      _addBotMessage('Estou carregando o cardápio...');
      _loadMenuItems();
      return;
    }

    final normalizedText = _normalizeText(originalText);
    Map<String, int> itemsFound = {};
    String potentialDescription = '';
    bool descriptionKeywordFound = false;
    bool itemAdded = false;

    // 1. Tentar encontrar itens (base ou composto) e extrair quantidade
    List<MenuItem> matchedItems = [];
    for (var item in _menuItems) {
      final normalizedSingular = _normalizeText(item.name);
      final normalizedPlural = _getPluralForm(normalizedSingular);
      if (RegExp('\\b' + RegExp.escape(normalizedSingular) + '\\b').hasMatch(normalizedText) ||
          RegExp('\\b' + RegExp.escape(normalizedPlural) + '\\b').hasMatch(normalizedText)) {
        matchedItems.add(item);
      }
    }

    // Priorizar match mais longo (item composto)
    matchedItems.sort((a, b) => _normalizeText(b.name).length.compareTo(_normalizeText(a.name).length));

    MenuItem? bestMatch;
    if (matchedItems.isNotEmpty) {
      bestMatch = matchedItems.first;
      int quantity = _extractQuantity(originalText, bestMatch.name);
      if (quantity > 0) {
        itemsFound[bestMatch.id] = quantity;
      }
    }

    // 2. Isolar a parte da descrição (se houver)
    String remainingText = originalText;
    if (bestMatch != null) {
      // Remover o nome do item (e quantidade, se adjacente) para isolar a descrição
      remainingText = originalText
          .replaceAll(RegExp('\\b' + RegExp.escape(bestMatch.name) + '\\b', caseSensitive: false), '')
          .trim();
      String quantityStr = itemsFound[bestMatch.id]?.toString() ?? '';
      if (quantityStr.isNotEmpty) {
        remainingText = remainingText.replaceAll(RegExp('\\b' + quantityStr + '\\b'), '').trim();
      }
      for (var word in _numberWords.keys) {
        remainingText = remainingText.replaceAll(RegExp('\\b' + word + '\\b'), '').trim();
      }
      // Remover palavras de incremento do início
      for (var incKeyword in _incrementKeywords) {
        if (remainingText.toLowerCase().startsWith(incKeyword + ' ')) {
          remainingText = remainingText.substring(incKeyword.length + 1).trim();
        }
      }
      remainingText = remainingText
          .replaceAll(RegExp(r'^[.,!?;:]+\s*'), '')
          .trim(); // Remover pontuação inicial
      remainingText = remainingText
          .replaceAll(RegExp(r'^\s*'), '')
          .trim(); // Remover espaços iniciais

      if (remainingText.isNotEmpty && remainingText.length > 2) {
        potentialDescription = remainingText;
        // Verificar se a descrição isolada contém palavras-chave de descrição
        for (var keyword in _descriptionKeywords) {
          if (_normalizeText(potentialDescription).contains(keyword)) {
            descriptionKeywordFound = true;
            break;
          }
        }
      }
    }

    // 3. Decidir a ação
    if (itemsFound.isNotEmpty) {
      // Adicionar itens ao carrinho
      itemsFound.forEach((itemId, quantity) {
        _cartItems[itemId] = (_cartItems[itemId] ?? 0) + quantity;
      });
      _updateCartTotal();
      itemAdded = true;

      String itemAddedMessage = 'Entendi "${bestMatch!.name}" (${itemsFound[bestMatch.id]}x). Adicionado ao pedido.';
      _addBotMessage(itemAddedMessage);

      // Adicionar/Substituir descrição SE ela foi encontrada
      if (descriptionKeywordFound && potentialDescription.isNotEmpty) {
        String oldDescription = _orderDescription;
        _orderDescription = potentialDescription;
        if (oldDescription.isEmpty) {
           _addBotMessage('Observação adicionada: "$_orderDescription".');
        } else {
           _addBotMessage('Observação alterada de "$oldDescription" para "$_orderDescription".');
        }
      }
      _showOrderSummary();
    } else if (descriptionKeywordFound && _cartItems.isNotEmpty && !itemAdded) {
      // Se não encontrou item mas encontrou descrição e já há itens no carrinho
      // (Tratar como adição/substituição de descrição avulsa)
      String newDescription = originalText.trim();
      String oldDescription = _orderDescription;
      _orderDescription = newDescription;
      if (oldDescription.isEmpty) {
        _addBotMessage('Entendido. Adicionei "$_orderDescription" como observação ao seu pedido.');
      } else {
        _addBotMessage('Entendido. Alterei a observação de "$oldDescription" para "$_orderDescription".');
      }
      _showOrderSummary(); // Mostrar resumo com botões após alterar descrição
    } else {
      // Se não encontrou item nem descrição clara, tentar similaridade
      _trySimilarityMatch(originalText);
    }
  }

  void _trySimilarityMatch(String originalText) {
    if (_menuItems.isEmpty || originalText.length < 3) {
      _handleUnclearMessage();
      return;
    }

    String bestMatchItemId = '';
    double highestSimilarity = 0.65; // Limiar de similaridade
    final normalizedText = _normalizeText(originalText);

    for (var item in _menuItems) {
      final normalizedSingular = _normalizeText(item.name);
      final normalizedPlural = _getPluralForm(normalizedSingular);
      double currentHighestSim = 0.0;

      final simSingularFull = normalizedText.similarityTo(normalizedSingular);
      final simPluralFull = normalizedText.similarityTo(normalizedPlural);
      currentHighestSim = simSingularFull > simPluralFull ? simSingularFull : simPluralFull;

      for (String word in normalizedText.split(' ')) {
        if (word.length < 3) continue;
        final simSingularWord = word.similarityTo(normalizedSingular);
        final simPluralWord = word.similarityTo(normalizedPlural);
        final simWord = simSingularWord > simPluralWord ? simSingularWord : simPluralWord;
        if (simWord > currentHighestSim) {
          currentHighestSim = simWord;
        }
      }

      if (currentHighestSim > highestSimilarity) {
        highestSimilarity = currentHighestSim;
        bestMatchItemId = item.id;
      }
    }

    if (bestMatchItemId.isNotEmpty) {
      final matchedItem = _menuItems.firstWhere((i) => i.id == bestMatchItemId);
      int quantity = _extractQuantity(originalText, matchedItem.name);
      if (quantity == 0)
        quantity = 1; // Default to 1 if similarity match but no quantity

      _cartItems[matchedItem.id] = (_cartItems[matchedItem.id] ?? 0) + quantity;
      _updateCartTotal();
      _addBotMessage('Entendi "${matchedItem.name}" (por similaridade). Adicionado ao pedido.');
      _showOrderSummary();
    } else {
      _handleUnclearMessage();
    }
  }

  void _updateCartTotal() {
    _cartTotal = 0.0;
    _cartItems.forEach((itemId, quantity) {
      final item = _menuItems.firstWhere((i) => i.id == itemId,
          orElse: () => MenuItem(id: '', name: 'Desconhecido', description: '', price: 0));
      _cartTotal += item.price * quantity;
    });
  }

  void _showOrderSummary({bool showButtons = true}) {
    if (_cartItems.isEmpty) {
      _addBotMessage('Seu carrinho está vazio.');
      return;
    }

    String summary = 'Resumo atual:\n\n';
    _cartItems.forEach((itemId, quantity) {
      final item = _menuItems.firstWhere((i) => i.id == itemId,
          orElse: () => MenuItem(id: '', name: 'Desconhecido', description: '', price: 0));
      summary += '- ${quantity}x ${item.name}: R\$ ${(item.price * quantity).toStringAsFixed(2)}\n';
    });
    summary += '\nTotal: R\$ ${_cartTotal.toStringAsFixed(2)}\n';

    // Exibir descrição única
    if (_orderDescription.isNotEmpty) {
      summary += '\nObservação: ${_orderDescription}\n';
    }

    summary += '\nVocê pode adicionar mais itens, adicionar/mudar/remover a observação ou confirmar o pedido.';
    _addBotMessage(summary);

    if (showButtons) {
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          List<ChatAction> actionButtons = [];

          // Botão Adicionar Outro Item (SEMPRE)
          actionButtons.add(ChatAction(
            label: 'Adicionar Outro Item',
            action: () {
              _addBotMessage('O que mais você gostaria de pedir?');
            },
          ));

          // Botão Adicionar/Editar Descrição
          actionButtons.add(ChatAction(
            label: _orderDescription.isEmpty ? 'Adicionar Observação' : 'Editar Observação',
            action: () {
              _addBotMessage(_orderDescription.isEmpty
                  ? 'Qual observação você gostaria de adicionar ao pedido?'
                  : 'Qual a nova observação para substituir "$_orderDescription"?');
              _waitingForDescription = true;
            },
          ));

          // Botão Remover Descrição (se houver)
          if (_orderDescription.isNotEmpty) {
            actionButtons.add(ChatAction(
              label: 'Remover Observação',
              action: () {
                _processRemoveDescriptionCommand(); // Chama a função diretamente
              },
            ));
          }

          // Botão Confirmar Pedido (SEMPRE)
          actionButtons.add(ChatAction(
            label: 'Confirmar Pedido',
            action: () {
              _confirmOrder();
            },
          ));

          // Adiciona a mensagem com os botões
          _messages.add(ChatMessage(
            text: '', // Texto não é usado quando isActionButtons é true
            isUser: false,
            timestamp: DateTime.now(),
            isActionButtons: true,
            actions: actionButtons,
          ));
        });
        _scrollToBottom();
      });
    }
  }

  void _handleUnclearMessage() {
    _addBotMessage('Desculpe, não entendi. Você gostaria de ver o cardápio ou fazer um pedido?');
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add(ChatMessage(
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
          isActionButtons: true,
          actions: [
            ChatAction(
              label: 'Cardápio',
              action: () {
                _showMenuItems();
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
              label: 'Fazer Pedido',
              action: () {
                _addBotMessage('O que você gostaria de pedir hoje?');
              },
            ),
          ],
        ));
      });
      _scrollToBottom();
    });
  }

  // Função para obter e incrementar o número do pedido sequencial
  Future<int> _getNextOrderNumber() async {
    final counterRef = _firestore.collection('counters').doc('order_number');

    // Executa uma transação para garantir atomicidade
    return _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(counterRef);

      if (!snapshot.exists) {
        // Se o contador não existe, cria com valor 1
        transaction.set(counterRef, {'value': 1});
        return 1;
      } else {
        // Se existe, incrementa o valor
        final currentNumber = (snapshot.data()?['value'] as int?) ?? 0;
        final nextNumber = currentNumber + 1;
        transaction.update(counterRef, {'value': nextNumber});
        return nextNumber;
      }
    });
  }

  Future<void> _confirmOrder() async {
    if (_cartItems.isEmpty) {
      _addBotMessage('Seu carrinho está vazio. Adicione itens antes de confirmar.');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _addBotMessage('Confirmando seu pedido...');

    try {
      final authProvider = Provider.of<ChatbotAuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      // Obter o UID e Email do usuário logado através da instância _auth
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('Usuário Firebase não encontrado.');
      }
      final userId = firebaseUser.uid;
      final userEmail = firebaseUser.email ?? ''; // Usar email para extrair RA

      // Obter o próximo número de pedido sequencial
      final nextOrderNumber = await _getNextOrderNumber();
      final orderNumberString = nextOrderNumber.toString().padLeft(3, '0'); // Formata como 001, 002...

      // Criar lista de itens formatada para o Firestore
      List<Map<String, dynamic>> itemsList = [];
      _cartItems.forEach((itemId, quantity) {
        final item = _menuItems.firstWhere((i) => i.id == itemId,
            orElse: () => MenuItem(id: '', name: 'Desconhecido', description: '', price: 0));
        itemsList.add({
          'itemId': itemId,
          'name': item.name,
          'quantity': quantity,
          'price': item.price,
        });
      });

      // Salvar pedido no Firestore
      final orderRef = await _firestore.collection('orders').add({
        'userId': userId,
        'userEmail': userEmail, // Salvar email
        'userPhone': user.phone, // Manter telefone se existir
        'items': itemsList,
        'total': _cartTotal,
        'description': _orderDescription, // Salvar descrição única
        'status': 'pending', // Status inicial
        'timestamp': FieldValue.serverTimestamp(),
        'orderNumber': nextOrderNumber, // Salvar o número sequencial (int)
      });

      // Guardar o total e número antes de limpar
      final confirmedTotal = _cartTotal;
      final confirmedOrderNumber = orderNumberString; // Usar o número formatado

      // Limpar carrinho e estado local
      setState(() {
        _cartItems = {};
        _cartTotal = 0.0;
        _orderDescription = ''; // Limpar descrição
        _isLoading = false;
      });

      // Navegar para a tela de confirmação
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationScreen(
            orderId: orderRef.id,
            totalValue: confirmedTotal,
            orderNumber: confirmedOrderNumber, // Passar número do pedido formatado
          ),
        ),
      );

      // Adicionar mensagem de sucesso após a navegação
      _addBotMessage('Pedido #$confirmedOrderNumber confirmado com sucesso! Obrigado!');

    } catch (e) {
      print('Erro ao confirmar pedido: $e');
      setState(() {
        _isLoading = false;
      });
      _addBotMessage('Desculpe, houve um erro ao confirmar seu pedido. Detalhes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot da Cantina'),
        automaticallyImplyLeading: false, // Remove o botão de voltar
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<ChatbotAuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];

                // Mensagem com botões de ação
                if (message.isActionButtons && message.actions.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                    child: Wrap(
                      spacing: 8.0, // Espaço horizontal entre botões
                      runSpacing: 8.0, // Espaço vertical entre linhas de botões
                      alignment: WrapAlignment.center,
                      children: message.actions.map((action) {
                        return ElevatedButton(
                          onPressed: action.action,
                          child: Text(action.label),
                          style: ElevatedButton.styleFrom(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          )
                        );
                      }).toList(),
                    ),
                  );
                }

                // Mensagem normal de texto
                return Container(
                  margin: EdgeInsets.only(
                    top: 8.0,
                    bottom: 8.0,
                    left: message.isUser ? 64.0 : 8.0,
                    right: message.isUser ? 8.0 : 64.0,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.0),
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
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (text) {
                      _addUserMessage(text);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _addUserMessage(_textController.text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

