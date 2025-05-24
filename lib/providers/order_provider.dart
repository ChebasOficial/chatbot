import 'package:flutter/material.dart';
import 'package:chatbot/models/order.dart';
import 'package:chatbot/models/order_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];

  List<Order> get orders => _orders;

  // Getters para filtrar pedidos por status
  List<Order> get pendingOrders => _orders
      .where((order) => order.status == OrderStatus.pending.value)
      .toList();

  List<Order> get inProgressOrders => _orders
      .where((order) => order.status == OrderStatus.inProgress.value)
      .toList();

  List<Order> get completedOrders => _orders
      .where((order) => order.status == OrderStatus.completed.value)
      .toList();

  List<Order> get archivedOrders => _orders
      .where((order) => order.status == OrderStatus.archived.value)
      .toList();

  // Getters para calcular totais
  double get pendingTotal =>
      pendingOrders.fold(0, (sum, order) => sum + order.total);

  double get inProgressTotal =>
      inProgressOrders.fold(0, (sum, order) => sum + order.total);

  double get completedTotal =>
      completedOrders.fold(0, (sum, order) => sum + order.total);

  double get dayTotal => pendingTotal + inProgressTotal + completedTotal;

  // Inicializar o provider carregando os pedidos do armazenamento local
  Future<void> initialize() async {
    await loadOrders();
  }

  // Adicionar um novo pedido
  Future<void> addOrder(Order order) async {
    _orders.add(order);
    await _saveOrders();
    notifyListeners();
  }

  // Atualizar o status de um pedido usando OrderStatus enum
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      _orders[orderIndex].orderStatus = newStatus;
      await _saveOrders();
      notifyListeners();
    }
  }

  // Cancelar um pedido (remove da lista)
  Future<void> cancelOrder(String orderId) async {
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      _orders.removeAt(orderIndex);
      await _saveOrders();
      notifyListeners();
    }
  }

  // Arquivar um pedido (muda status para archived)
  Future<void> archiveOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.archived);
  }

  // Carregar pedidos do armazenamento local
  Future<void> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getString('orders');

    if (ordersJson != null) {
      final List<dynamic> decodedOrders = jsonDecode(ordersJson);
      _orders = decodedOrders.map((order) => Order.fromJson(order)).toList();
      notifyListeners();
    }
  }

  // Salvar pedidos no armazenamento local
  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson =
        jsonEncode(_orders.map((order) => order.toJson()).toList());
    await prefs.setString('orders', ordersJson);
  }

  // Limpar todos os pedidos (para testes)
  Future<void> clearOrders() async {
    _orders = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('orders');
    notifyListeners();
  }
}
