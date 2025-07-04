// lib/utils/user_data_manager.dart
import 'package:shared_preferences/shared_preferences.dart';


class UserDataManager {
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhone = 'user_phone';


  static Future<String> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserName) ?? 'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }


  static Future<String> getUserPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserPhone) ?? '';
    } catch (e) {
      return '';
    }
  }


  static Future<bool> saveUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyUserName, name);
    } catch (e) {
      return false;
    }
  }


  static Future<bool> saveUserPhone(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_keyUserPhone, phone);
    } catch (e) {
      return false;
    }
  }


  static Future<Map<String, String>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'name': prefs.getString(_keyUserName) ?? 'Unknown User',
        'phone': prefs.getString(_keyUserPhone) ?? '',
      };
    } catch (e) {
      return {
        'name': 'Unknown User',
        'phone': '',
      };
    }
  }


  static Future<bool> hasUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_keyUserName);
      return name != null && name.isNotEmpty;
    } catch (e) {
      return false;
    }
  }


  static Future<bool> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserPhone);
      return true;
    } catch (e) {
      return false;
    }
  }
}
