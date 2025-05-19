import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatbot/models/user.dart' as app_models;

class ChatbotAuthProvider extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  app_models.User? _currentUser;
  bool _isAdminLoggedIn = false;
  
  app_models.User? get currentUser => _currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isAdminLoggedIn => _isAdminLoggedIn;
  
  // Inicializar o provider verificando se há um usuário logado
  Future<void> initialize() async {
    // Verificar se há um usuário logado no Firebase
    final firebaseUser = _auth.currentUser;
    
    if (firebaseUser != null) {
      try {
        // Verificar se é um administrador
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          final isAdmin = userData?['isAdmin'] ?? false;
          
          if (isAdmin) {
            _isAdminLoggedIn = true;
          } else {
            // Recuperar dados do usuário comum
            final phone = userData?['phone'] ?? '';
            _currentUser = app_models.User(
              ra: firebaseUser.email ?? '',
              phone: phone,
            );
          }
          notifyListeners();
        }
      } catch (e) {
        print('Erro ao inicializar provider: $e');
      }
    }
  }
  
  // Verificar se o usuário já existe no Firestore
  Future<bool> _userExists(String email) async {
    try {
      // Buscar usuário pelo email
      final querySnapshot = await _firestore
          .collection('users')
          .where('ra', isEqualTo: email)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar existência do usuário: $e');
      return false;
    }
  }
  
  // Login de usuário comum
  Future<void> login(app_models.User user) async {
    try {
      // Validar o formato do R.A. (email)
      final raRegex = RegExp(r'^\d{8}@p4ed\.com\.br$');
      if (!raRegex.hasMatch(user.ra)) {
        throw Exception('R.A. inválido. Use o formato: 12345678@p4ed.com.br');
      }
      
      // Verificar se o usuário já existe
      final userExists = await _userExists(user.ra);
      
      if (userExists) {
        // Usuário já existe, login apenas com email
        await _loginExistingUser(user.ra);
      } else {
        // Primeiro login, validar telefone também
        if (user.phone.isEmpty) {
          throw Exception('Telefone é obrigatório no primeiro login');
        }
        
        // Validar o formato do telefone
        final phoneRegex = RegExp(r'^\(\d{2}\) \d{5}-\d{4}$');
        if (!phoneRegex.hasMatch(user.phone)) {
          throw Exception('Telefone inválido. Use o formato: (11) 98765-4321');
        }
        
        // Primeiro login, criar conta
        await _createUserAccount(user.ra, user.phone);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Login de usuário existente (apenas com email)
  Future<void> _loginExistingUser(String email) async {
    try {
      // Buscar usuário no Firestore para obter o telefone
      final querySnapshot = await _firestore
          .collection('users')
          .where('ra', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        throw Exception('Usuário não encontrado');
      }
      
      final userData = querySnapshot.docs.first.data();
      final phone = userData['phone'] as String;
      
      // Gerar senha a partir do telefone (apenas números)
      final password = phone.replaceAll(RegExp(r'[^0-9]'), '');
      
      // Fazer login no Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Atualizar timestamp de último login
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      _currentUser = app_models.User(
        ra: email,
        phone: phone,
      );
      _isAdminLoggedIn = false;
      notifyListeners();
    } on firebase_auth.FirebaseAuthException catch (e) {
      _handleFirebaseAuthError(e);
    }
  }
  
  // Criar conta de usuário
  Future<void> _createUserAccount(String email, String phone) async {
    try {
      // Gerar senha a partir do telefone (apenas números)
      final password = phone.replaceAll(RegExp(r'[^0-9]'), '');
      
      // Criar usuário no Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Salvar dados adicionais no Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'ra': email,
        'phone': phone,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      _currentUser = app_models.User(
        ra: email,
        phone: phone,
      );
      _isAdminLoggedIn = false;
      notifyListeners();
    } on firebase_auth.FirebaseAuthException catch (e) {
      _handleFirebaseAuthError(e);
    }
  }
  
  // Login administrativo
  Future<void> adminLogin(String username, String password) async {
    try {
      // Verificar se o email é de administrador
      if (username != 'admin@p4ed.com.br') {
        throw Exception('Usuário não encontrado');
      }
      
      // Tentar fazer login no Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: username,
        password: password,
      );
      
      // Verificar se o usuário é realmente um administrador
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      
      if (!userDoc.exists || !(userDoc.data()?['isAdmin'] ?? false)) {
        // Se não for admin, fazer logout e lançar erro
        await _auth.signOut();
        throw Exception('Acesso não autorizado');
      }
      
      // Atualizar timestamp de último login
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      _isAdminLoggedIn = true;
      _currentUser = null;
      notifyListeners();
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' && username == 'admin@p4ed.com.br') {
        // Criar conta de administrador se não existir
        await _createAdminAccount(username, password);
      } else {
        _handleFirebaseAuthError(e);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Criar conta de administrador
  Future<void> _createAdminAccount(String email, String password) async {
    try {
      // Criar usuário no Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Salvar dados adicionais no Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      _isAdminLoggedIn = true;
      _currentUser = null;
      notifyListeners();
    } on firebase_auth.FirebaseAuthException catch (e) {
      _handleFirebaseAuthError(e);
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _isAdminLoggedIn = false;
      notifyListeners();
    } catch (e) {
      print('Erro ao fazer logout: $e');
      rethrow;
    }
  }
  
  // Tratar erros do Firebase Auth
  void _handleFirebaseAuthError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        throw Exception('Email inválido');
      case 'user-disabled':
        throw Exception('Usuário desativado');
      case 'user-not-found':
        throw Exception('Usuário não encontrado');
      case 'wrong-password':
        throw Exception('Senha incorreta');
      case 'email-already-in-use':
        throw Exception('Email já está em uso');
      case 'operation-not-allowed':
        throw Exception('Operação não permitida');
      case 'weak-password':
        throw Exception('Senha muito fraca');
      default:
        throw Exception('Erro de autenticação: ${e.message}');
    }
  }
}
