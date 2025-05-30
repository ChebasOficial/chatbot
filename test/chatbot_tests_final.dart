import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';


class MockFirebaseAuth {
  dynamic currentUser;
  Function? authStateChangesCallback;

  MockFirebaseAuth({this.currentUser});

  Future<void> signInWithEmailAndPassword({String? email, String? password}) async {
    if (email == '12345678@p4ed.com.br' && password == '11987654321') {
      currentUser = MockFirebaseUser(uid: 'user123', email: email);
      authStateChangesCallback?.call();
      return;
    } else if (email == 'admin@p4ed.com.br' && password == 'adminpass') {
      currentUser = MockFirebaseUser(uid: 'admin123', email: email);
      authStateChangesCallback?.call();
      return;
    } else if (email == 'cozinha@p4ed.com.br' && password == 'cozinhapass') {
      currentUser = MockFirebaseUser(uid: 'cozinha123', email: email);
      authStateChangesCallback?.call();
      return;
    } else if (email == 'exists@p4ed.com.br' && password != 'correctpass') {
       throw MockFirebaseAuthException(code: 'wrong-password');
    } else if (email == 'newuser@p4ed.com.br') {
       throw MockFirebaseAuthException(code: 'user-not-found');
    } else {
      throw MockFirebaseAuthException(code: 'invalid-credential');
    }
  }

  Future<void> createUserWithEmailAndPassword({String? email, String? password}) async {
     if (email == 'exists@p4ed.com.br') {
       throw MockFirebaseAuthException(code: 'email-already-in-use');
     } else if (email == 'newuser@p4ed.com.br' && password == '11911112222') {
       currentUser = MockFirebaseUser(uid: 'newuser123', email: email);
       authStateChangesCallback?.call();
       return;
     } else {
       throw MockFirebaseAuthException(code: 'creation-failed');
     }
  }

  Future<void> signOut() async {
    currentUser = null;
    authStateChangesCallback?.call();
  }

  Stream authStateChanges() {
    return Stream.fromFuture(Future.value(currentUser)).asBroadcastStream();
  }
}

class MockFirebaseUser {
  final String uid;
  final String? email;
  MockFirebaseUser({required this.uid, this.email});
  Future<void> reload() async {}
}

class MockFirebaseAuthException implements Exception {
  final String code;
  final String? message;
  MockFirebaseAuthException({required this.code, this.message});
  @override
  String toString() => 'FirebaseAuthException($code): $message';
}

class MockFirebaseFirestore {
  final Map<String, Map<String, dynamic>> _data = {
    'users': {
      'user123': {'ra': '12345678@p4ed.com.br', 'phone': '(11) 98765-4321', 'isAdmin': false},
      'exists_uid': {'ra': 'exists@p4ed.com.br', 'phone': '(11) 999998888', 'isAdmin': false},
    }
  };

  MockCollectionReference collection(String path) {
    return MockCollectionReference(path: path, firestore: this);
  }

  Future<void> _setData(String path, String docId, Map<String, dynamic> data, {bool merge = false}) async {
    if (!_data.containsKey(path)) {
      _data[path] = {};
    }
    if (merge && _data[path]!.containsKey(docId)) {
       _data[path]![docId]!.addAll(data);
    } else {
       _data[path]![docId] = data;
    }
  }

  Future<MockDocumentSnapshot> _getData(String path, String docId) async {
    final docData = _data[path]?[docId];
    return MockDocumentSnapshot(id: docId, data: docData, exists: docData != null);
  }

  Future<MockQuerySnapshot> _getCollection(String path, {String? whereField, dynamic isEqualTo}) async {
    List<MockQueryDocumentSnapshot> docs = [];
    if (_data.containsKey(path)) {
      _data[path]!.forEach((docId, docData) {
        if (whereField == null || (docData.containsKey(whereField) && docData[whereField] == isEqualTo)) {
          docs.add(MockQueryDocumentSnapshot(id: docId, data: docData));
        }
      });
    }
    return MockQuerySnapshot(docs: docs);
  }
}

class MockCollectionReference {
  final String path;
  final MockFirebaseFirestore firestore;
  MockCollectionReference({required this.path, required this.firestore});

  MockDocumentReference doc(String docId) {
    return MockDocumentReference(path: path, docId: docId, firestore: firestore);
  }

