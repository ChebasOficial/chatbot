import 'package:chatbot/models/menu_item.dart';
import 'package:chatbot/models/order_status.dart';

class PoliedroOrderItem {
  final MenuItem menuItem;
  final int quantity;

  PoliedroOrderItem({
    required this.menuItem,
    required this.quantity,
  });

  // Getters para facilitar acesso aos dados do menuItem
  String get name => menuItem.name;
  double get price => menuItem.price;
  double get total => menuItem.price * quantity;

  factory PoliedroOrderItem.fromJson(Map<String, dynamic> json) {
    return PoliedroOrderItem(
      menuItem: MenuItem.fromJson(json['menuItem']),
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItem': menuItem.toJson(),
      'quantity': quantity,
    };
  }
}

// Classe para representar o usuário do pedido
class PoliedroOrderUser {
  final String ra;
  final String phone;
  
  PoliedroOrderUser({
    required this.ra,
    this.phone = '',
  });
  
  factory PoliedroOrderUser.fromJson(Map<String, dynamic> json) {
    return PoliedroOrderUser(
      ra: json['ra'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'ra': ra,
      'phone': phone,
    };
  }
}

class PoliedroOrder {
  String id;
  final String ra;
  final DateTime timestamp;
  final List<PoliedroOrderItem> items;
  double total;
  String status; // 'pending', 'inProgress', 'completed', 'archived'
  String notes; // Observações do pedido
  String orderNumber; // Número do pedido (000-999)
  String _phone = ''; // Telefone do usuário
  
  // Campos explícitos para evitar problemas de reconhecimento de getters
  final PoliedroOrderUser _user;
  final String _formattedDate;
  final String _description;

  PoliedroOrder({
    required this.id,
    required this.ra,
    required this.timestamp,
    required this.items,
    required this.total,
    required this.status,
    this.notes = '',
    required this.orderNumber,
    String phone = '',
  }) : _user = PoliedroOrderUser(ra: ra, phone: phone),
       _formattedDate = '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
       _description = items.map((item) => '${item.quantity}x ${item.name}').join(', ') {
    _phone = phone;
  }
  
  // Getter para obter o usuário do pedido
  PoliedroOrderUser get user => _user;
  
  // Getter para obter a data formatada
  String get formattedDate => _formattedDate;
  
  // Getter para obter a descrição do pedido
  String get description => _description;

  // Converter String status para OrderStatus enum
  OrderStatus get orderStatus => OrderStatusExtension.fromString(status);
  
  // Atualizar status a partir da enum
  set orderStatus(OrderStatus newStatus) {
    status = newStatus.value;
  }

  factory PoliedroOrder.fromJson(Map<String, dynamic> json) {
    // Tratamento robusto para o campo timestamp que pode vir em diferentes formatos
    DateTime timestamp;
    final timestampData = json['timestamp'];
    
    if (timestampData == null) {
      // Se não houver timestamp, usar data atual
      timestamp = DateTime.now();
    } else if (timestampData is int) {
      // Se for um inteiro (milissegundos desde a época)
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampData);
    } else if (timestampData is String) {
      // Se for uma string ISO
      timestamp = DateTime.parse(timestampData);
    } else {
      // Para outros casos (como Timestamp do Firestore), converter para string e depois para DateTime
      try {
        timestamp = DateTime.parse(timestampData.toString());
      } catch (e) {
        // Fallback para data atual em caso de erro
        print('Erro ao converter timestamp: $e');
        timestamp = DateTime.now();
      }
    }
    
    final items = (json['items'] as List)
        .map((item) => PoliedroOrderItem.fromJson(item))
        .toList();
    final phone = json['phone'] ?? '';
    
    return PoliedroOrder(
      id: json['id'],
      ra: json['ra'],
      timestamp: timestamp,
      items: items,
      total: json['total'].toDouble(),
      status: json['status'],
      notes: json['notes'] ?? '',
      orderNumber: json['orderNumber'] ?? '000',
      phone: phone,
    );
  }

  Map<String, dynamic> toJson() {
    // Imprimir para debug
    print('Convertendo pedido para JSON - ID: $id, RA: $ra, OrderNumber: $orderNumber');
    
    return {
      'id': id,
      'ra': ra,
      'timestamp': timestamp.millisecondsSinceEpoch,  // Converter para milissegundos para evitar problemas de tipo
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status,
      'notes': notes,
      'orderNumber': orderNumber,
      'phone': _phone,
      // Adicionar campos explícitos para garantir compatibilidade com a tela admin
      'userEmail': ra,  // Garantir que userEmail também esteja disponível
      'description': notes,  // Garantir que description também esteja disponível
    };
  }
}
