import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatbot/models/user.dart';

class ChatbotAuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isAdminLoggedIn = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdminLoggedIn => _isAdminLoggedIn;

  // Inicializar o provider verificando se há um usuário logado
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final userRa = prefs.getString('userRa');
    final userPhone = prefs.getString('userPhone');
    final isAdmin = prefs.getBool('isAdmin') ?? false;

    if (userRa != null && userPhone != null) {
      if (isAdmin) {
        _isAdminLoggedIn = true;
        notifyListeners();
      } else {
        _currentUser = User(ra: userRa, phone: userPhone);
        notifyListeners();
      }
    }
  }

  // Login de usuário comum
  Future<void> login(User user) async {
    // Validar o formato do R.A.
    final raRegex = RegExp(r'^\d{8}@p4ed\.com\.br$');
    if (!raRegex.hasMatch(user.ra)) {
      throw Exception('R.A. inválido. Use o formato: 12345678@p4ed.com.br');
    }

    // Validar o formato do telefone
    final phoneRegex = RegExp(r'^\(\d{2}\) \d{5}-\d{4}$');
    if (!phoneRegex.hasMatch(user.phone)) {
      throw Exception('Telefone inválido. Use o formato: (11) 98765-4321');
    }

    // Simular um delay de autenticação
    await Future.delayed(const Duration(seconds: 1));

    // Salvar os dados do usuário
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRa', user.ra);
    await prefs.setString('userPhone', user.phone);
    await prefs.setBool('isAdmin', false);

    _currentUser = user;
    notifyListeners();
  }

  // Login administrativo
  Future<void> adminLogin(String username, String password) async {
    // Credenciais de administrador (em produção, isso seria validado no servidor)
    const adminUsername = 'admin@p4ed.com.br';
    const adminPassword = 'admin123';

    // Validar as credenciais
    if (username != adminUsername || password != adminPassword) {
      throw Exception('Credenciais inválidas');
    }

    // Simular um delay de autenticação
    await Future.delayed(const Duration(seconds: 1));

    // Salvar os dados do administrador
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRa', username);
    await prefs.setString('userPhone', '');
    await prefs.setBool('isAdmin', true);

    _isAdminLoggedIn = true;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userRa');
    await prefs.remove('userPhone');
    await prefs.remove('isAdmin');

    _currentUser = null;
    _isAdminLoggedIn = false;
    notifyListeners();
  }
}
