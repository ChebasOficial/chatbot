import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:chatbot/models/menu_item.dart';
import 'dart:async';

class MenuProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<MenuItem> _menuItems = [];
  bool _isLoading = false;
  String? _error;

  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Carregar itens do cardápio
  Future<void> loadMenuItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

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

      _menuItems = items;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Erro ao carregar itens do cardápio: $e');
      _error = 'Erro ao carregar itens do cardápio: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adicionar item ao cardápio
  Future<MenuItem?> addMenuItem(MenuItem item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docRef = await _firestore.collection('menu_items').add({
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'imageUrl': item.imageUrl,
        'quantity': item.quantity,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newItem = MenuItem(
        id: docRef.id,
        name: item.name,
        description: item.description,
        price: item.price,
        imageUrl: item.imageUrl,
        quantity: item.quantity,
      );

      _menuItems.add(newItem);
      _isLoading = false;
      notifyListeners();

      return newItem;
    } catch (e) {
      print('Erro ao adicionar item ao cardápio: $e');
      _error = 'Erro ao adicionar item ao cardápio: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Atualizar item do cardápio
  Future<bool> updateMenuItem(MenuItem item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('menu_items').doc(item.id).update({
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'imageUrl': item.imageUrl,
        'quantity': item.quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = _menuItems.indexWhere((i) => i.id == item.id);
      if (index >= 0) {
        _menuItems[index] = item;
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      print('Erro ao atualizar item do cardápio: $e');
      _error = 'Erro ao atualizar item do cardápio: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Remover item do cardápio
  Future<bool> deleteMenuItem(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('menu_items').doc(id).delete();

      _menuItems.removeWhere((item) => item.id == id);
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      print('Erro ao remover item do cardápio: $e');
      _error = 'Erro ao remover item do cardápio: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Atualizar quantidade de um item
  Future<bool> updateItemQuantity(String id, int quantity) async {
    try {
      await _firestore.collection('menu_items').doc(id).update({
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = _menuItems.indexWhere((i) => i.id == id);
      if (index >= 0) {
        final item = _menuItems[index];
        _menuItems[index] = MenuItem(
          id: item.id,
          name: item.name,
          description: item.description,
          price: item.price,
          imageUrl: item.imageUrl,
          quantity: quantity,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('Erro ao atualizar quantidade do item: $e');
      return false;
    }
  }
}
