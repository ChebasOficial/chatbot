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

  app_models.User? get currentUser => _currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isAdminLoggedIn => _isAdminLoggedIn;

  // Inicializar o provider verificando se há um usuário logado
  Future<void> initialize() async {
    try {
      // Verificar se há um usuário logado no Firebase
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        try {
          // Verificar se é um administrador
          final userDoc =
              await _firestore.collection('users').doc(firebaseUser.uid).get();

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
          print('Erro ao inicializar provider com Firestore: $e');
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
      print('Dados do usuário salvos localmente: $email, $phone');
    } catch (e) {
      print('Erro ao salvar dados do usuário no armazenamento local: $e');
    }
  }

  // Verificar se o usuário já existe no Firestore
  Future<bool> _userExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('ra', isEqualTo: email)
          .limit(1)
          .get();

      final exists = querySnapshot.docs.isNotEmpty;
      print(
          'Usuário ${exists ? "encontrado" : "não encontrado"} no Firestore: $email');
      return exists;
    } catch (e) {
      print('Erro ao verificar existência do usuário: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception(
            'Erro de permissão ao acessar o banco de dados. Verifique as regras de segurança do Firestore.');
      } else if (e.toString().contains('network')) {
        throw Exception(
            'Sem conexão com a internet. O login requer conexão ativa com a internet.');
      } else {
        throw Exception(
            'Erro ao verificar existência do usuário. Verifique sua conexão com a internet.');
      }
    }
  }

  // Obter telefone do usuário do Firestore
  Future<String?> _getUserPhone(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('ra', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return userData['phone'] as String?;
      }
      return null;
    } catch (e) {
      print('Erro ao obter telefone do usuário: $e');
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

      // Verificar se há dados salvos localmente
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('user_email');
      final storedPhone = prefs.getString('user_phone');

      // Se encontrou localmente e tem telefone armazenado
      if (storedEmail == user.ra &&
          storedPhone != null &&
          storedPhone.isNotEmpty) {
        print('Usuário encontrado no armazenamento local: ${user.ra}');

        // Se não forneceu telefone, usar o armazenado apenas para preencher o campo
        if (user.phone.isEmpty) {
          print('Usando telefone armazenado localmente: $storedPhone');
          user = app_models.User(
            ra: user.ra,
            phone: storedPhone,
          );
        }
      }

      // Verificar se o telefone foi fornecido
      if (user.phone.isEmpty) {
        // Se não forneceu telefone, tentar buscar do Firestore
        try {
          final phoneFromFirestore = await _getUserPhone(user.ra);
          if (phoneFromFirestore != null && phoneFromFirestore.isNotEmpty) {
            print('Telefone recuperado do Firestore: $phoneFromFirestore');
            user = app_models.User(
              ra: user.ra,
              phone: phoneFromFirestore,
            );
          } else {
            // Se não encontrou no Firestore, solicitar telefone
            print('Telefone não encontrado no Firestore');
            throw Exception('Telefone é obrigatório para o primeiro login.');
          }
        } catch (e) {
          print('Erro ao buscar telefone do Firestore: $e');
          throw Exception('Telefone é obrigatório para o primeiro login.');
        }
      }

      // Verificar se o usuário existe no Firestore
      bool userExists = false;
      try {
        userExists = await _userExists(user.ra);
      } catch (e) {
        print('Erro ao verificar existência do usuário: $e');
        // Continuar com o fluxo, assumindo que precisamos criar o usuário
      }

      if (userExists) {
        print('Usuário existe, tentando login: ${user.ra}');

        // Telefone já foi verificado ou recuperado acima
        print('Telefone fornecido: ${user.phone}');

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
          // Tentar login no Firebase
          await _auth
              .signInWithEmailAndPassword(
            email: user.ra,
            password: password,
          )
              .then((userCredential) async {
            print('Login bem-sucedido com telefone fornecido');

            // Atualizar telefone no Firestore
            try {
              await _firestore
                  .collection('users')
                  .doc(userCredential.user!.uid)
                  .update({
                'phone': user.phone,
                'lastLogin': FieldValue.serverTimestamp(),
              });
              print('Telefone atualizado no Firestore');
            } catch (updateError) {
              print('Erro ao atualizar telefone no Firestore: $updateError');
            }

            // Salvar dados localmente
            await _saveUserToLocal(user.ra, user.phone);

            _currentUser = app_models.User(
              ra: user.ra,
              phone: user.phone,
            );
            _isAdminLoggedIn = false;
            notifyListeners();
          });

          // Se chegou aqui, login foi bem-sucedido
          return;
        } catch (authError) {
          print('Erro ao tentar login com telefone fornecido: $authError');
          throw Exception(
              'Senha incorreta. Verifique se o telefone está correto.');
        }
      } else {
        // Usuário não existe, criar nova conta
        print('Primeiro login para: ${user.ra}');

        // Primeiro login, validar telefone também
        if (user.phone.isEmpty) {
          print('Telefone não fornecido no primeiro login');
          throw Exception('Telefone é obrigatório no primeiro login');
        }

        // Validar o formato do telefone
        final phoneRegex = RegExp(r'^\(\d{2}\) \d{5}-\d{4}$');
        if (!phoneRegex.hasMatch(user.phone)) {
          print('Formato de telefone inválido: ${user.phone}');
          throw Exception('Telefone inválido. Use o formato: (11) 98765-4321');
        }

        // Primeiro login, criar conta
        print('Criando nova conta para: ${user.ra}');
        await _createUserAccount(user.ra, user.phone);
      }
    } catch (e) {
      // Se ocorrer erro ao verificar usuário ou ao fazer login, tentar criar conta
      if (e.toString().contains('Erro ao verificar existência do usuário') &&
          user.phone.isNotEmpty) {
        print('Erro ao verificar usuário, tentando criar conta: ${user.ra}');

        // Validar o formato do telefone
        final phoneRegex = RegExp(r'^\(\d{2}\) \d{5}-\d{4}$');
        if (!phoneRegex.hasMatch(user.phone)) {
          print('Formato de telefone inválido: ${user.phone}');
          throw Exception('Telefone inválido. Use o formato: (11) 98765-4321');
        }

        // Criar conta
        await _createUserAccount(user.ra, user.phone);
        return;
      }

      // Se não for erro de verificação ou não tiver telefone, propagar o erro
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
        await _auth
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        )
            .then((userCredential) async {
          try {
            // Salvar dados adicionais no Firestore
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
          } catch (firestoreError) {
            print('Erro ao salvar dados no Firestore: $firestoreError');
            // Se falhar ao salvar no Firestore, excluir o usuário do Auth
            await userCredential.user?.delete();
            throw Exception(
                'Erro ao salvar dados do usuário. Tente novamente.');
          }

          // Salvar dados localmente
          await _saveUserToLocal(email, phone);

          _currentUser = app_models.User(
            ra: email,
            phone: phone,
          );
          _isAdminLoggedIn = false;
          notifyListeners();
        });
      } catch (authError) {
        print('Erro específico de criação de conta: $authError');
        throw Exception(
            'Erro ao criar conta. Verifique sua conexão e tente novamente.');
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

  // Login administrativo
  Future<void> adminLogin(String username, String password) async {
    try {
      // Verificar se o email é de administrador
      if (username != 'admin@p4ed.com.br') {
        throw Exception('Usuário não encontrado');
      }

      // Verificar se a senha é a padrão para admin
      if (password != 'admin123') {
        throw Exception('Senha incorreta');
      }

      try {
        // Fazer login no Firebase
        await _auth
            .signInWithEmailAndPassword(
          email: username,
          password: password,
        )
            .then((userCredential) async {
          try {
            // Verificar se o usuário é realmente admin no Firestore
            final userDoc = await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .get();

            if (userDoc.exists) {
              final userData = userDoc.data();
              final isAdmin = userData?['isAdmin'] ?? false;

              if (isAdmin) {
                _isAdminLoggedIn = true;
                _currentUser = null;
                notifyListeners();
              } else {
                // Se não for admin, fazer logout e lançar erro
                await _auth.signOut();
                throw Exception('Usuário não tem permissão de administrador');
              }
            } else {
              // Se falhar ao verificar no Firestore, fazer logout
              await _auth.signOut();
              throw Exception('Erro ao verificar permissões de administrador');
            }
          } catch (firestoreError) {
            print('Erro ao verificar admin no Firestore: $firestoreError');
            await _auth.signOut();
            throw Exception('Erro ao verificar permissões de administrador');
          }
        });
      } catch (authError) {
        print('Erro ao fazer login admin: $authError');
        throw Exception('Erro ao fazer login. Verifique suas credenciais.');
      }
    } catch (e) {
      print('Erro ao fazer login admin: $e');
      rethrow;
    }
  }
}
