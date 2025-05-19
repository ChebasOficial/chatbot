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
  String? _cachedPhone;

  app_models.User? get currentUser => _currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isAdminLoggedIn => _isAdminLoggedIn;
  String? get cachedPhone => _cachedPhone;

  // Inicializar o provider verificando se há um usuário logado
  Future<void> initialize() async {
    try {
      // Verificar se há um usuário logado no Firebase
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        try {
          // Verificar se é o admin
          if (firebaseUser.email == 'admin@p4ed.com.br') {
            _isAdminLoggedIn = true;
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
          await _auth.signOut();
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
      await _auth.signOut();
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
      _cachedPhone = phone;
      print('Dados do usuário salvos localmente: $email, $phone');
    } catch (e) {
      print('Erro ao salvar dados do usuário no armazenamento local: $e');
    }
  }

  // Verificar se o telefone está associado ao RA no Firestore
  Future<String?> getPhoneForRA(String ra) async {
    try {
      // Primeiro verificar no cache local
      final prefs = await SharedPreferences.getInstance();
      final cachedEmail = prefs.getString('user_email');
      final cachedPhone = prefs.getString('user_phone');
      
      if (cachedEmail == ra && cachedPhone != null) {
        print('Telefone encontrado no cache local: $cachedPhone');
        return cachedPhone;
      }
      
      // Se não encontrou no cache, tentar no Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .where('ra', isEqualTo: ra)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));
      
      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final phone = userData['phone'] as String?;
        
        if (phone != null && phone.isNotEmpty) {
          print('Telefone encontrado no Firestore: $phone');
          // Atualizar cache local
          await _saveUserToLocal(ra, phone);
          return phone;
        }
      }
      
      print('Nenhum telefone encontrado para o RA: $ra');
      return null;
    } catch (e) {
      print('Erro ao buscar telefone para RA: $e');
      return null;
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

      // Se o telefone não foi fornecido, tentar recuperar do Firestore ou cache local
      String phone = user.phone;
      if (phone.isEmpty) {
        final savedPhone = await getPhoneForRA(user.ra);
        if (savedPhone == null || savedPhone.isEmpty) {
          print('Telefone não fornecido e não encontrado no sistema');
          throw Exception('Telefone necessário para o primeiro login. Por favor, informe seu telefone.');
        }
        phone = savedPhone;
        print('Usando telefone recuperado: $phone');
      } else {
        // Validar o formato do telefone se foi fornecido
        final phoneRegex = RegExp(r'^\(\d{2}\) \d{5}-\d{4}$');
        if (!phoneRegex.hasMatch(phone)) {
          print('Formato de telefone inválido: $phone');
          throw Exception('Telefone inválido. Use o formato: (11) 98765-4321');
        }
      }

      // Gerar senha a partir do telefone fornecido
      final password = phone.replaceAll(RegExp(r'[^0-9]'), '');
      print('Senha gerada a partir do telefone: $password');

      try {
        // Tentar login no Firebase
        try {
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: user.ra,
            password: password,
          );
          
          print('Login bem-sucedido');
          
          // Salvar dados localmente
          await _saveUserToLocal(user.ra, phone);
          
          _currentUser = app_models.User(
            ra: user.ra,
            phone: phone,
          );
          _isAdminLoggedIn = false;
          notifyListeners();
          
          // Tentar atualizar telefone no Firestore, mas não falhar se não conseguir
          try {
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .update({
              'phone': phone,
              'lastLogin': FieldValue.serverTimestamp(),
            });
            print('Telefone atualizado no Firestore');
          } catch (e) {
            print('Erro ao atualizar telefone no Firestore: $e');
            // Não interromper o fluxo por causa desse erro
          }
          
          return;
        } catch (authError) {
          // Se o erro for de usuário não encontrado, criar nova conta
          if (authError is firebase_auth.FirebaseAuthException && 
              (authError.code == 'user-not-found' || authError.code == 'wrong-password')) {
            print('Usuário não encontrado ou senha incorreta, tentando criar conta');
            await _createUserAccount(user.ra, phone);
            return;
          } else {
            print('Erro ao fazer login: $authError');
            throw Exception('Erro ao fazer login. Verifique seus dados e tente novamente.');
          }
        }
      } catch (e) {
        print('Erro ao fazer login: $e');
        rethrow;
      }
    } catch (e) {
      print('Erro em login: $e');
      rethrow;
    }
  }

  // Criar conta de usuário
  Future<void> _createUserAccount(String email, String phone) async {
    try {
      // Gerar senha a partir do telefone (apenas números)
      final password = phone.replaceAll(RegExp(r'[^0-9]'), '');

      try {
        // Criar usuário no Firebase Auth
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Se chegou aqui, o usuário foi criado com sucesso
        if (userCredential.user != null) {
          // Salvar dados localmente
          await _saveUserToLocal(email, phone);

          // Atualizar estado do provider
          _currentUser = app_models.User(
            ra: email,
            phone: phone,
          );
          _isAdminLoggedIn = false;
          notifyListeners();

          print('Usuário criado com sucesso');
          
          // Tentar salvar dados no Firestore, mas não falhar se não conseguir
          try {
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'ra': email,
              'phone': phone,
              'isAdmin': false,
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
            });
            print('Dados do usuário salvos no Firestore');
          } catch (firestoreError) {
            print('Erro ao salvar dados no Firestore: $firestoreError');
            // Não interromper o fluxo por causa desse erro
          }
        } else {
          throw Exception('Erro ao criar usuário: objeto de usuário é nulo');
        }
      } catch (authError) {
        // Se o email já existe, tentar fazer login
        if (authError is firebase_auth.FirebaseAuthException && 
            authError.code == 'email-already-in-use') {
          print('Email já existe, tentando login');
          
          try {
            final userCredential = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            
            if (userCredential.user != null) {
              // Login bem-sucedido
              print('Login bem-sucedido para usuário existente');
              
              // Salvar dados localmente
              await _saveUserToLocal(email, phone);
              
              _currentUser = app_models.User(
                ra: email,
                phone: phone,
              );
              _isAdminLoggedIn = false;
              notifyListeners();
              
              // Tentar atualizar telefone no Firestore, mas não falhar se não conseguir
              try {
                await _firestore
                    .collection('users')
                    .doc(userCredential.user!.uid)
                    .update({
                  'phone': phone,
                  'lastLogin': FieldValue.serverTimestamp(),
                });
                print('Telefone atualizado no Firestore');
              } catch (e) {
                print('Erro ao atualizar telefone no Firestore: $e');
                // Não interromper o fluxo por causa desse erro
              }
              
              return;
            }
          } catch (loginError) {
            print('Erro ao tentar login com email existente: $loginError');
            throw Exception('Este email já está em uso, mas a senha não corresponde ao telefone informado.');
          }
        } else {
          print('Erro específico de criação de conta: $authError');
          throw Exception('Erro ao criar conta. Verifique sua conexão e tente novamente.');
        }
      }
    } catch (e) {
      print('Erro em _createUserAccount: $e');
      rethrow;
    }
  }

  // Método de logout
  Future<void> logout() async {
    try {
      print('Iniciando logout');

      // Desconectar do Firebase Auth
      await _auth.signOut();

      // Limpar dados do usuário atual
      _currentUser = null;
      _isAdminLoggedIn = false;

      // Notificar listeners sobre a mudança de estado
      notifyListeners();

      print('Logout realizado com sucesso');
    } catch (e) {
      print('Erro durante logout: $e');
      rethrow;
    }
  }

  // Login administrativo - Corrigido para ignorar erros de Firestore
  Future<void> adminLogin(String username, String password) async {
    try {
      // Verificar se o email é de administrador
      if (username != 'admin@p4ed.com.br') {
        throw Exception('Usuário não encontrado');
      }

      try {
        // Fazer login no Firebase Auth
        try {
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: username,
            password: password,
          );
          
          // Se chegou aqui, o login foi bem-sucedido
          print('Login administrativo bem-sucedido via Firebase Auth');
          
          // Definir como admin logado
          _isAdminLoggedIn = true;
          _currentUser = null;
          notifyListeners();
          
          return;
        } catch (authError) {
          print('Erro ao fazer login administrativo via Firebase Auth: $authError');
          
          // Verificar se é o erro específico de tipo
          if (authError.toString().contains("type 'List<Object?>'")) {
            print('Erro de tipo detectado, mas login foi bem-sucedido');
            
            // Mesmo com o erro, o login foi bem-sucedido
            _isAdminLoggedIn = true;
            _currentUser = null;
            notifyListeners();
            return;
          }
          
          // Se não for o erro específico, propagar o erro
          throw Exception('Credenciais inválidas');
        }
      } catch (e) {
        print('Erro ao fazer login administrativo: $e');
        rethrow;
      }
    } catch (e) {
      print('Erro em adminLogin: $e');
      rethrow;
    }
  }
}
