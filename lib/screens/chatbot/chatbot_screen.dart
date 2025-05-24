import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as firebase_auth; // Importar FirebaseAuth
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/models/menu_item.dart';
import 'package:chatbot/models/chat_message.dart';
import 'package:chatbot/screens/confirmation_screen.dart';
// import 'package:chatbot/providers/counter_provider.dart'; // CounterProvider não é usado neste arquivo
import 'package:intl/intl.dart';
import 'package:string_similarity/string_similarity.dart'; // Para comparação flexível

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth =
      firebase_auth.FirebaseAuth.instance; // Declarar instância do FirebaseAuth
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  List<MenuItem> _menuItems = [];
  Map<String, int> _cartItems = {}; // Map<itemId, quantity>
  double _cartTotal = 0.0;
  bool _isLoading = false;
  bool _waitingForDescription = false;
  // Usar Lista para descrições
  List<String> _orderDescriptions = [];

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
    // Adicione mais se necessário
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
    // Adicione outros aqui conforme necessário
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
    'sem gelo'
    // Adicione outras palavras/frases comuns de descrição aqui
  ];

  // Palavras-chave que indicam incremento
  final List<String> _incrementKeywords = ['mais', 'outro', 'outra'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider =
          Provider.of<ChatbotAuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      _addBotMessage(
          'Olá! Bem-vindo ao chatbot da cantina. Como posso ajudar?');
      _loadMenuItems();
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
      _addBotMessage(
          'Desculpe, não consegui carregar o cardápio. Por favor, tente novamente mais tarde.');
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
        .replaceAll('ã', 'a');
    normalized = normalized.replaceAll('é', 'e').replaceAll('ê', 'e');
    normalized = normalized.replaceAll('í', 'i');
    normalized = normalized
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o');
    normalized = normalized.replaceAll('ú', 'u').replaceAll('ü', 'u');
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
      return singularNormalized.substring(0, singularNormalized.length - 1) +
          'is';
    if (singularNormalized.endsWith('r') || singularNormalized.endsWith('z'))
      return singularNormalized + 'es';
    if (singularNormalized.endsWith('m'))
      return singularNormalized.substring(0, singularNormalized.length - 1) +
          'ns';
    if (singularNormalized.endsWith('s') && singularNormalized.length > 3)
      return singularNormalized;
    if (singularNormalized.endsWith('s')) return singularNormalized + 'es';
    return singularNormalized + 's';
  }

  void _processUserMessage(String originalText) {
    final normalizedText = _normalizeText(originalText);

    if (_waitingForDescription) {
      // NOVO: Adicionar verificação para "cancelar"
      if (normalizedText == 'cancelar') {
        _waitingForDescription = false;
        _addBotMessage('Ação cancelada. Voltando ao resumo do pedido.');
        _showOrderSummary();
        return;
      }

      if (normalizedText.contains('confirmar')) {
        _confirmOrder();
      } else {
        String newDescription = originalText.trim();
        if (!_orderDescriptions.any(
            (desc) => _normalizeText(desc) == _normalizeText(newDescription))) {
          _orderDescriptions.add(newDescription);
          _addBotMessage('Descrição "$newDescription" adicionada.');
        } else {
          _addBotMessage('Essa descrição já existe.');
        }
        _waitingForDescription = false;
        _showOrderSummary();
      }
      return;
    }

    if (normalizedText.contains('confirmar')) {
      _confirmOrder();
      return;
    }

    // NOVO: Verificar comando de edição de descrição
    if (_isEditDescriptionCommand(normalizedText)) {
      _processEditDescriptionCommand(originalText);
      return;
    }

    // NOVO: Verificar comando de exclusão de descrição
    if (_isDeleteDescriptionCommand(normalizedText)) {
      _processDeleteDescriptionCommand(originalText);
      return;
    }

    if (_isPotentiallyOrderOrDescription(normalizedText)) {
      _processOrderOrDescriptionRequest(originalText);
      return;
    }

    if (normalizedText.contains('cardapio') ||
        normalizedText.contains('menu')) {
      _showMenuItems();
      return;
    }

    _handleUnclearMessage();
  }

  // NOVO: Função para verificar se é comando de edição
  bool _isEditDescriptionCommand(String normalizedText) {
    final editKeywords = ['mudar', 'alterar', 'trocar', 'editar'];
    final descriptionKeywords = [
      'descrição',
      'descricao',
      'observação',
      'observacao'
    ];
    final paraKeywords = ['para', 'por'];

    // Padrão: (mudar|alterar|...) (descrição|observação|...) [número] (para|por) [novo texto]
    final regex = RegExp(r'^(' +
        editKeywords.join('|') +
        r')\s+(' +
        descriptionKeywords.join('|') +
        r')\s+(\d+)\s+(' +
        paraKeywords.join('|') +
        r')\s+(.+)$');
    return regex.hasMatch(normalizedText);
  }

  // NOVO: Função para processar comando de edição
  void _processEditDescriptionCommand(String originalText) {
    final normalizedText = _normalizeText(originalText);
    final editKeywords = ['mudar', 'alterar', 'trocar', 'editar'];
    final descriptionKeywords = [
      'descrição',
      'descricao',
      'observação',
      'observacao'
    ];
    final paraKeywords = ['para', 'por'];

    final regex = RegExp(r'^(' +
        editKeywords.join('|') +
        r')\s+(' +
        descriptionKeywords.join('|') +
        r')\s+(\d+)\s+(' +
        paraKeywords.join('|') +
        r')\s+(.+)$');

    final match = regex.firstMatch(normalizedText);
    if (match != null && match.groupCount >= 5) {
      final indexStr = match.group(3);
      final newDescriptionPart = match.group(5);

      if (indexStr != null && newDescriptionPart != null) {
        final index = int.tryParse(indexStr);
        // Extrair a nova descrição do texto original para manter a capitalização
        final originalMatch = RegExp(
                r'^(?:' +
                    editKeywords.join('|') +
                    r')\s+(?:' +
                    descriptionKeywords.join('|') +
                    r')\s+' +
                    indexStr +
                    r'\s+(?:' +
                    paraKeywords.join('|') +
                    r')\s+(.+)$',
                caseSensitive: false)
            .firstMatch(originalText);

        final newDescription =
            originalMatch?.group(1)?.trim() ?? newDescriptionPart.trim();

        if (index != null && index > 0 && index <= _orderDescriptions.length) {
          final oldDescription = _orderDescriptions[index - 1];
          _orderDescriptions[index - 1] = newDescription;
          _addBotMessage(
              'Descrição ${index} alterada de "$oldDescription" para "$newDescription".');
          _showOrderSummary();
        } else {
          _addBotMessage(
              'Número de descrição inválido. Por favor, informe um número entre 1 e ${_orderDescriptions.length}.');
        }
      } else {
        _addBotMessage(
            'Não consegui entender qual descrição mudar ou qual o novo texto. Use o formato: "mudar descrição [número] para [novo texto]".');
      }
    } else {
      _addBotMessage(
          'Não consegui entender o comando de mudança de descrição. Use o formato: "mudar descrição [número] para [novo texto]".');
    }
  }

  void _showMenuItems() {
    if (_menuItems.isEmpty) {
      _addBotMessage(
          'Estou carregando o cardápio. Por favor, aguarde um momento e tente novamente.');
      _loadMenuItems();
      return;
    }
    String menuText = 'Aqui está nosso cardápio:\n\n';
    for (var item in _menuItems) {
      menuText +=
          '${item.name} - R\$ ${item.price.toStringAsFixed(2)}\n${item.description}\n\n';
    }
    menuText +=
        'Para fazer um pedido, basta digitar o nome do item e a quantidade desejada. Por exemplo: "Quero 2 hambúrgueres".\nVocê também pode adicionar observações, como "com maionese extra".';
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
      'poe',
      'põe',
      'me ve',
      'me vê',
      'manda',
      'traz'
    ];

    // Incluir palavras de incremento como potenciais pedidos
    if (orderKeywords.any((keyword) => normalizedText.contains(keyword)) ||
        _incrementKeywords
            .any((keyword) => normalizedText.startsWith(keyword))) {
      return true;
    }

    for (var item in _menuItems) {
      final normalizedSingular = _normalizeText(item.name);
      final normalizedPlural = _getPluralForm(normalizedSingular);
      if (RegExp('\b' + RegExp.escape(normalizedSingular) + '\b')
              .hasMatch(normalizedText) ||
          RegExp('\b' + RegExp.escape(normalizedPlural) + '\b')
              .hasMatch(normalizedText)) {
        return true;
      }
    }

    if (_cartItems.isNotEmpty) {
      for (var keyword in _descriptionKeywords) {
        bool partOfItemName = _menuItems
            .any((item) => _normalizeText(item.name).contains(keyword));
        if (normalizedText.contains(keyword) && !partOfItemName) {
          return true;
        }
      }
    }

    final numberItemRegex =
        RegExp(r'^(\d+|' + _numberWords.keys.join('|') + r')\s+([\w\s]+)$');
    if (numberItemRegex.hasMatch(normalizedText)) {
      final match = numberItemRegex.firstMatch(normalizedText);
      if (match != null && match.groupCount >= 2) {
        final itemNamePart = _normalizeText(match.group(2)!);
        for (var item in _menuItems) {
          final normalizedSingular = _normalizeText(item.name);
          final normalizedPlural = _getPluralForm(normalizedSingular);
          if (itemNamePart == normalizedSingular ||
              itemNamePart == normalizedPlural) {
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
      final incRegex = RegExp(r'^' +
          incKeyword +
          r'\s+(\d+)\s+(?:' +
          escapedSingular +
          r'|' +
          escapedPlural +
          r')\b');
      var incMatch = incRegex.firstMatch(normalizedText);
      if (incMatch != null) return int.tryParse(incMatch.group(1) ?? '1') ?? 1;

      for (var entry in _numberWords.entries) {
        final incRegexWord = RegExp(r'^' +
            incKeyword +
            r'\s+' +
            entry.key +
            r'\s+(?:' +
            escapedSingular +
            r'|' +
            escapedPlural +
            r')\b');
        if (incRegexWord.hasMatch(normalizedText)) return entry.value;
      }
      // Caso "mais pao" (sem número explícito)
      final incRegexNoNum = RegExp(r'^' +
          incKeyword +
          r'\s+(?:' +
          escapedSingular +
          r'|' +
          escapedPlural +
          r')\b');
      if (incRegexNoNum.hasMatch(normalizedText)) return 1;
    }

    // Lógica anterior para números antes/depois do item
    final regexBefore = RegExp(
        r'(\d+)\s+(?:' + escapedSingular + r'|' + escapedPlural + r')\b');
    var match = regexBefore.firstMatch(normalizedText);
    if (match != null) return int.tryParse(match.group(1) ?? '1') ?? 1;

    for (var entry in _numberWords.entries) {
      final regexWordBefore = RegExp(r'\b' +
          entry.key +
          r'\b\s+(?:' +
          escapedSingular +
          r'|' +
          escapedPlural +
          r')\b');
      if (regexWordBefore.hasMatch(normalizedText)) return entry.value;
    }

    final regexAfter = RegExp(
        r'\b(?:' + escapedSingular + r'|' + escapedPlural + r')\s+(\d+)\b');
    match = regexAfter.firstMatch(normalizedText);
    if (match != null) return int.tryParse(match.group(1) ?? '1') ?? 1;

    for (var entry in _numberWords.entries) {
      final regexWordAfter = RegExp(r'\b(?:' +
          escapedSingular +
          r'|' +
          escapedPlural +
          r')\s+\b' +
          entry.key +
          r'\b');
      if (regexWordAfter.hasMatch(normalizedText)) return entry.value;
    }

    // Caso "pao" (sem número explícito e sem incremento)
    if (RegExp('\b' + escapedSingular + '\b').hasMatch(normalizedText) ||
        RegExp('\b' + escapedPlural + '\b').hasMatch(normalizedText)) {
      final hasLooseNumber = RegExp(r'\b\d+\b').hasMatch(normalizedText);
      final hasLooseNumberWord = _numberWords.keys
          .any((word) => RegExp('\b$word\b').hasMatch(normalizedText));
      if (!hasLooseNumber &&
          !hasLooseNumberWord &&
          !_incrementKeywords.any((kw) => normalizedText.contains(kw)))
        return 1;
    }

    // Caso "1 pao" (apenas número e item)
    final numberItemRegex = RegExp(r'^(\d+|' +
        _numberWords.keys.join('|') +
        r')\s+(?:' +
        escapedSingular +
        r'|' +
        escapedPlural +
        r')$');
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
      if (RegExp('\b' + RegExp.escape(normalizedSingular) + '\b')
              .hasMatch(normalizedText) ||
          RegExp('\b' + RegExp.escape(normalizedPlural) + '\b')
              .hasMatch(normalizedText)) {
        matchedItems.add(item);
      }
    }

    // Priorizar match mais longo (item composto)
    matchedItems.sort((a, b) =>
        _normalizeText(b.name).length.compareTo(_normalizeText(a.name).length));

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
          .replaceAll(
              RegExp('\b' + RegExp.escape(bestMatch.name) + '\b',
                  caseSensitive: false),
              '')
          .trim();
      String quantityStr = itemsFound[bestMatch.id]?.toString() ?? '';
      if (quantityStr.isNotEmpty) {
        remainingText = remainingText
            .replaceAll(RegExp('\b' + quantityStr + '\b'), '')
            .trim();
      }
      for (var word in _numberWords.keys) {
        remainingText =
            remainingText.replaceAll(RegExp('\b' + word + '\b'), '').trim();
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

      String itemAddedMessage =
          'Entendi "${bestMatch!.name}" (${itemsFound[bestMatch.id]}x). Adicionado ao pedido.';
      _addBotMessage(itemAddedMessage);

      // Adicionar descrição SE ela foi encontrada E não existe ainda
      if (descriptionKeywordFound && potentialDescription.isNotEmpty) {
        String normalizedPotentialDesc = _normalizeText(potentialDescription);
        if (!_orderDescriptions
            .any((desc) => _normalizeText(desc) == normalizedPotentialDesc)) {
          _orderDescriptions.add(potentialDescription);
          _addBotMessage('Observação adicionada: "$potentialDescription".');
        }
      }
      _showOrderSummary();
    } else if (descriptionKeywordFound && _cartItems.isNotEmpty && !itemAdded) {
      // Se não encontrou item mas encontrou descrição e já há itens no carrinho
      // (Tratar como adição de descrição avulsa)
      String newDescription = originalText.trim();
      String normalizedNewDesc = _normalizeText(newDescription);
      if (!_orderDescriptions
          .any((desc) => _normalizeText(desc) == normalizedNewDesc)) {
        _orderDescriptions.add(newDescription);
        _addBotMessage(
            'Entendido. Adicionei "$newDescription" como observação ao seu pedido.');
      } else {
        _addBotMessage('Essa observação já existe.');
      }
      _showOrderSummary(showButtons: false);
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
      currentHighestSim =
          simSingularFull > simPluralFull ? simSingularFull : simPluralFull;

      for (String word in normalizedText.split(' ')) {
        if (word.length < 3) continue;
        final simSingularWord = word.similarityTo(normalizedSingular);
        final simPluralWord = word.similarityTo(normalizedPlural);
        final simWord =
            simSingularWord > simPluralWord ? simSingularWord : simPluralWord;
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
      _addBotMessage(
          'Entendi "${matchedItem.name}" (por similaridade). Adicionado ao pedido.');
      _showOrderSummary();
    } else {
      _handleUnclearMessage();
    }
  }

  void _updateCartTotal() {
    _cartTotal = 0.0;
    _cartItems.forEach((itemId, quantity) {
      final item = _menuItems.firstWhere((i) => i.id == itemId,
          orElse: () => MenuItem(
              id: '', name: 'Desconhecido', description: '', price: 0));
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
          orElse: () => MenuItem(
              id: '', name: 'Desconhecido', description: '', price: 0));
      summary +=
          '- ${quantity}x ${item.name}: R\$ ${(item.price * quantity).toStringAsFixed(2)}\n';
    });
    summary += '\nTotal: R\$ ${_cartTotal.toStringAsFixed(2)}\n';

    // Exibir lista numerada de descrições
    if (_orderDescriptions.isNotEmpty) {
      summary += '\nObservações:\n';
      for (int i = 0; i < _orderDescriptions.length; i++) {
        summary += '${i + 1}. ${_orderDescriptions[i]}\n';
      }
    }

    summary +=
        '\nVocê pode adicionar mais itens, adicionar/mudar descrições ou confirmar o pedido.';
    _addBotMessage(summary);

    if (showButtons) {
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Adicionar Descrição',
            isUser: false,
            timestamp: DateTime.now(),
            isButton: true,
            onButtonPressed: () {
              _addBotMessage(
                  'Qual descrição/observação você gostaria de adicionar ao pedido?');
              _waitingForDescription = true;
            },
          ));
          // NOVO: Botão para Mudar Descrição (se houver descrições)
          if (_orderDescriptions.isNotEmpty) {
            _messages.add(ChatMessage(
              text: 'Mudar Descrição',
              isUser: false,
              timestamp: DateTime.now(),
              isButton: true,
              onButtonPressed: () {
                _addBotMessage(
                    'Qual número de descrição você quer mudar e qual o novo texto? (Ex: "mudar descrição 1 para sem queijo")');
                // Não definimos _waitingForDescription aqui, pois o comando é direto
              },
            ));
          }
          _messages.add(ChatMessage(
            text: 'Confirmar Pedido',
            isUser: false,
            timestamp: DateTime.now(),
            isButton: true,
            onButtonPressed: () {
              _confirmOrder();
            },
          ));
        });
        _scrollToBottom();
      });
    }
  }

  void _handleUnclearMessage() {
    _addBotMessage(
        'Desculpe, não entendi. Você gostaria de ver o cardápio ou fazer um pedido?');
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
      _scrollToBottom();
    });
  }

  // --- MÉTODO _confirmOrder --- (ESSENCIAL)
  Future<void> _confirmOrder() async {
    if (_cartItems.isEmpty) {
      _addBotMessage(
          'Seu carrinho está vazio. Adicione itens antes de confirmar.');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _addBotMessage('Confirmando seu pedido...');

    try {
      final authProvider =
          Provider.of<ChatbotAuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado.');
      }

      // Obter o UID do usuário logado através da instância _auth
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('Usuário Firebase não encontrado.');
      }
      final userId = firebaseUser.uid;

      // Criar lista de itens formatada para o Firestore
      List<Map<String, dynamic>> itemsList = [];
      _cartItems.forEach((itemId, quantity) {
        final item = _menuItems.firstWhere((i) => i.id == itemId,
            orElse: () => MenuItem(
                id: '', name: 'Desconhecido', description: '', price: 0));
        itemsList.add({
          'itemId': itemId,
          'name': item.name,
          'quantity': quantity,
          'price': item.price,
        });
      });

      // Salvar pedido no Firestore
      final orderRef = await _firestore.collection('orders').add({
        'userId': userId, // Usar UID obtido da instância _auth
        'userRa': user.ra.split('@').first, // Salvar apenas o RA
        'userPhone': user.phone,
        'items': itemsList,
        'total': _cartTotal,
        // Salvar lista de descrições
        'descriptions': _orderDescriptions,
        'status': 'pending', // Status inicial
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Guardar o total antes de limpar
      final confirmedTotal = _cartTotal;

      // Limpar carrinho e estado local
      setState(() {
        _cartItems = {};
        _cartTotal = 0.0;
        _orderDescriptions = [];
        _isLoading = false;
      });

      // Navegar para a tela de confirmação
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationScreen(
              orderId: orderRef.id, totalValue: confirmedTotal),
        ),
      );
      // Adicionar mensagem de sucesso após a navegação
      _addBotMessage(
          'Pedido #${orderRef.id.substring(0, 6)} confirmado com sucesso! Obrigado!');
    } catch (e) {
      print('Erro ao confirmar pedido: $e');
      setState(() {
        _isLoading = false;
      });
      _addBotMessage(
          'Desculpe, houve um erro ao confirmar seu pedido. Por favor, tente novamente.');
    }
  }

  // --- MÉTODO build --- (ESSENCIAL)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot da Cantina'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<ChatbotAuthProvider>(context, listen: false)
                  .logout();
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
                if (message.isButton) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 40.0),
                    child: ElevatedButton(
                      onPressed: message.onButtonPressed,
                      child: Text(message.text),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondary, // Cor do botão
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
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
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 14.0),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                      ),
                    ),
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
          const Divider(height: 1.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Digite sua mensagem ou pedido...',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: _isLoading ? null : _addUserMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading
                      ? null
                      : () => _addUserMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );


  // NOVO: Função para verificar se é comando de edição
  bool _isEditDescriptionCommand(String normalizedText) {
    final editKeywords = ['mudar', 'alterar', 'trocar', 'editar'];
    final descriptionKeywords = [
      'descrição',
      'descricao',
      'observação',
      'observacao'
    ];
    final paraKeywords = ['para', 'por'];

    // Padrão: (mudar|alterar|...) (descrição|observação|...) [número] (para|por) [novo texto]
    final regex = RegExp(r'^(' +
        editKeywords.join('|') +
        r')\s+(' +
        descriptionKeywords.join('|') +
        r')\s+(\d+)\s+(' +
        paraKeywords.join('|') +
        r')\s+(.+)$');
    return regex.hasMatch(normalizedText);
  }

  // NOVO: Função para processar comando de edição
  void _processEditDescriptionCommand(String originalText) {
    final normalizedText = _normalizeText(originalText);
    final editKeywords = ['mudar', 'alterar', 'trocar', 'editar'];
    final descriptionKeywords = [
      'descrição',
      'descricao',
      'observação',
      'observacao'
    ];
    final paraKeywords = ['para', 'por'];

    final regex = RegExp(r'^(' +
        editKeywords.join('|') +
        r')\s+(' +
        descriptionKeywords.join('|') +
        r')\s+(\d+)\s+(' +
        paraKeywords.join('|') +
        r')\s+(.+)$');

    final match = regex.firstMatch(normalizedText);
    if (match != null && match.groupCount >= 5) {
      final indexStr = match.group(3);
      final newDescriptionPart = match.group(5);

      if (indexStr != null && newDescriptionPart != null) {
        final index = int.tryParse(indexStr);
        // Extrair a nova descrição do texto original para manter a capitalização
        final originalMatch = RegExp(
                r'^(?:' +
                    editKeywords.join('|') +
                    r')\s+(?:' +
                    descriptionKeywords.join('|') +
                    r')\s+' +
                    indexStr +
                    r'\s+(?:' +
                    paraKeywords.join('|') +
                    r')\s+(.+)$',
                caseSensitive: false)
            .firstMatch(originalText);

        final newDescription =
            originalMatch?.group(1)?.trim() ?? newDescriptionPart.trim();

        if (index != null && index > 0 && index <= _orderDescriptions.length) {
          final oldDescription = _orderDescriptions[index - 1];
          _orderDescriptions[index - 1] = newDescription;
          _addBotMessage(
              'Descrição ${index} alterada de "$oldDescription" para "$newDescription".');
          _showOrderSummary();
        } else {
          _addBotMessage(
              'Número de descrição inválido. Por favor, informe um número entre 1 e ${_orderDescriptions.length}.');
           _showOrderSummary(showButtons: false); // Evitar loop
        }
      } else {
        _addBotMessage(
            'Não consegui entender qual descrição mudar ou qual o novo texto. Use o formato: "mudar descrição [número] para [novo texto]".');
         _showOrderSummary(showButtons: false); // Evitar loop
      }
    } else {
      _addBotMessage(
          'Não consegui entender o comando de mudança de descrição. Use o formato: "mudar descrição [número] para [novo texto]".');
       _showOrderSummary(showButtons: false); // Evitar loop
    }
  }

  // NOVO: Função para verificar se é comando de exclusão
  bool _isDeleteDescriptionCommand(String normalizedText) {
    final deleteKeywords = ['excluir', 'remover', 'tirar', 'apagar'];
    final descriptionKeywords = [
      'descrição',
      'descricao',
      'observação',
      'observacao',
      'item'
    ]; // Inclui 'item' para "excluir item 1" da descrição

    // Padrão: (excluir|remover|...) (descrição|observação|...) [número]
    final regex = RegExp(r'^(' +
        deleteKeywords.join('|') +
        r')\s+(?:' + // Grupo opcional para palavra chave da descrição
        descriptionKeywords.join('|') +
        r'\s+)?(\d+)$'); // Torna a palavra "descrição" opcional
    return regex.hasMatch(normalizedText);
  }

  // NOVO: Função para processar comando de exclusão
  void _processDeleteDescriptionCommand(String originalText) {
    final normalizedText = _normalizeText(originalText);
    final deleteKeywords = ['excluir', 'remover', 'tirar', 'apagar'];
    final descriptionKeywords = [
      'descrição',
      'descricao',
      'observação',
      'observacao',
      'item'
    ];

    final regex = RegExp(r'^(' +
        deleteKeywords.join('|') +
        r')\s+(?:' +
        descriptionKeywords.join('|') +
        r'\s+)?(\d+)$');

    final match = regex.firstMatch(normalizedText);
    if (match != null && match.groupCount >= 2) { // Precisa capturar o número
      final indexStr = match.group(2); // O número é o segundo grupo capturado
      if (indexStr != null) {
        final index = int.tryParse(indexStr);
        if (index != null && index > 0 && index <= _orderDescriptions.length) {
          final removedDescription = _orderDescriptions.removeAt(index - 1);
          _addBotMessage('Descrição ${index} ("$removedDescription") removida.');
          _showOrderSummary();
        } else {
          _addBotMessage(
              'Número de descrição inválido. Por favor, informe um número entre 1 e ${_orderDescriptions.length}.');
          _showOrderSummary(showButtons: false); // Mostra resumo sem botões para evitar loop
        }
      } else {
         // Este caso não deveria ocorrer com a regex atual se houver match
        _addBotMessage(
            'Não consegui identificar o número da descrição para excluir. Use o formato: "excluir [número]".');
         _showOrderSummary(showButtons: false);
      }
    } else {
      // Mensagem de erro genérica se o comando não corresponder exatamente
       _addBotMessage(
           'Não consegui entender o comando de exclusão. Use o formato: "excluir [número]" ou "excluir descrição [número]".');
       _showOrderSummary(showButtons: false);
    }
  }
}
