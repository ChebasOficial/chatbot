import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Classe wrapper para lidar com possíveis problemas de cast no Firebase Auth
/// 
/// Esta classe encapsula as chamadas ao Firebase Auth e garante que os retornos
/// sejam tratados corretamente, evitando problemas de cast com PigeonUserDetails
class FirebaseAuthWrapper {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  
  /// Realiza login com email e senha
  /// 
  /// Este método encapsula a chamada original do Firebase Auth e trata
  /// possíveis erros de cast ou formato de retorno
  Future<firebase_auth.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Chamada normal ao Firebase Auth
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Se for um erro de cast para PigeonUserDetails, registra para debug
      if (e.toString().contains('PigeonUserDetails')) {
        print('Erro de cast para PigeonUserDetails detectado: $e');
      }
      
      // Propaga o erro original
      rethrow;
    }
  }
  
  /// Cria um novo usuário com email e senha
  /// 
  /// Este método encapsula a chamada original do Firebase Auth e trata
  /// possíveis erros de cast ou formato de retorno
  Future<firebase_auth.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Chamada normal ao Firebase Auth
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Se for um erro de cast para PigeonUserDetails, registra para debug
      if (e.toString().contains('PigeonUserDetails')) {
        print('Erro de cast para PigeonUserDetails detectado: $e');
      }
      
      // Propaga o erro original
      rethrow;
    }
  }
  
  /// Realiza logout do usuário atual
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  /// Método de logout para compatibilidade com código existente
  Future<void> logout() async {
    await signOut();
  }
  
  /// Obtém o usuário atual
  firebase_auth.User? get currentUser => _auth.currentUser;
}
