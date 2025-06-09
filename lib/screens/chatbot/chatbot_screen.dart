import 'package:flutter/material.dart';
import 'package:chatbot/models/chat_message.dart';
import 'package:chatbot/models/menu_item.dart';
import 'package:chatbot/models/order.dart';
import 'package:chatbot/models/order_status.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/providers/menu_provider.dart';
import 'package:chatbot/providers/order_provider.dart';
import 'package:chatbot/config/style_guide.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<PoliedroOrderItem> _cart = [];
  String _orderDescription = '';
  bool _isInitialized = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeChat() {
    // Adicionar um pequeno atraso para garantir que o widget esteja completamente montado
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        // Adicionar mensagens iniciais apenas se a lista estiver vazia
        if (_messages.isEmpty) {
          _messages.add(
            ChatMessage(
              text: 'Olá! Bem-vindo ao Poliedro Food!',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _messages.add(
            ChatMessage(
              text: 'O que você gostaria de pedir hoje?',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );

          _isInitialized = true;
        }
      });

      // Carregar o menu
      _loadMenu();
    });
  }

  Future<void> _loadMenu() async {
    try {
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);
      await menuProvider.loadMenuItems();

      if (!mounted) return;

      // Verificar se o menu foi carregado com sucesso
      if (menuProvider.menuItems.isNotEmpty) {
        setState(() {
          // Adicionar mensagem com o cardápio
          _addBotMessage(_buildMenuText(menuProvider.menuItems));
        });
      } else {
        // Adicionar mensagem de erro se o menu estiver vazio
        _addBotMessage(
            'Desculpe, não consegui carregar o cardápio. Por favor, tente novamente mais tarde.');
      }
    } catch (e) {
      if (!mounted) return;

      // Adicionar mensagem de erro em caso de exceção
      _addBotMessage(
          'Desculpe, ocorreu um erro ao carregar o cardápio. Por favor, tente novamente mais tarde.');
      print('Erro ao carregar menu: $e');
    }
  }

  String _buildMenuText(List<MenuItem> menuItems) {
    final buffer = StringBuffer();
    buffer.writeln('Cardápio:');
    buffer.writeln();

    for (var item in menuItems) {
      buffer.writeln('${item.name} - R\$ ${item.price.toStringAsFixed(2)}');
      buffer.writeln(item.description);
      buffer.writeln();
    }

    buffer.writeln(
        'Para pedir, digite o nome do item e a quantidade. Por exemplo: "2 hambúrgueres" ou "quero um suco de laranja"');

    return buffer.toString();
  }

  void _addBotMessage(String text) {
    if (!mounted) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    if (!mounted) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    // Adicionar um pequeno atraso para garantir que a lista foi atualizada
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          print('Erro ao rolar para o final: $e');
        }
      }
    });
  }

  void _handleSendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _addUserMessage(text);
    _messageController.clear();

    // Processar a mensagem do usuário
    _processUserMessage(text);
  }

  void _processUserMessage(String text) {
    // Verificar se é um comando para ver o cardápio
    if (_isViewMenuCommand(text)) {
      _loadMenu();
      return;
    }

    // Verificar se é um comando para adicionar descrição ao pedido
    if (_isAddDescriptionCommand(text)) {
      _addOrderDescription(text);
      return;
    }

    // Verificar se é um comando para confirmar o pedido
    if (_isConfirmOrderCommand(text)) {
      _confirmOrder();
      return;
    }

    // Verificar se é um comando para cancelar o pedido
    if (_isCancelOrderCommand(text)) {
      _cancelOrder();
      return;
    }

    // Verificar se é um comando para sair/logout
    if (_isLogoutCommand(text)) {
      _showLogoutConfirmation();
      return;
    }

    // Tentar identificar um pedido
    final orderItems = _identifyOrderItems(text);
    if (orderItems.isNotEmpty) {
      _addToCart(orderItems);
      return;
    }

    // Se chegou aqui, não entendeu o comando
    _addBotMessage('Desculpe, não entendi. Você pode:');
    _addBotMessage('Escolha uma opção:');
  }

  bool _isViewMenuCommand(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains('cardápio') ||
        lowerText.contains('cardapio') ||
        lowerText.contains('menu') ||
        lowerText.contains('ver opções') ||
        lowerText.contains('ver opcoes');
  }

  bool _isAddDescriptionCommand(String text) {
    if (_cart.isEmpty) return false;

    final lowerText = text.toLowerCase();
    return lowerText.contains('observação') ||
        lowerText.contains('observacao') ||
        lowerText.contains('descrição') ||
        lowerText.contains('descricao') ||
        lowerText.contains('nota') ||
        lowerText.contains('com ') ||
        lowerText.contains('sem ');
  }

  bool _isConfirmOrderCommand(String text) {
    if (_cart.isEmpty) return false;

    final lowerText = text.toLowerCase();
    return lowerText.contains('confirmar') ||
        lowerText.contains('finalizar') ||
        lowerText.contains('concluir') ||
        lowerText.contains('fechar') ||
        lowerText.contains('pronto');
  }

  bool _isCancelOrderCommand(String text) {
    if (_cart.isEmpty) return false;

    final lowerText = text.toLowerCase();
    return lowerText.contains('cancelar') ||
        lowerText.contains('limpar') ||
        lowerText.contains('esvaziar') ||
        lowerText.contains('remover tudo');
  }

  void _cancelOrder() {
    setState(() {
      _cart.clear();
      _orderDescription = '';
    });

    _addBotMessage('Seu pedido foi cancelado. O carrinho está vazio.');
    _addBotMessage('O que você gostaria de pedir hoje?');
  }

  bool _isLogoutCommand(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains('sair') ||
        lowerText.contains('logout') ||
        lowerText.contains('deslogar') ||
        lowerText.contains('encerrar');
  }

  List<PoliedroOrderItem> _identifyOrderItems(String text) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final menuItems = menuProvider.menuItems;
    final List<PoliedroOrderItem> result = [];

    // Normalizar o texto para facilitar a comparação
    String normalizedText = _normalizeText(text);

    // Imprimir para debug
    print('Texto normalizado para identificação: "$normalizedText"');
    print(
        'Itens disponíveis no menu: ${menuItems.map((item) => item.name).toList()}');

    // Verificar explicitamente por "pao", "pão", "paes", "pães" ou "paos" antes de processar outros itens
    if (normalizedText.contains("pao") ||
        normalizedText.contains("pão") ||
        normalizedText.contains("paes") ||
        normalizedText.contains("pães") ||
        normalizedText.contains("paos")) {
      // Buscar o item "pao" no menu
      MenuItem? paoItem;
      try {
        paoItem = menuItems.firstWhere(
          (item) =>
              _normalizeText(item.name) == "pao" ||
              _normalizeText(item.name) == "pão",
        );
        print('Item "pão" encontrado no menu: ${paoItem.name}');
      } catch (e) {
        // Item não encontrado, continuar com o processamento normal
        print('Item "pão" não encontrado no menu: $e');
      }

      if (paoItem != null) {
        // Extrair quantidade - verificar todas as variações possíveis
        int quantity = 0;

        // Verificar todas as variações possíveis
        for (var form in ["pao", "pão", "paes", "pães", "paos"]) {
          if (normalizedText.contains(form)) {
            int extractedQuantity = _extractQuantity(normalizedText, form);
            if (extractedQuantity > 0) {
              quantity = extractedQuantity;
              print('Quantidade extraída para "$form": $quantity');
              break;
            }
          }
        }

        // Se não encontrou quantidade, usar 1 como padrão
        if (quantity <= 0) {
          quantity = 1;
          print('Usando quantidade padrão: 1');
        }

        result.add(PoliedroOrderItem(
          menuItem: paoItem,
          quantity: quantity,
        ));

        print('Adicionado ao carrinho: ${quantity}x ${paoItem.name}');

        // Remover o item encontrado do texto para evitar duplicações
        normalizedText = normalizedText
            .replaceAll("paes", "")
            .replaceAll("pães", "")
            .replaceAll("paos", "")
            .replaceAll("pao", "")
            .replaceAll("pão", "");
      }
    }

    // Extrair quantidade e nome do item para os demais itens
    for (var menuItem in menuItems) {
      // Normalizar o nome do item para facilitar a comparação
      String normalizedItemName = _normalizeText(menuItem.name);

      // Pular "pao" se já processamos "paes"
      if ((normalizedItemName == "pao" || normalizedItemName == "pão") &&
          result.any((item) =>
              _normalizeText(item.menuItem.name) == normalizedItemName)) {
        continue;
      }

      // Verificar plurais irregulares
      List<String> possibleForms = _getPossibleForms(normalizedItemName);
      print('Formas possíveis para "$normalizedItemName": $possibleForms');

      for (var form in possibleForms) {
        if (normalizedText.contains(form)) {
          // Encontrou um item do menu
          int quantity = _extractQuantity(normalizedText, form);
          print('Item encontrado: "$form", quantidade: $quantity');

          result.add(PoliedroOrderItem(
            menuItem: menuItem,
            quantity: quantity,
          ));

          // Remover o item encontrado do texto para evitar duplicações
          normalizedText = normalizedText.replaceAll(form, "");
          break;
        }
      }
    }

    return result;
  }

  String _normalizeText(String text) {
    // Remover acentos e converter para minúsculas
    String normalized = text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');

    return normalized;
  }

  List<String> _getPossibleForms(String itemName) {
    List<String> forms = [itemName];

    // Adicionar formas plurais comuns
    if (itemName.endsWith('ao')) {
      // pão -> pães, pao -> paes
      forms.add(itemName.substring(0, itemName.length - 2) + 'aes');
    } else if (itemName.endsWith('el')) {
      // pastel -> pastéis, pasteis
      forms.add(itemName.substring(0, itemName.length - 2) + 'eis');
    } else if (itemName.endsWith('il')) {
      // mil -> mis
      forms.add(itemName.substring(0, itemName.length - 2) + 'is');
    } else if (itemName.endsWith('r')) {
      // hambúrguer -> hambúrgueres
      forms.add(itemName + 'es');
    } else if (itemName.endsWith('m')) {
      // homem -> homens
      forms.add(itemName.substring(0, itemName.length - 1) + 'ns');
    } else {
      // Plural regular
      forms.add(itemName + 's');
    }

    // Casos específicos com tratamento especial
    if (itemName == 'pao' || itemName == 'pão') {
      forms.clear(); // Limpar para evitar duplicações
      forms.add('pao');
      forms.add('pão');
      forms.add('paes');
      forms.add('pães');
      forms.add('paos'); // Adicionando variação comum
    }

    return forms;
  }

  int _extractQuantity(String text, String itemName) {
    // Imprimir para debug
    print('Extraindo quantidade para "$itemName" do texto: "$text"');

    // Padrão: número seguido do nome do item
    RegExp regExp = RegExp(r'(\d+)\s*' + itemName);
    var match = regExp.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      int quantity = int.parse(match.group(1)!);
      print('Quantidade encontrada via regex: $quantity');
      return quantity;
    }

    // Verificar números por extenso
    Map<String, int> numberWords = {
      'um': 1,
      'uma': 1,
      'dois': 2,
      'duas': 2,
      'tres': 3,
      'três': 3,
      'quatro': 4,
      'cinco': 5,
      'seis': 6,
      'sete': 7,
      'oito': 8,
      'nove': 9,
      'dez': 10
    };

    for (var entry in numberWords.entries) {
      if (text.contains(entry.key + ' ' + itemName) ||
          text.contains(entry.key + itemName)) {
        print('Quantidade encontrada por extenso: ${entry.value}');
        return entry.value;
      }
    }

    // Verificar se há um número no início do texto (caso comum: "3 pao")
    RegExp startNumberRegExp = RegExp(r'^\s*(\d+)\s+');
    var startMatch = startNumberRegExp.firstMatch(text);
    if (startMatch != null && startMatch.groupCount >= 1) {
      int quantity = int.parse(startMatch.group(1)!);
      print('Quantidade encontrada no início do texto: $quantity');
      return quantity;
    }

    // Padrão não encontrado, assumir quantidade 1
    print('Nenhum padrão de quantidade encontrado, usando padrão: 1');
    return 1;
  }

  void _addToCart(List<PoliedroOrderItem> items) {
    if (items.isEmpty) return;

    setState(() {
      for (var item in items) {
        // Verificar se o item já está no carrinho
        int existingIndex = _cart
            .indexWhere((cartItem) => cartItem.menuItem.id == item.menuItem.id);

        if (existingIndex >= 0) {
          // Atualizar quantidade
          _cart[existingIndex] = PoliedroOrderItem(
            menuItem: _cart[existingIndex].menuItem,
            quantity: _cart[existingIndex].quantity + item.quantity,
          );
        } else {
          // Adicionar novo item
          _cart.add(item);
        }
      }
    });

    // Confirmar adição ao carrinho
    if (items.length == 1) {
      _addBotMessage(
          'Adicionei ${items[0].quantity} ${items[0].menuItem.name} ao seu pedido.');
    } else {
      _addBotMessage('Adicionei os itens ao seu pedido.');
    }

    // Mostrar resumo do pedido
    _showOrderSummary();
  }

  void _addOrderDescription(String text) {
    // Extrair a descrição do texto
    String description = text;

    // Remover palavras-chave comuns
    List<String> keywordsToRemove = [
      'observação',
      'observacao',
      'descrição',
      'descricao',
      'nota',
      'adicionar',
      'incluir'
    ];

    for (var keyword in keywordsToRemove) {
      description = description.replaceAll(keyword, '').trim();
    }

    setState(() {
      _orderDescription = description;
    });

    _addBotMessage('Adicionei a observação: "$description" ao seu pedido.');
    _showOrderSummary();
  }

  // Solicitar ao usuário que adicione uma descrição
  void _promptForDescription() {
    _addBotMessage(
        'Por favor, digite a descrição ou observação para o seu pedido:');
  }

  // Mostrar opções para editar ou excluir a descrição
  void _showEditDescriptionOptions() {
    if (_orderDescription.isEmpty) {
      _promptForDescription();
      return;
    }

    _addBotMessage('Descrição atual: "$_orderDescription"');

    // Adicionar botões para modificar ou excluir a descrição
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      List<ChatAction> actions = [
        ChatAction(
          label: 'Modificar Descrição',
          action: () {
            _addBotMessage('Digite a nova descrição para substituir a atual:');
          },
        ),
        ChatAction(
          label: 'Excluir Descrição',
          action: () {
            setState(() {
              _orderDescription = '';
            });
            _addBotMessage('Descrição removida com sucesso!');
            _showOrderSummary();
          },
        ),
        ChatAction(
          label: 'Voltar',
          action: () {
            _showOrderSummary();
          },
        ),
      ];

      setState(() {
        _messages.add(
          ChatMessage(
            text: 'O que você deseja fazer com a descrição?',
            isUser: false,
            timestamp: DateTime.now(),
            isActionButtons: true,
            actions: actions,
          ),
        );
      });

      // Garantir que a tela role para mostrar os botões
      _scrollToBottom();
    });
  }

  // Mostrar opções para remover itens do carrinho
  void _showRemoveItemOptions() {
    if (_cart.isEmpty) {
      _addBotMessage('Seu carrinho está vazio. Não há itens para remover.');
      return;
    }

    _addBotMessage('Selecione o item que deseja remover:');

    // Adicionar botões para cada item no carrinho
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      List<ChatAction> actions = [];

      // Adicionar um botão para cada item no carrinho
      for (int i = 0; i < _cart.length; i++) {
        final item = _cart[i];
        actions.add(
          ChatAction(
            label: '${item.quantity}x ${item.menuItem.name}',
            action: () {
              _removeItemFromCart(i);
            },
          ),
        );
      }

      // Adicionar botão para voltar
      actions.add(
        ChatAction(
          label: 'Voltar',
          action: () {
            _showOrderSummary();
          },
        ),
      );

      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Escolha um item para remover:',
            isUser: false,
            timestamp: DateTime.now(),
            isActionButtons: true,
            actions: actions,
          ),
        );
      });

      // Garantir que a tela role para mostrar os botões
      _scrollToBottom();
    });
  }

  // Remover um item específico do carrinho
  void _removeItemFromCart(int index) {
    if (index < 0 || index >= _cart.length) return;

    final removedItem = _cart[index];

    setState(() {
      _cart.removeAt(index);
    });

    _addBotMessage(
        'Removi ${removedItem.quantity}x ${removedItem.menuItem.name} do seu pedido.');

    // Mostrar resumo atualizado
    _showOrderSummary();
  }

  void _showOrderSummary() {
    if (_cart.isEmpty) {
      _addBotMessage('Seu carrinho está vazio.');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Resumo do seu pedido:');
    buffer.writeln();

    double total = 0;

    for (var item in _cart) {
      double itemTotal = item.menuItem.price * item.quantity;
      buffer.writeln(
          '${item.quantity} x ${item.menuItem.name} - R\$ ${itemTotal.toStringAsFixed(2)}');
      total += itemTotal;
    }

    buffer.writeln();

    // Adicionar descrição/observações se existir
    if (_orderDescription.isNotEmpty) {
      buffer.writeln('Observações: $_orderDescription');
      buffer.writeln();
    }

    buffer.writeln('Total: R\$ ${total.toStringAsFixed(2)}');

    _addBotMessage(buffer.toString());
    _addBotMessage('O que deseja fazer?');

    // Adicionar opções explícitas para o usuário como botões
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      // Criar ações para os botões - chamando diretamente as funções corretas
      List<ChatAction> actions = [
        ChatAction(
          label: 'Confirmar Pedido',
          action: () {
            // Chamar diretamente a função de confirmação em vez de processar texto
            _confirmOrder();
          },
        ),
        ChatAction(
          label: 'Adicionar Item',
          action: () {
            // Mostrar o cardápio automaticamente ao clicar em adicionar
            _addBotMessage(
                'O que mais você gostaria de adicionar ao seu pedido?');
            _loadMenu(); // Carregar e exibir o cardápio
          },
        ),
        // Mostrar botão "Adicionar Descrição" apenas se não houver descrição
        if (_orderDescription.isEmpty)
          ChatAction(
            label: 'Adicionar Descrição',
            action: () {
              // Solicitar ao usuário que adicione uma descrição
              _promptForDescription();
            },
          ),
        // Mostrar botão "Editar Descrição" apenas se já houver descrição
        if (_orderDescription.isNotEmpty)
          ChatAction(
            label: 'Editar Descrição',
            action: () {
              // Mostrar opções para editar ou excluir a descrição
              _showEditDescriptionOptions();
            },
          ),
        ChatAction(
          label: 'Remover Item',
          action: () {
            // Mostrar opções para remover itens
            _showRemoveItemOptions();
          },
        ),
        ChatAction(
          label: 'Cancelar Pedido',
          action: () {
            // Chamar diretamente a função de cancelamento em vez de processar texto
            _cancelOrder();
          },
        ),
      ];

      // Adicionar mensagem com botões
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Digite "confirmar" para finalizar o pedido, "adicionar" para incluir mais itens, ou "cancelar" para limpar o carrinho.',
            isUser: false,
            timestamp: DateTime.now(),
            isActionButtons: true,
            actions: actions,
          ),
        );
      });

      // Garantir que a tela role para mostrar os botões
      _scrollToBottom();
    });
  }

  Future<void> _confirmOrder() async {
    if (_cart.isEmpty) {
      _addBotMessage(
          'Seu carrinho está vazio. Adicione itens antes de confirmar o pedido.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Iniciando confirmação do pedido...');

      // Obter o próximo número de pedido
      int orderNumber = await _getNextOrderNumber();
      print('Número do pedido obtido: $orderNumber');

      // Calcular o total do pedido
      double total = _cart.fold(
          0, (sum, item) => sum + (item.menuItem.price * item.quantity));
      print('Total do pedido: $total');

      // Obter informações do usuário
      final authProvider =
          Provider.of<ChatbotAuthProvider>(context, listen: false);
      final userEmail = authProvider.currentUser?.ra ?? '';
      final userPhone = authProvider.cachedPhone ?? '';
      print('Informações do usuário - RA: $userEmail, Telefone: $userPhone');

      // Criar o pedido
      final orderId = const Uuid().v4();
      print('ID do pedido gerado: $orderId');

      // Imprimir itens do carrinho para debug
      print('Itens no carrinho:');
      for (var item in _cart) {
        print(
            '- ${item.quantity}x ${item.menuItem.name} (R\$ ${item.menuItem.price})');
      }

      final order = PoliedroOrder(
        id: orderId,
        ra: userEmail,
        timestamp: DateTime.now(),
        items: List<PoliedroOrderItem>.from(
            _cart), // Criar uma cópia da lista para evitar problemas de referência
        total: total,
        status: OrderStatus.pending.value,
        notes: _orderDescription,
        orderNumber: orderNumber.toString(),
        phone: userPhone,
      );

      print('Pedido criado com sucesso. Salvando no Firebase...');

      // Salvar o pedido
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.addOrder(order);

      print('Pedido salvo com sucesso no Firebase!');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _cart.clear();
        _orderDescription = '';
      });

      print('Navegando para a tela de confirmação...');

      // Navegar para a tela de confirmação
      try {
        // Usar Future.delayed para garantir que a navegação ocorra após a conclusão do setState
        Future.delayed(Duration.zero, () {
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/confirmation',
              arguments: {
                'title': 'Pedido #$orderNumber Confirmado!',
                'message':
                    'Seu pedido foi registrado com sucesso.\nTotal: R\$ ${total.toStringAsFixed(2)}',
                'buttonText': 'Voltar ao Menu',
                'onConfirm': () =>
                    Navigator.pushReplacementNamed(context, '/chatbot'),
              },
            ).catchError((error) {
              print('Erro ao navegar para tela de confirmação: $error');
              // Fallback: mostrar confirmação diretamente no chatbot
              _addBotMessage('✅ Pedido #$orderNumber confirmado com sucesso!');
              _addBotMessage('Total: R\$ ${total.toStringAsFixed(2)}');
              _addBotMessage('O que mais você gostaria de pedir hoje?');
            });
          }
        });
      } catch (e) {
        print('Exceção ao tentar navegar: $e');
        // Fallback: mostrar confirmação diretamente no chatbot
        _addBotMessage('✅ Pedido #$orderNumber confirmado com sucesso!');
        _addBotMessage('Total: R\$ ${total.toStringAsFixed(2)}');
        _addBotMessage('O que mais você gostaria de pedir hoje?');
      }

      print('Navegação para tela de confirmação iniciada');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      print('ERRO AO CONFIRMAR PEDIDO: $e');
      print('Stack trace: ${StackTrace.current}');

      _addBotMessage(
          'Desculpe, ocorreu um erro ao confirmar seu pedido. Por favor, tente novamente.');
    }
  }

  Future<int> _getNextOrderNumber() async {
    try {
      // Obter o contador atual
      DocumentSnapshot counterDoc = await FirebaseFirestore.instance
          .collection('counters')
          .doc('order_number')
          .get();

      int currentValue = 0;

      // Se o documento existir, obter o valor atual
      if (counterDoc.exists) {
        currentValue =
            (counterDoc.data() as Map<String, dynamic>)['value'] ?? 0;
      }

      // Incrementar o contador
      int nextValue = currentValue + 1;

      // Atualizar o contador no Firestore
      await FirebaseFirestore.instance
          .collection('counters')
          .doc('order_number')
          .set({'value': nextValue});

      return nextValue;
    } catch (e) {
      print('Erro ao obter número do pedido: $e');
      // Gerar um número aleatório em caso de erro
      return DateTime.now().millisecondsSinceEpoch % 1000;
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final authProvider =
          Provider.of<ChatbotAuthProvider>(context, listen: false);
      await authProvider.logout();

      if (!mounted) return;

      // Navegar para a tela de login
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Erro ao fazer logout: $e');
      _addBotMessage(
          'Desculpe, ocorreu um erro ao sair. Por favor, tente novamente.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar se as mensagens iniciais foram adicionadas
    if (!_isInitialized && !_isLoading) {
      _initializeChat();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poliedro Food'),
        backgroundColor: PoliedroFoodStyle.primaryBlue,
        automaticallyImplyLeading: false, // Remove a seta de volta
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Lista de mensagens
                Expanded(
                  child: _buildMessageList(),
                ),
                // Campo de entrada
                _buildInputField(),
              ],
            ),
    );
  }

  Widget _buildMessageList() {
    return Container(
      width: double.infinity,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          if (index < 0 || index >= _messages.length) {
            return const SizedBox.shrink();
          }

          final message = _messages[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // Se for uma mensagem com botões de ação
    if (!message.isUser && message.isActionButtons && message.actions != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mensagem normal
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 8.0),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: PoliedroFoodStyle.backgroundLight,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botões de ação
          Container(
            margin: const EdgeInsets.only(top: 8.0, bottom: 16.0, left: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: message.actions!.map((action) {
                return ElevatedButton(
                  onPressed: action.action,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PoliedroFoodStyle.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: Text(action.label),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    // Mensagem normal (usuário ou bot)
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) const SizedBox(width: 8.0),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: message.isUser
                    ? PoliedroFoodStyle.primaryBlue
                    : PoliedroFoodStyle.backgroundLight,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8.0),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Campo de texto
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: PoliedroFoodStyle.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          // Botão de enviar
          Container(
            margin: const EdgeInsets.only(left: 8.0),
            decoration: BoxDecoration(
              color: PoliedroFoodStyle.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              onPressed: _handleSendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
