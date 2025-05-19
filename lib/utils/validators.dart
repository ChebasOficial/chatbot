import 'package:flutter/material.dart';

class Validators {
  // Validação de R.A.
  static String? validateRA(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, informe seu R.A.';
    }

    final raRegex = RegExp(r'^\d{8}@p4ed\.com\.br$');
    if (!raRegex.hasMatch(value)) {
      return 'R.A. inválido. Use o formato: 12345678@p4ed.com.br';
    }

    return null;
  }

  // Validação de telefone
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, informe seu telefone';
    }

    final phoneRegex = RegExp(r'^\(\d{2}\) \d{5}-\d{4}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Telefone inválido. Use o formato: (11) 98765-4321';
    }

    return null;
  }

  // Validação de usuário administrativo
  static String? validateAdminUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, informe o usuário';
    }

    if (value != 'admin@p4ed.com.br') {
      return 'Usuário não encontrado';
    }

    return null;
  }

  // Validação de senha
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, informe a senha';
    }

    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }

    return null;
  }
}
