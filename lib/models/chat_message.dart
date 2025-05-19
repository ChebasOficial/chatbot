import 'package:flutter/material.dart';
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? ra;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.ra,
  });
}
