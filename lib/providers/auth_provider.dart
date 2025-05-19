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
      print('Erro durante login: $e');
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
      
      try {
        // Fazer login no Firebase Auth com tratamento de erro específico
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ).then((userCredential) async {
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
        });
      } catch (authError) {
        print('Erro específico de autenticação: $authError');
        if (authError is firebase_auth.FirebaseAuthException) {
          _handleFirebaseAuthError(authError);
        } else {
          throw Exception('Erro ao fazer login: $authError');
        }
      }
    } catch (e) {
      print('Erro em _loginExistingUser: $e');
      rethrow;
    }
  }
  
  // Criar conta de usuário
  Future<void> _createUserAccount(String email, String phone) async {
    try {
      // Gerar senha a partir do telefone (apenas números)
      final password = phone.replaceAll(RegExp(r'[^0-9]'), '');
      
      try {
        // Criar usuário no Firebase Auth com tratamento de erro específico
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ).then((userCredential) async {
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
        });
      } catch (authError) {
        print('Erro específico de criação de conta: $authError');
        if (authError is firebase_auth.FirebaseAuthException) {
          _handleFirebaseAuthError(authError);
        } else {
          throw Exception('Erro ao criar conta: $authError');
        }
      }
    } catch (e) {
      print('Erro em _createUserAccount: $e');
      rethrow;
    }
  }
  
  // Login administrativo
  Future<void> adminLogin(String username, String password) async {
    try {
      // Verificar se o email é de administrador
      if (username != 'admin@p4ed.com.br') {
        throw Exception('Usuário não encontrado');
      }
      
      try {
        // Tentar fazer login no Firebase com tratamento de erro específico
        await _auth.signInWithEmailAndPassword(
          email: username,
          password: password,
        ).then((userCredential) async {
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
        });
      } catch (authError) {
        print('Erro específico de login admin: $authError');
        if (authError is firebase_auth.FirebaseAuthException) {
          if (authError.code == 'user-not-found' && username == 'admin@p4ed.com.br') {
            // Criar conta de administrador se não existir
            await _createAdminAccount(username, password);
          } else {
            _handleFirebaseAuthError(authError);
          }
        } else {
          throw Exception('Erro ao fazer login administrativo: $authError');
        }
      }
    } catch (e) {
      print('Erro em adminLogin: $e');
      rethrow;
    }
  }
  
  // Criar conta de administrador
  Future<void> _createAdminAccount(String email, String password) async {
    try {
      try {
        // Criar usuário no Firebase Auth com tratamento de erro específico
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ).then((userCredential) async {
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
        });
      } catch (authError) {
        print('Erro específico de criação de conta admin: $authError');
        if (authError is firebase_auth.FirebaseAuthException) {
          _handleFirebaseAuthError(authError);
        } else {
          throw Exception('Erro ao criar conta administrativa: $authError');
        }
      }
    } catch (e) {
      print('Erro em _createAdminAccount: $e');
      rethrow;
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
    print('Código de erro do Firebase Auth: ${e.code}');
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
