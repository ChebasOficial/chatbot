import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatbot/models/user.dart' as app_models;
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotAuthProvider extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  app_models.User? _currentUser;
  bool _isAdminLoggedIn = false;
  bool _isKitchenLoggedIn = false;
  String? _cachedPhone;

  app_models.User? get currentUser => _currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isAdminLoggedIn => _isAdminLoggedIn;
  bool get isKitchenLoggedIn => _isKitchenLoggedIn;
  String? get cachedPhone => _cachedPhone;

  // Inicializar o provider verificando se há um usuário logado
  Future<void> initialize() async {
    try {
      // Verificar se há um usuário logado no Firebase
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        try {
          // Verificar se é o admin ou cozinha
          if (firebaseUser.email == 'admin@p4ed.com.br') {
            _isAdminLoggedIn = true;
            _isKitchenLoggedIn = false;
            notifyListeners();
            return;
          } else if (firebaseUser.email == 'cozinha@p4ed.com.br') {
            _isKitchenLoggedIn = true;
            _isAdminLoggedIn = false;
            notifyListeners();
            return;
          }
          
          // Tentar recuperar dados do Firestore, mas não falhar se não conseguir
          try {
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
            } else {
              // Se o documento não existe, criar um usuário básico com o email
              _currentUser = app_models.User(
                ra: firebaseUser.email ?? '',
                phone: '',
              );
            }
          } catch (firestoreError) {
            // Se falhar ao acessar o Firestore, criar um usuário básico com o email
            print('Erro ao acessar Firestore durante inicialização: $firestoreError');
            _currentUser = app_models.User(
              ra: firebaseUser.email ?? '',
              phone: '',
            );
          }
          
          notifyListeners();
        } catch (e) {
          print('Erro ao inicializar provider: $e');
          // Fazer logout para garantir consistência
          await logout();
          _currentUser = null;
          _isAdminLoggedIn = false;
          notifyListeners();
        }
      } else {
        // Verificar se há dados salvos localmente
        await _checkLocalUserData();
      }
    } catch (e) {
      print('Erro geral ao inicializar provider: $e');
      // Fazer logout para garantir consistência
      await logout();
      _currentUser = null;
      _isAdminLoggedIn = false;
      notifyListeners();
    }
  }

  // Verificar se há dados de usuário salvos localmente
  Future<void> _checkLocalUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email');
      final userPhone = prefs.getString('user_phone');

      if (userEmail != null && userPhone != null) {
        print('Dados de usuário encontrados localmente: $userEmail');
        _cachedPhone = userPhone;
        // Não definir o usuário como logado, apenas armazenar os dados para facilitar o próximo login
      }
    } catch (e) {
      print('Erro ao verificar dados locais: $e');
    }
  }

  // Salvar dados do usuário no armazenamento local
  Future<void> _saveUserToLocal(String email, String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setString('user_phone', phone);
      // Salvar também com chave específica para este email
      await prefs.setString('user_phone_$email', phone);
      _cachedPhone = phone;
      print('Dados do usuário salvos localmente: $email, $phone');
    } catch (e) {
      print('Erro ao salvar dados do usuário no armazenamento local: $e');
    }
  }

  // Login para cozinha - MÉTODO CORRIGIDO
  Future<bool> loginKitchen(String email, String password) async {
    try {
      print('Iniciando login para cozinha: $email');
      
      if (email != 'cozinha@p4ed.com.br') {
        throw Exception('Email inválido para cozinha');
      }
      
      // Fazer logout primeiro para evitar conflitos de estado
      await logout();
      
      // Tentar fazer login com método simplificado
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Verificar se o login foi bem-sucedido verificando o usuário atual
        final user = _auth.currentUser;
        if (user != null && user.email == email) {
          print('Login da cozinha bem-sucedido');
          
          // Definir estado
          _isKitchenLoggedIn = true;
          _isAdminLoggedIn = false;
          _currentUser = null;
          
          notifyListeners();
          
          return true;
        } else {
          print('Login da cozinha falhou: usuário atual não corresponde');
          return false;
        }
      } catch (e) {
        print('Erro ao fazer login da cozinha: $e');
        return false;
      }
    } catch (e) {
      print('Erro no login da cozinha: $e');
      // Garantir que o estado seja limpo em caso de erro
      _isKitchenLoggedIn = false;
      _isAdminLoggedIn = false;
      _currentUser = null;
      notifyListeners();
      rethrow;
    }
  }
  
  // Login para admin
  Future<bool> loginAdmin(String email, String password) async {
    try {
      print('Iniciando login para admin: $email');
      
      if (email != 'admin@p4ed.com.br') {
        throw Exception('Email inválido para administrador');
      }
      
      // Fazer logout primeiro para evitar conflitos de estado
      await logout();
      
      // Tentar fazer login
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Verificar se o login foi bem-sucedido verificando o usuário atual
        final user = _auth.currentUser;
        if (user != null && user.email == email) {
          print('Login de admin bem-sucedido');
          
          // Definir estado
          _isAdminLoggedIn = true;
          _isKitchenLoggedIn = false;
          _currentUser = null;
          
          notifyListeners();
          
          return true;
        } else {
          print('Login de admin falhou: usuário atual não corresponde');
          return false;
        }
      } catch (e) {
        print('Erro ao fazer login de admin: $e');
        return false;
      }
    } catch (e) {
      print('Erro no login de admin: $e');
      // Garantir que o estado seja limpo em caso de erro
      _isAdminLoggedIn = false;
      _isKitchenLoggedIn = false;
      _currentUser = null;
      notifyListeners();
      rethrow;
    }
  }

  // Login de usuário comum
  Future<void> login(app_models.User user) async {
    try {
      print('Iniciando login para: ${user.ra}');

      // Validar o formato do R.A. (email)
      final raRegex = RegExp(r'^\d{8}@p4ed\.com\.br$');
      if (!raRegex.hasMatch(user.ra)) {
        print('R.A. inválido: ${user.ra}');
        throw Exception('R.A. inválido. Use o formato: 12345678@p4ed.com.br');
      }

      // Validar o formato do telefone
      final phoneRegex = RegExp(r'^\(\d{2}\) \d{5}-\d{4}$');
      if (!phoneRegex.hasMatch(user.phone)) {
        print('Formato de telefone inválido: ${user.phone}');
        throw Exception('Telefone inválido. Use o formato: (11) 98765-4321');
      }

      // Gerar senha a partir do telefone fornecido
      final password = user.phone.replaceAll(RegExp(r'[^0-9]'), '');
      print('Senha gerada a partir do telefone fornecido: $password');
      
      try {
        print('Tentando login com email: ${user.ra} e senha gerada do telefone fornecido');
        
        // Fazer logout primeiro para evitar conflitos de estado
        await logout();
        
        // Tentar fazer login
        await _auth.signInWithEmailAndPassword(
          email: user.ra,
          password: password,
        );
        
        // Verificar se o login foi bem-sucedido
        final currentUser = _auth.currentUser;
        if (currentUser == null || currentUser.email != user.ra) {
          throw Exception('Falha ao fazer login: usuário não autenticado corretamente');
        }
        
        print('Login bem-sucedido');
        
        // Salvar dados localmente
        await _saveUserToLocal(user.ra, user.phone);
        
        _currentUser = app_models.User(
          ra: user.ra,
          phone: user.phone,
        );
        _isAdminLoggedIn = false;
        _isKitchenLoggedIn = false;
        notifyListeners();
        
        // Tentar atualizar telefone no Firestore, mas não falhar se não conseguir
        try {
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .set({
            'ra': user.ra,
            'phone': user.phone,
            'isAdmin': false,
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('Dados do usuário atualizados no Firestore');
        } catch (e) {
          print('Erro ao atualizar dados no Firestore: $e');
          // Não interromper o fluxo por causa desse erro
        }
        
        return;
      } catch (authError) {
        // Se o erro for de usuário não encontrado, criar nova conta
        print('Erro ao fazer login: $authError');
        
        if (authError is firebase_auth.FirebaseAuthException) {
          if (authError.code == 'user-not-found') {
            print('Usuário não encontrado, tentando criar nova conta');
            await _createUserAccount(user.ra, user.phone);
            return;
          } else if (authError.code == 'wrong-password' || 
                    authError.code == 'invalid-credential') {
            print('Senha incorreta - telefone não corresponde ao usado na criação da conta');
            throw Exception('Este email já está em uso, mas a senha não corresponde ao telefone informado. Por favor, use o mesmo telefone que usou para criar a conta.');
          } else if (authError.code == 'network-request-failed') {
            throw Exception('Erro de conexão. Verifique sua internet e tente novamente.');
          } else {
            throw Exception('Erro ao fazer login: ${authError.message}');
          }
        } else {
          print('Erro não específico, tentando criar nova conta');
          await _createUserAccount(user.ra, user.phone);
          return;
        }
      }
    } catch (e) {
      print('Erro em login: $e');
      rethrow;
    }
  }

  // Criar conta de usuário
  Future<void> _createUserAccount(String email, String phone) async {
    try {
      print('Iniciando criação de conta para: $email');
      
      // Gerar senha a partir do telefone (apenas números)
      final password = phone.replaceAll(RegExp(r'[^0-9]'), '');
      print('Senha gerada: $password');

      try {
        // Criar usuário no Firebase Auth
        print('Tentando criar usuário no Firebase Auth');
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Verificar se o usuário foi criado com sucesso
        final currentUser = _auth.currentUser;
        if (currentUser == null || currentUser.email != email) {
          throw Exception('Falha ao criar usuário: usuário não criado corretamente');
        }
        
        print('Usuário criado com sucesso no Firebase Auth: ${currentUser.uid}');
        
        // Salvar dados localmente - importante para logins futuros
        await _saveUserToLocal(email, phone);
        print('Dados salvos localmente');

        // Atualizar estado do provider - isso faz o login automático
        _currentUser = app_models.User(
          ra: email,
          phone: phone,
        );
        _isAdminLoggedIn = false;
        _isKitchenLoggedIn = false;
        notifyListeners();

        print('Estado do provider atualizado - usuário logado automaticamente');
        
        // Tentar salvar dados no Firestore, mas não falhar se não conseguir
        try {
          print('Tentando salvar dados no Firestore');
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .set({
            'ra': email,
            'phone': phone,
            'isAdmin': false,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)); // Garantir que use merge para não sobrescrever dados existentes
          print('Dados do usuário salvos no Firestore');
        } catch (firestoreError) {
          print('Erro ao salvar dados no Firestore: $firestoreError');
          // Não interromper o fluxo por causa desse erro
          
          // Tentar novamente após um breve atraso
          try {
            await Future.delayed(Duration(seconds: 1));
            await _firestore
                .collection('users')
                .doc(currentUser.uid)
                .set({
              'ra': email,
              'phone': phone,
              'isAdmin': false,
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            print('Dados do usuário salvos no Firestore na segunda tentativa');
          } catch (retryError) {
            print('Erro na segunda tentativa de salvar no Firestore: $retryError');
            // Ainda não falhar o fluxo
          }
        }
        
        return;
      } catch (authError) {
        print('Erro ao criar usuário: $authError');
        
        // Se o email já existe, tentar fazer login
        if (authError is firebase_auth.FirebaseAuthException) {
          print('Código de erro: ${authError.code}');
          
          if (authError.code == 'email-already-in-use') {
            print('Email já existe, tentando login');
            
            try {
              // Tentar recuperar o telefone do Firestore para este email
              try {
                // Consultar usuários com este email
                final querySnapshot = await _firestore
                    .collection('users')
                    .where('ra', isEqualTo: email)
                    .limit(1)
                    .get();
                
                if (querySnapshot.docs.isNotEmpty) {
                  final userData = querySnapshot.docs.first.data();
                  final storedPhone = userData['phone'] as String?;
                  
                  if (storedPhone != null && storedPhone.isNotEmpty) {
                    print('Telefone encontrado no Firestore: $storedPhone');
                    
                    // Gerar senha a partir do telefone armazenado
                    final storedPassword = storedPhone.replaceAll(RegExp(r'[^0-9]'), '');
                    
                    try {
                      // Tentar login com o telefone armazenado
                      await _auth.signInWithEmailAndPassword(
                        email: email,
                        password: storedPassword,
                      );
                      
                      // Verificar se o login foi bem-sucedido
                      final currentUser = _auth.currentUser;
                      if (currentUser == null || currentUser.email != email) {
                        throw Exception('Falha ao fazer login: usuário não autenticado corretamente');
                      }
                      
                      print('Login bem-sucedido com telefone armazenado');
                      
                      // Atualizar dados locais
                      await _saveUserToLocal(email, storedPhone);
                      
                      _currentUser = app_models.User(
                        ra: email,
                        phone: storedPhone,
                      );
                      _isAdminLoggedIn = false;
                      _isKitchenLoggedIn = false;
                      notifyListeners();
                      
                      // Atualizar lastLogin no Firestore
                      try {
                        await _firestore
                            .collection('users')
                            .doc(currentUser.uid)
                            .update({
                          'lastLogin': FieldValue.serverTimestamp(),
                        });
                        print('lastLogin atualizado no Firestore');
                      } catch (e) {
                        print('Erro ao atualizar lastLogin: $e');
                        // Não falhar o fluxo por causa desse erro
                      }
                      
                      return;
                    } catch (loginError) {
                      print('Erro ao fazer login com telefone armazenado: $loginError');
                      throw Exception('Este email já está em uso, mas não foi possível fazer login com o telefone armazenado. Por favor, use o mesmo telefone que usou para criar a conta.');
                    }
                  } else {
                    print('Telefone não encontrado no Firestore');
                    throw Exception('Este email já está em uso, mas não foi possível recuperar o telefone associado. Por favor, use o mesmo telefone que usou para criar a conta.');
                  }
                } else {
                  print('Nenhum documento encontrado para este email no Firestore');
                  throw Exception('Este email já está em uso, mas não foi possível recuperar os dados associados. Por favor, use o mesmo telefone que usou para criar a conta.');
                }
              } catch (firestoreError) {
                print('Erro ao consultar Firestore: $firestoreError');
                throw Exception('Este email já está em uso, mas ocorreu um erro ao tentar recuperar os dados. Por favor, use o mesmo telefone que usou para criar a conta.');
              }
            } catch (e) {
              print('Erro ao tentar login com email existente: $e');
              rethrow;
            }
          } else {
            // Propagar outros erros
            throw Exception('Erro ao criar conta: ${authError.message}');
          }
        } else {
          // Propagar erros não específicos
          throw Exception('Erro não específico ao criar conta: $authError');
        }
      }
    } catch (e) {
      print('Erro geral em _createUserAccount: $e');
      rethrow;
    }
  }
  
  // Método de logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _isAdminLoggedIn = false;
      _isKitchenLoggedIn = false;
      notifyListeners();
    } catch (e) {
      print('Erro ao fazer logout: $e');
      rethrow;
    }
  }
  
  // Método de signOut para compatibilidade com código existente
  Future<void> signOut() async {
    return logout();
  }
}
