import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class BroadcastMessageProvider extends ChangeNotifier {
  static const String storageKey = 'broadcast_messages';
  List<CrisisMessage> _messages = [];

  List<CrisisMessage> get messages => List.unmodifiable(_messages);

  BroadcastMessageProvider() {
    loadMessages();
  }

  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getStringList(storageKey);
    if (messagesJson != null) {
      _messages = messagesJson
          .map((json) => CrisisMessage.fromJson(jsonDecode(json)))
          .toList();
      notifyListeners();
    }
  }

  Future<void> addMessage(CrisisMessage message) async {
    _messages.insert(0, message);
    await _saveMessages();
    notifyListeners();
  }

  Future<void> clearMessages() async {
    _messages.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    notifyListeners();
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = _messages.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(storageKey, messagesJson);
  }
}
