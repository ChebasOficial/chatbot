import 'package:flutter/material.dart';

// Classe para definir as ações dos botões
class ChatAction {
  final String label;
  final VoidCallback action;

  ChatAction({required this.label, required this.action});
}

// Classe para representar uma mensagem no chat
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isActionButtons; // Indica se esta mensagem deve renderizar botões
  final List<ChatAction> actions; // Lista de ações para os botões

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isActionButtons = false, // Valor padrão: não é botão de ação
    this.actions = const [], // Valor padrão: lista vazia de ações
  });
}
