import 'package:flutter/material.dart';
import 'package:chatbot/models/order.dart';
import 'package:chatbot/models/order_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:async';

class OrderProvider extends ChangeNotifier {
  List<PoliedroOrder> _orders = [];
  bool _isKitchenAuthenticated = false;
  final StreamController<List<PoliedroOrder>> _ordersStreamController = StreamController<List<PoliedroOrder>>.broadcast();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PoliedroOrder> get orders => _orders;
  bool get isKitchenAuthenticated => _isKitchenAuthenticated;

  // Getters para filtrar pedidos por status
  List<PoliedroOrder> get pendingOrders =>
      _orders.where((order) => order.status == OrderStatus.pending.value).toList();
  
  List<PoliedroOrder> get inProgressOrders =>
      _orders.where((order) => order.status == OrderStatus.inProgress.value).toList();
  
  List<PoliedroOrder> get completedOrders =>
      _orders.where((order) => order.status == OrderStatus.completed.value).toList();
  
  List<PoliedroOrder> get archivedOrders =>
      _orders.where((order) => order.status == OrderStatus.archived.value).toList();

  // Getters para calcular totais
  double get pendingTotal =>
      pendingOrders.fold(0, (sum, order) => sum + order.total);
  
  double get inProgressTotal =>
      inProgressOrders.fold(0, (sum, order) => sum + order.total);
  
  double get completedTotal =>
      completedOrders.fold(0, (sum, order) => sum + order.total);
  
  double get dayTotal => pendingTotal + inProgressTotal + completedTotal;

  // Inicializar o provider carregando os pedidos do Firestore
  Future<void> initialize() async {
    await loadOrdersFromFirestore();
  }

  // Adicionar um novo pedido
  Future<void> addOrder(PoliedroOrder order) async {
    try {
      // Adicionar ao Firestore
      await _firestore.collection('orders').doc(order.id).set(order.toJson());
      
      // Adicionar à lista local
      _orders.add(order);
      
      // Atualizar o stream de pedidos
      _ordersStreamController.add(_orders);
      
      notifyListeners();
    } catch (e) {
      print('Erro ao adicionar pedido: $e');
      // Fallback para armazenamento local se o Firestore falhar
      _orders.add(order);
      await _saveOrders();
      notifyListeners();
    }
  }

  // Atualizar o status de um pedido usando OrderStatus enum
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      // Atualizar no Firestore
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.value
      });
      
      // Atualizar na lista local
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex].orderStatus = newStatus;
        
        // Atualizar o stream de pedidos
        _ordersStreamController.add(_orders);
        
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao atualizar status do pedido: $e');
      // Fallback para armazenamento local se o Firestore falhar
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex].orderStatus = newStatus;
        await _saveOrders();
        notifyListeners();
      }
    }
  }

  // Cancelar um pedido (remove da lista)
  Future<void> cancelOrder(String orderId) async {
    try {
      // Remover do Firestore
      await _firestore.collection('orders').doc(orderId).delete();
      
      // Remover da lista local
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        _orders.removeAt(orderIndex);
        
        // Atualizar o stream de pedidos
        _ordersStreamController.add(_orders);
        
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao cancelar pedido: $e');
      // Fallback para armazenamento local se o Firestore falhar
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        _orders.removeAt(orderIndex);
        await _saveOrders();
        notifyListeners();
      }
    }
  }

  // Arquivar um pedido (muda status para archived)
  Future<void> archiveOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.archived);
  }

  // Carregar pedidos do Firestore
  Future<void> loadOrdersFromFirestore() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      
      _orders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Garantir que o ID do documento seja usado
        return PoliedroOrder.fromJson(data);
      }).toList();
      
      // Atualizar o stream de pedidos
      _ordersStreamController.add(_orders);
      
      notifyListeners();
    } catch (e) {
      print('Erro ao carregar pedidos do Firestore: $e');
      // Fallback para armazenamento local se o Firestore falhar
      await loadOrders();
    }
  }

  // Carregar pedidos do armazenamento local (fallback)
  Future<void> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = prefs.getString('orders');

    if (ordersJson != null) {
      final List<dynamic> decodedOrders = jsonDecode(ordersJson);
      _orders = decodedOrders.map((order) => PoliedroOrder.fromJson(order)).toList();
      notifyListeners();
    }
  }

  // Salvar pedidos no armazenamento local (fallback)
  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson =
        jsonEncode(_orders.map((order) => order.toJson()).toList());
    await prefs.setString('orders', ordersJson);
  }

  // Limpar todos os pedidos (para testes)
  Future<void> clearOrders() async {
    try {
      // Obter todos os documentos da coleção orders
      final snapshot = await _firestore.collection('orders').get();
      
      // Excluir cada documento
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      _orders = [];
      
      // Atualizar o stream de pedidos
      _ordersStreamController.add(_orders);
      
      // Limpar também o armazenamento local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('orders');
      
      notifyListeners();
    } catch (e) {
      print('Erro ao limpar pedidos: $e');
      // Fallback para limpar apenas localmente
      _orders = [];
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('orders');
      notifyListeners();
    }
  }
  
  // Autenticar usuário da cozinha
  Future<void> authenticateKitchen(bool authenticated) async {
    _isKitchenAuthenticated = authenticated;
    if (authenticated) {
      // Carregar pedidos do Firestore quando autenticado
      await loadOrdersFromFirestore();
    }
    notifyListeners();
  }
  
  // Obter stream de pedidos para a tela da cozinha
  Stream<List<PoliedroOrder>> getOrdersStream() {
    // Carregar pedidos do Firestore e adicionar ao stream
    loadOrdersFromFirestore().then((_) {
      _ordersStreamController.add(_orders);
    });
    
    // Configurar um listener para atualizações em tempo real
    _firestore.collection('orders').snapshots().listen((snapshot) {
      _orders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PoliedroOrder.fromJson(data);
      }).toList();
      
      // Adicionar os pedidos atualizados ao stream
      _ordersStreamController.add(_orders);
      
      notifyListeners();
    }, onError: (e) {
      print('Erro ao ouvir atualizações do Firestore: $e');
    });
    
    return _ordersStreamController.stream;
  }
  
  // Confirmar pedido (muda status para inProgress)
  Future<void> confirmOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.inProgress);
  }
  
  @override
  void dispose() {
    _ordersStreamController.close();
    super.dispose();
  }
}