  Future<MockQuerySnapshot> where(String field, {dynamic isEqualTo}) async {
     return await firestore._getCollection(path, whereField: field, isEqualTo: isEqualTo);
  }

  Future<MockQuerySnapshot> get() async {
     return await firestore._getCollection(path);
  }
}

class MockDocumentReference {
  final String path;
  final String docId;
  final MockFirebaseFirestore firestore;
  MockDocumentReference({required this.path, required this.docId, required this.firestore});

  Future<MockDocumentSnapshot> get() async {
    return await firestore._getData(path, docId);
  }

  Future<void> set(Map<String, dynamic> data, [dynamic setOptions]) async {
    await firestore._setData(path, docId, data, merge: setOptions != null);
  }
}

class MockDocumentSnapshot {
  final String id;
  final Map<String, dynamic>? _data;
  final bool exists;
  MockDocumentSnapshot({required this.id, Map<String, dynamic>? data, required this.exists}) : _data = data;
  Map<String, dynamic>? data() => _data;
}

class MockQuerySnapshot {
  final List<MockQueryDocumentSnapshot> docs;
  MockQuerySnapshot({required this.docs});
  bool get isEmpty => docs.isEmpty;
}

class MockQueryDocumentSnapshot extends MockDocumentSnapshot {
   MockQueryDocumentSnapshot({required String id, required Map<String, dynamic> data}) : super(id: id, data: data, exists: true);
}

class MockSharedPreferences {
  final Map<String, dynamic> _prefs = {};

  Future<bool> setString(String key, String value) async {
    _prefs[key] = value;
    return true;
  }

  String? getString(String key) {
    return _prefs[key] as String?;
  }

  Future<bool> remove(String key) async {
    _prefs.remove(key);
    return true;
  }

  Future<bool> clear() async {
    _prefs.clear();
    return true;
  }
}


import 'package:chatbot/models/user.dart' as app_models;
import 'package:chatbot/models/chat_message.dart';
import 'package:chatbot/models/menu_item.dart';
import 'package:chatbot/models/order.dart';
import 'package:chatbot/models/order_status.dart';
import 'package:chatbot/providers/auth_provider.dart';
import 'package:chatbot/providers/chat_provider.dart';
import 'package:chatbot/providers/menu_provider.dart';
import 'package:chatbot/providers/order_provider.dart';
import 'package:chatbot/utils/validators.dart';
import 'package:chatbot/widgets/custom_button.dart';
import 'package:chatbot/widgets/custom_text_field.dart';
import 'package:chatbot/screens/login/login_screen.dart';
import 'package:chatbot/screens/chatbot/chatbot_screen.dart';
import 'package:chatbot/screens/inicio_screen.dart';


