import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountInitializer {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para inicializar contas especiais (admin e cozinha)
  Future<void> initializeSpecialAccounts() async {
    try {
      // Inicializar conta de admin
      await _initializeAccount(
        email: 'admin@p4ed.com.br',
        password: 'admin123',
        role: 'admin',
      );

      // Inicializar conta de cozinha
      await _initializeAccount(
        email: 'cozinha@p4ed.com.br',
        password: 'cozinha123',
        role: 'kitchen',
      );

      print('Contas especiais inicializadas com sucesso!');
    } catch (e) {
      print('Erro ao inicializar contas especiais: $e');
    }
  }

  // Método auxiliar para inicializar uma conta específica
  Future<void> _initializeAccount({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Verificar se a conta já existe
      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('Conta $email já existe, fazendo logout...');
        await _auth.signOut();
        return;
      } catch (e) {
        // Se o erro for "user-not-found", criar a conta
        if (e is FirebaseAuthException && e.code == 'user-not-found') {
          print('Conta $email não encontrada, criando...');
          
          // Criar a conta no Firebase Auth
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          // Salvar dados adicionais no Firestore
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'email': email,
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          print('Conta $email criada com sucesso!');
          
          // Fazer logout para não interferir no fluxo normal
          await _auth.signOut();
        } else {
          // Se for outro erro, propagar
          print('Erro ao verificar conta $email: $e');
          throw e;
        }
      }
    } catch (e) {
      print('Erro ao inicializar conta $email: $e');
      throw e;
    }
  }
}
