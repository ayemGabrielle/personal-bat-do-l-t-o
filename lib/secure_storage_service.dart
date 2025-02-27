import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveUserRole(String accountType) async {
    await _storage.write(key: 'user_role', value: accountType);
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: 'user_role');
  }

  static Future<void> clearUserRole() async {
    await _storage.delete(key: 'user_role');
  }

  static Future<Map<String, String>> getUser () async {
    return await _storage.readAll();
  }
}
