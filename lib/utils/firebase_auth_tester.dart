import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthTester {
  static Future<String> testFirebaseAuth() async {
    StringBuffer result = StringBuffer();
    
    try {
      result.writeln("Iniciando teste de conexão com Firebase...");
      
      // Verificar se o Firebase está inicializado
      if (Firebase.apps.isNotEmpty) {
        result.writeln("✅ Firebase inicializado com sucesso");
      } else {
        result.writeln("❌ Firebase não inicializado");
        return result.toString();
      }
      
      // Testar conexão com Firestore
      try {
        final testCollection = FirebaseFirestore.instance.collection('test');
        await testCollection.add({
          'timestamp': FieldValue.serverTimestamp(),
          'test': 'Teste de conexão',
        });
        result.writeln("✅ Conexão com Firestore estabelecida com sucesso");
      } catch (e) {
        result.writeln("❌ Erro ao conectar com Firestore: $e");
      }
      
      // Testar verificação de usuário existente
      try {
        final testEmail = "12345678@p4ed.com.br";
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('ra', isEqualTo: testEmail)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          result.writeln("✅ Verificação de usuário existente funcionando");
          result.writeln("   Usuário de teste encontrado: $testEmail");
        } else {
          result.writeln("ℹ️ Nenhum usuário encontrado com o email de teste");
        }
      } catch (e) {
        result.writeln("❌ Erro ao verificar usuário existente: $e");
      }
      
      result.writeln("\nTeste concluído!");
      
    } catch (e) {
      result.writeln("❌ Erro durante o teste: $e");
    }
    
    return result.toString();
  }
}
