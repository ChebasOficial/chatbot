import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isButton;
  final VoidCallback? onButtonPressed;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isButton = false,
    this.onButtonPressed,
  });
}
