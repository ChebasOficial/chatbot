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
    // ... (código inalterado)
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
            final userDoc = await _firestore
                .collection('users')
                .doc(firebaseUser.uid)
                .get();

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
            print(
                'Erro ao acessar Firestore durante inicialização: $firestoreError');
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
    // ... (código inalterado)
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
    // ... (código inalterado)
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

  // Login para cozinha
  Future<bool> loginKitchen(String email, String password) async {
    // ... (código inalterado com melhoria no erro)
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
          // Lançar erro específico
          throw Exception('Falha na autenticação da cozinha.');
        }
      } catch (e) {
        print('Erro ao fazer login da cozinha: $e');
        // Aprimorar mensagem de erro
        if (e is firebase_auth.FirebaseAuthException) {
          throw Exception('Erro de autenticação cozinha: ${e.message}');
        } else {
          // Relança a exceção se já for uma ou cria uma nova
          throw Exception(e.toString().contains('Exception:')
              ? e.toString().replaceAll('Exception: ', '')
              : 'Erro desconhecido no login da cozinha.');
        }
      }
    } catch (e) {
      print('Erro no login da cozinha: $e');
      // Garantir que o estado seja limpo em caso de erro
      _isKitchenLoggedIn = false;
      _isAdminLoggedIn = false;
      _currentUser = null;
      notifyListeners();
      // Relança a exceção formatada
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Login para admin
  Future<bool> loginAdmin(String email, String password) async {
    // ... (código inalterado com melhoria no erro)
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
          // Lançar erro específico
          throw Exception('Falha na autenticação do admin.');
        }
      } catch (e) {
        print('Erro ao fazer login de admin: $e');
        // Aprimorar mensagem de erro
        if (e is firebase_auth.FirebaseAuthException) {
          throw Exception('Erro de autenticação admin: ${e.message}');
        } else {
          // Relança a exceção se já for uma ou cria uma nova
          throw Exception(e.toString().contains('Exception:')
              ? e.toString().replaceAll('Exception: ', '')
              : 'Erro desconhecido no login do admin.');
        }
      }
    } catch (e) {
      print('Erro no login de admin: $e');
      // Garantir que o estado seja limpo em caso de erro
      _isAdminLoggedIn = false;
      _isKitchenLoggedIn = false;
      _currentUser = null;
      notifyListeners();
      // Relança a exceção formatada
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // MÉTODO LOGIN FINAL - TENTA LOGAR, SE FALHAR (EXCETO SENHA ERRADA), TENTA CRIAR
  Future<void> login(app_models.User user) async {
    // ... (código inalterado)
    try {
      print('Iniciando login/criação para: ${user.ra}');

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

      // Gerar senha a partir do telefone fornecido (apenas números)
      final password = user.phone.replaceAll(RegExp(r'[^0-9]'), '');
      print('Senha gerada a partir do telefone fornecido: $password');

      try {
        print('Tentando login com email: ${user.ra}');

        // Fazer logout primeiro para evitar conflitos de estado
        await logout();

        // Tentar fazer login
        await _auth.signInWithEmailAndPassword(
          email: user.ra,
          password: password,
        );

        // Se chegou aqui, o login foi bem-sucedido
        final currentUser = _auth.currentUser;
        if (currentUser == null || currentUser.email != user.ra) {
          // Segurança extra, não deveria acontecer se signIn funcionou
          throw Exception('Falha ao verificar usuário após login');
        }

        print('Login bem-sucedido para ${user.ra}');

        // Salvar dados localmente
        await _saveUserToLocal(user.ra, user.phone);

        // Atualizar estado do provider
        _currentUser = app_models.User(
          ra: user.ra,
          phone: user.phone,
        );
        _isAdminLoggedIn = false;
        _isKitchenLoggedIn = false;
        notifyListeners();

        // Tentar atualizar telefone e lastLogin no Firestore (não crítico)
        try {
          await _firestore.collection('users').doc(currentUser.uid).set({
            'ra': user.ra,
            'phone': user.phone, // Atualiza o telefone caso tenha mudado
            'isAdmin': false,
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('Dados do usuário ${user.ra} atualizados no Firestore');
        } catch (e) {
          print(
              'Aviso: Erro ao atualizar dados no Firestore após login para ${user.ra}: $e');
        }

        return; // Login concluído
      } on firebase_auth.FirebaseAuthException catch (authError) {
        print(
            'Falha na tentativa de login para ${user.ra}. Código: ${authError.code}');

        // CASO 1: Senha incorreta para um usuário que DEFINITIVAMENTE existe
        if (authError.code == 'wrong-password') {
          print(
              'Senha incorreta detectada para ${user.ra}. Verificando telefone...');
          // Verificar se o telefone fornecido difere do armazenado (se houver)
          try {
            final querySnapshot = await _firestore
                .collection('users')
                .where('ra', isEqualTo: user.ra)
                .limit(1)
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              final userData = querySnapshot.docs.first.data();
              final storedPhone = userData['phone'] as String?;
              if (storedPhone != null &&
                  storedPhone.isNotEmpty &&
                  storedPhone != user.phone) {
                // O usuário existe, mas o telefone fornecido é diferente do cadastrado
                throw Exception(
                    'Telefone incorreto. O telefone cadastrado para este RA é diferente.');
              } else {
                // O usuário existe, telefone igual ou não encontrado no Firestore, mas senha errada no Auth
                throw Exception('Senha (telefone) incorreta.');
              }
            } else {
              // Usuário existe no Auth (pois deu wrong-password) mas não no Firestore? Inconsistência.
              throw Exception(
                  'Senha (telefone) incorreta. Problema ao verificar dados.');
            }
          } catch (e) {
            // Relança a exceção específica gerada acima ou uma genérica
            print('Erro ao verificar telefone após senha incorreta: $e');
            throw Exception(e.toString().contains('Telefone incorreto') ||
                    e.toString().contains('Senha (telefone) incorreta')
                ? e.toString().replaceAll('Exception: ', '')
                : 'Erro ao verificar dados após senha incorreta.');
          }
        }
        // CASO 2: Qualquer outro erro de autenticação -> Tentar criar a conta
        else {
          print(
              'Erro de login (${authError.code}) para ${user.ra}. Assumindo que não existe ou credencial inválida. Tentando criar conta...');
          try {
            await _createUserAccount(user.ra, user.phone);
            print(
                'Criação de conta para ${user.ra} concluída (ou tentativa bem-sucedida).');
            // _createUserAccount já notifica listeners e atualiza estado se bem-sucedido
            return; // Criação concluída
          } catch (creationError) {
            print(
                'Erro ANINHADO ao tentar criar conta para ${user.ra} após falha no login: $creationError');
            // Relança o erro da criação, que é mais relevante agora
            // Formata a mensagem de erro da criação
            throw Exception(
                'Falha ao criar conta: ${creationError.toString().replaceAll('Exception: ', '')}');
          }
        }
      } catch (e) {
        // Outro tipo de erro durante a tentativa de login (não FirebaseAuthException)
        print(
            'Erro inesperado durante a tentativa de login para ${user.ra}: $e');
        throw Exception('Ocorreu um erro inesperado durante o login.');
      }
    } catch (e) {
      // Erro nas validações iniciais (RA/Telefone) ou relançado dos blocos internos
      print('Erro geral no método login: $e');
      // Garante que a mensagem de validação seja exibida corretamente
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // MÉTODO PARA CRIAR CONTA - AJUSTADO PARA CONTORNAR BUG DE TIPAGEM
  Future<void> _createUserAccount(String email, String phone) async {
    firebase_auth.User? createdUser;
    try {
      print('Iniciando criação de conta para: $email');

      // Gerar senha a partir do telefone (apenas números)
      final password = phone.replaceAll(RegExp(r'[^0-9]'), '');
      print('Senha gerada para criação: $password');

      // Criar usuário no Firebase Auth
      print('Tentando criar usuário no Firebase Auth: $email');
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // *** WORKAROUND PARA BUG DE TIPAGEM: Buscar o usuário atual novamente ***
      await Future.delayed(Duration(
          milliseconds: 500)); // Pequeno delay para garantir propagação
      createdUser = _auth.currentUser;

      if (createdUser == null || createdUser!.email != email) {
        print('Falha ao obter usuário recém-criado via _auth.currentUser.');
        // Tentar obter via recarga se possível (pode não funcionar dependendo do estado)
        try {
          await _auth.currentUser?.reload();
          createdUser = _auth.currentUser;
          if (createdUser == null || createdUser!.email != email) {
            throw Exception('Falha ao confirmar criação do usuário no Auth.');
          }
          print('Usuário confirmado após reload.');
        } catch (reloadError) {
          print('Erro durante reload: $reloadError');
          throw Exception('Falha ao confirmar criação do usuário no Auth.');
        }
      }

      print(
          'Usuário criado e confirmado com sucesso no Firebase Auth: ${createdUser!.uid}');

      // Salvar dados localmente
      await _saveUserToLocal(email, phone);
      print('Dados salvos localmente após criação');

      // Atualizar estado do provider e notificar ANTES do Firestore
      _currentUser = app_models.User(
        ra: email,
        phone: phone,
      );
      _isAdminLoggedIn = false;
      _isKitchenLoggedIn = false;
      notifyListeners();
      print(
          'Estado do provider ATUALIZADO e listeners NOTIFICADOS para ${email} ANTES do Firestore.');

      // Tentar salvar dados no Firestore (em segundo plano)
      _saveUserDataToFirestore(createdUser!.uid, email, phone);
    } on firebase_auth.FirebaseAuthException catch (authError) {
      print(
          'Erro ao criar usuário no Firebase Auth (${email}): ${authError.code} - ${authError.message}');
      _currentUser = null; // Limpa estado local
      notifyListeners();
      if (authError.code == 'email-already-in-use') {
        throw Exception('Este RA já está cadastrado. Tente fazer login.');
      } else if (authError.code == 'invalid-email') {
        throw Exception('O formato do RA (email) é inválido.');
      } else if (authError.code == 'weak-password') {
        throw Exception('A senha gerada (telefone) é considerada fraca.');
      } else {
        throw Exception(
            'Erro ao criar conta no Auth: ${authError.message ?? authError.code}');
      }
    } catch (e) {
      print('Erro inesperado durante a criação da conta para ${email}: $e');
      _currentUser = null; // Limpa estado local
      notifyListeners();
      // Adiciona o erro original na mensagem para depuração
      throw Exception(
          'Ocorreu um erro inesperado ao criar sua conta: ${e.toString()}');
    }
  }

  // Método auxiliar para salvar no Firestore (não bloqueante)
  Future<void> _saveUserDataToFirestore(
      String uid, String email, String phone) async {
    // ... (código inalterado)
    try {
      print(
          'Tentando salvar dados no Firestore para novo usuário $uid (em segundo plano)');
      await _firestore.collection('users').doc(uid).set({
        'ra': email,
        'phone': phone,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
      print('Dados do novo usuário $email salvos no Firestore com sucesso.');
    } catch (firestoreError) {
      print('*****************************************************');
      print(
          'ALERTA: Erro NÃO CRÍTICO ao salvar dados no Firestore para ${email} (UID: $uid): $firestoreError');
      print(
          'O usuário foi criado no Auth e pode usar o app, mas os dados no Firestore estão ausentes/inconsistentes.');
      print('Verificar permissões do Firestore e formato dos dados.');
      print('*****************************************************');
      // Não relançar o erro para não afetar o usuário que já está logado
    }
  }

  // Logout
  Future<void> logout() async {
    // ... (código inalterado)
    try {
      await _auth.signOut();
      _currentUser = null;
      _isAdminLoggedIn = false;
      _isKitchenLoggedIn = false;
      notifyListeners();
      print('Logout realizado com sucesso.');
    } catch (e) {
      print('Erro ao fazer logout: $e');
      // Mesmo em caso de erro, limpar o estado local
      _currentUser = null;
      _isAdminLoggedIn = false;
      _isKitchenLoggedIn = false;
      notifyListeners();
    }
  }
}
