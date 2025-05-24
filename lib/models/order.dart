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
    final timestamp = DateTime.parse(json['timestamp']);
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
    return {
      'id': id,
      'ra': ra,
      'timestamp': timestamp.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status,
      'notes': notes,
      'orderNumber': orderNumber,
      'phone': _phone,
    };
  }
}
