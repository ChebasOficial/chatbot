import 'package:chatbot/models/menu_item.dart';

class OrderItem {
  final MenuItem menuItem;
  final int quantity;

  OrderItem({
    required this.menuItem,
    required this.quantity,
  });

  double get total => menuItem.price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
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

class Order {
  String id;
  final String ra;
  final DateTime timestamp;
  final List<OrderItem> items;
  double total;
  String status; // 'pending', 'preparing', 'completed'

  Order({
    required this.id,
    required this.ra,
    required this.timestamp,
    required this.items,
    required this.total,
    required this.status,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      ra: json['ra'],
      timestamp: DateTime.parse(json['timestamp']),
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      total: json['total'].toDouble(),
      status: json['status'],
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
    };
  }
}