void main() {
  group('Validators (Unit Tests)', () {
    test('validateRA - R.A. válido deve retornar null', () {
      expect(Validators.validateRA('12345678@p4ed.com.br'), isNull);
      expect(Validators.validateRA('87654321@p4ed.com.br'), isNull);
    });
    test('validateRA - R.A. nulo ou vazio deve retornar mensagem de erro', () {
      expect(Validators.validateRA(null), contains('informe seu R.A.'));
      expect(Validators.validateRA(''), contains('informe seu R.A.'));
    });
    test('validateRA - R.A. com formato inválido deve retornar mensagem de erro', () {
      expect(Validators.validateRA('1234567@p4ed.com.br'), contains('R.A. inválido'));
      expect(Validators.validateRA('123456789@p4ed.com.br'), contains('R.A. inválido'));
      expect(Validators.validateRA('12345678@gmail.com'), contains('R.A. inválido'));
      expect(Validators.validateRA('12345678p4ed.com.br'), contains('R.A. inválido'));
      expect(Validators.validateRA('abcdefgh@p4ed.com.br'), contains('R.A. inválido'));
    });
    test('validatePhone - Telefone válido deve retornar null', () {
      expect(Validators.validatePhone('(11) 98765-4321'), isNull);
      expect(Validators.validatePhone('(99) 12345-6789'), isNull);
    });
    test('validatePhone - Telefone nulo ou vazio deve retornar mensagem de erro', () {
      expect(Validators.validatePhone(null), contains('informe seu telefone'));
      expect(Validators.validatePhone(''), contains('informe seu telefone'));
    });
    test('validatePhone - Telefone com formato inválido deve retornar mensagem de erro', () {
      expect(Validators.validatePhone('11987654321'), contains('Telefone inválido'));
      expect(Validators.validatePhone('(11)98765-4321'), contains('Telefone inválido'));
      expect(Validators.validatePhone('(11) 9876-54321'), contains('Telefone inválido'));
      expect(Validators.validatePhone('(11) 987654321'), contains('Telefone inválido'));
      expect(Validators.validatePhone('11 98765-4321'), contains('Telefone inválido'));
    });
    test('validateAdminUsername - Usuário admin válido deve retornar null', () {
      expect(Validators.validateAdminUsername('admin@p4ed.com.br'), isNull);
    });
    test('validateAdminUsername - Usuário nulo ou vazio deve retornar mensagem de erro', () {
      expect(Validators.validateAdminUsername(null), contains('informe o usuário'));
      expect(Validators.validateAdminUsername(''), contains('informe o usuário'));
    });
    test('validateAdminUsername - Usuário diferente de admin deve retornar mensagem de erro', () {
      expect(Validators.validateAdminUsername('user@p4ed.com.br'), contains('Usuário não encontrado'));
      expect(Validators.validateAdminUsername('admin@gmail.com'), contains('Usuário não encontrado'));
    });
    test('validatePassword - Senha válida (>= 6 caracteres) deve retornar null', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('password'), isNull);
      expect(Validators.validatePassword('!@#$%^'), isNull);
    });
    test('validatePassword - Senha nula ou vazia deve retornar mensagem de erro', () {
      expect(Validators.validatePassword(null), contains('informe a senha'));
      expect(Validators.validatePassword(''), contains('informe a senha'));
    });
    test('validatePassword - Senha inválida (< 6 caracteres) deve retornar mensagem de erro', () {
      expect(Validators.validatePassword('12345'), contains('pelo menos 6 caracteres'));
      expect(Validators.validatePassword('abc'), contains('pelo menos 6 caracteres'));
    });
  });

  group('Models (Unit Tests)', () {
    test('User Model - Criação e Propriedades', () {
      final user = app_models.User(ra: 'test@test.com', phone: '(11) 11111-1111');
      expect(user.ra, 'test@test.com');
      expect(user.phone, '(11) 11111-1111');
    });
    test('ChatMessage Model - Criação e Propriedades', () {
      final now = DateTime.now();
      final msg = ChatMessage(id: '1', text: 'Hi', senderId: 'a', timestamp: now);
      expect(msg.id, '1');
      expect(msg.text, 'Hi');
      expect(msg.senderId, 'a');
      expect(msg.timestamp, now);
    });
    test('MenuItem Model - Criação e Propriedades', () {
       final item = MenuItem(id: 'p1', name: 'Pizza', price: 10.0, description: 'desc', imageUrl: 'url');
       expect(item.id, 'p1');
       expect(item.name, 'Pizza');
       expect(item.price, 10.0);
    });
    test('Order Model - Criação e Propriedades', () {
       final item = MenuItem(id: 'p1', name: 'Pizza', price: 10.0, description: 'desc', imageUrl: 'url');
       final order = Order(id: 'o1', userId: 'u1', items: {item: 1}, total: 10.0, status: OrderStatus.pending, timestamp: DateTime.now());
       expect(order.id, 'o1');
       expect(order.userId, 'u1');
       expect(order.items.length, 1);
       expect(order.total, 10.0);
       expect(order.status, OrderStatus.pending);
    });
    test('OrderStatus Enum - Valores', () {
       expect(OrderStatus.values.length, greaterThan(0));
    });
  });

  group('ChatbotAuthProvider (Unit Tests)', () {
    late ChatbotAuthProvider authProvider;
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockPrefs = MockSharedPreferences();
      authProvider = ChatbotAuthProvider(/* Pass mocks here if constructor allows */);
    });

    test('Initial state - Não logado', () {
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isAdminLoggedIn, isFalse);
      expect(authProvider.isKitchenLoggedIn, isFalse);
      expect(authProvider.cachedPhone, isNull);
    });

    test('login - Sucesso com usuário existente', () async {
      final userToLogin = app_models.User(ra: '12345678@p4ed.com.br', phone: '(11) 98765-4321');
      await authProvider.login(userToLogin);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser?.ra, userToLogin.ra);
      expect(authProvider.currentUser?.phone, userToLogin.phone);
      expect(authProvider.isAdminLoggedIn, isFalse);
      expect(authProvider.isKitchenLoggedIn, isFalse);
      expect(mockPrefs.getString('user_email'), userToLogin.ra);
      expect(mockPrefs.getString('user_phone'), userToLogin.phone);
      expect(mockPrefs.getString('user_phone_${userToLogin.ra}'), userToLogin.phone);
    });

    test('login - Sucesso criando novo usuário', () async {
       final newUser = app_models.User(ra: 'newuser@p4ed.com.br', phone: '(11) 91111-2222');
       mockAuth = MockFirebaseAuth();
       authProvider = ChatbotAuthProvider(/* Pass mocks */);
       await authProvider.login(newUser);
       expect(authProvider.isLoggedIn, isTrue);
       expect(authProvider.currentUser?.ra, newUser.ra);
       expect(authProvider.currentUser?.phone, newUser.phone);
       expect(authProvider.isAdminLoggedIn, isFalse);
       expect(authProvider.isKitchenLoggedIn, isFalse);
       expect(mockPrefs.getString('user_email'), newUser.ra);
       expect(mockPrefs.getString('user_phone'), newUser.phone);
    });

    test('login - Falha com RA inválido', () async {
      final invalidUser = app_models.User(ra: 'invalidra', phone: '(11) 98765-4321');
      await expectLater(() => authProvider.login(invalidUser), throwsException);
      expect(authProvider.isLoggedIn, isFalse);
    });

    test('login - Falha com telefone inválido', () async {
      final invalidUser = app_models.User(ra: '12345678@p4ed.com.br', phone: '11987654321');
      await expectLater(() => authProvider.login(invalidUser), throwsException);
      expect(authProvider.isLoggedIn, isFalse);
    });

    test('login - Falha com senha (telefone) incorreta', () async {
      final wrongPassUser = app_models.User(ra: 'exists@p4ed.com.br', phone: '(11) 91111-2222');
      mockAuth = MockFirebaseAuth();
      authProvider = ChatbotAuthProvider(/* Pass mocks */);
      await expectLater(() => authProvider.login(wrongPassUser), throwsException);
      expect(authProvider.isLoggedIn, isFalse);
    });

    test('login - Falha na criação (RA já existe)', () async {
       final existingUser = app_models.User(ra: 'exists@p4ed.com.br', phone: '(11) 99999-8888');
       mockAuth = MockFirebaseAuth();
       authProvider = ChatbotAuthProvider(/* Pass mocks */);
       await expectLater(() => authProvider.login(existingUser), throwsException);
       expect(authProvider.isLoggedIn, isFalse);
    });

    test('loginAdmin - Sucesso', () async {
      final success = await authProvider.loginAdmin('admin@p4ed.com.br', 'adminpass');
      expect(success, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.isAdminLoggedIn, isTrue);
      expect(authProvider.isKitchenLoggedIn, isFalse);
      expect(authProvider.currentUser, isNull);
    });

    test('loginAdmin - Falha (email incorreto)', () async {
      await expectLater(() => authProvider.loginAdmin('wrong@p4ed.com.br', 'adminpass'), throwsException);
      expect(authProvider.isAdminLoggedIn, isFalse);
    });

    test('loginAdmin - Falha (senha incorreta)', () async {
      await expectLater(() => authProvider.loginAdmin('admin@p4ed.com.br', 'wrongpass'), throwsException);
      expect(authProvider.isAdminLoggedIn, isFalse);
    });

    test('loginKitchen - Sucesso', () async {
      final success = await authProvider.loginKitchen('cozinha@p4ed.com.br', 'cozinhapass');
      expect(success, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.isKitchenLoggedIn, isTrue);
      expect(authProvider.isAdminLoggedIn, isFalse);
      expect(authProvider.currentUser, isNull);
    });

    test('loginKitchen - Falha (email incorreto)', () async {
       await expectLater(() => authProvider.loginKitchen('wrong@p4ed.com.br', 'cozinhapass'), throwsException);
       expect(authProvider.isKitchenLoggedIn, isFalse);
    });

    test('loginKitchen - Falha (senha incorreta)', () async {
       await expectLater(() => authProvider.loginKitchen('cozinha@p4ed.com.br', 'wrongpass'), throwsException);
       expect(authProvider.isKitchenLoggedIn, isFalse);
    });

    test('logout - Limpa estado corretamente', () async {
      await authProvider.loginAdmin('admin@p4ed.com.br', 'adminpass');
      expect(authProvider.isAdminLoggedIn, isTrue);
      await authProvider.logout();
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isAdminLoggedIn, isFalse);
      expect(authProvider.isKitchenLoggedIn, isFalse);
    });

    test('_checkLocalUserData - Carrega telefone cacheado se existir', () async {
      await mockPrefs.setString('user_email', 'cached@p4ed.com.br');
      await mockPrefs.setString('user_phone', '(99) 91234-5678');
      await authProvider.initialize();
      expect(authProvider.cachedPhone, '(99) 91234-5678');
      expect(authProvider.isLoggedIn, isFalse);
    });
  });

  group('Widgets (Widget Tests)', () {
    testWidgets('CustomButton - Exibe texto e chama onPressed', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(text: 'Test Button', onPressed: () => pressed = true),
          ),
        ),
      );
      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.byType(CustomButton));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('CustomTextField - Exibe rótulos e permite input', (WidgetTester tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: controller,
              labelText: 'Label Test',
              hintText: 'Hint Test',
            ),
          ),
        ),
      );
      expect(find.text('Label Test'), findsOneWidget);
      expect(find.text('Hint Test'), findsOneWidget);
      await tester.enterText(find.byType(CustomTextField), 'Input Text');
      await tester.pump();
      expect(controller.text, 'Input Text');
    });

    testWidgets('CustomTextField - Validação de erro', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: CustomTextField(
                labelText: 'Required Field',
                validator: Validators.validatePassword,
              ),
            ),
          ),
        ),
      );
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Por favor, informe a senha'), findsOneWidget);
    });
  });

  group('Funcionalidade de Login (BDD)', () {
    late ChatbotAuthProvider bddAuthProvider;
    late MockFirebaseAuth bddMockAuth;
    late MockFirebaseFirestore bddMockFirestore;
    late MockSharedPreferences bddMockPrefs;

    setUp(() {
      bddMockAuth = MockFirebaseAuth();
      bddMockFirestore = MockFirebaseFirestore();
      bddMockPrefs = MockSharedPreferences();
      bddAuthProvider = ChatbotAuthProvider(/* Pass mocks */);
    });

    testWidgets('Cenário: Login de usuário comum bem-sucedido', (WidgetTester tester) async {
      await tester.pumpWidget(
         MaterialApp(home: LoginScreen(authProvider: bddAuthProvider))
      );
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.enterText(find.byKey(const Key('ra_field')), '12345678@p4ed.com.br');
      await tester.enterText(find.byKey(const Key('phone_field')), '(11) 98765-4321');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(bddAuthProvider.isLoggedIn, isTrue);
      expect(bddAuthProvider.currentUser?.ra, '12345678@p4ed.com.br');
      expect(find.byType(InicioScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('Cenário: Tentativa de login com telefone incorreto', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen(authProvider: bddAuthProvider)));
      await tester.enterText(find.byKey(const Key('ra_field')), 'exists@p4ed.com.br');
      await tester.enterText(find.byKey(const Key('phone_field')), '(11) 91111-2222');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(bddAuthProvider.isLoggedIn, isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.textContaining('Telefone incorreto'), findsOneWidget);
    });

    testWidgets('Cenário: Criação de nova conta de usuário bem-sucedida', (WidgetTester tester) async {
       await tester.pumpWidget(MaterialApp(home: LoginScreen(authProvider: bddAuthProvider)));
       await tester.enterText(find.byKey(const Key('ra_field')), 'newuser@p4ed.com.br');
       await tester.enterText(find.byKey(const Key('phone_field')), '(11) 91111-2222');
       await tester.tap(find.byKey(const Key('login_button')));
       await tester.pumpAndSettle();

       expect(bddAuthProvider.isLoggedIn, isTrue);
       expect(bddAuthProvider.currentUser?.ra, 'newuser@p4ed.com.br');
       expect(find.byType(InicioScreen), findsOneWidget);
       expect(find.byType(LoginScreen), findsNothing);
    });
  });
}

