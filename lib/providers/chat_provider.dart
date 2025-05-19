import 'package:flutter/material.dart';
import 'package:chatbot/models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => _messages;

  // Adicionar mensagem
  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  // Limpar todas as mensagens
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
