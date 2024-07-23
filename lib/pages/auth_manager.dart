import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;

  AuthManager._internal() {
    checkAuthState();
  }

  final storage = FlutterSecureStorage();
  final _authStateController = StreamController<bool>.broadcast();

  Stream<bool> get authStateStream => _authStateController.stream;

  Future<void> saveToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
    print('Token saved, updating stream');
    _authStateController.add(true);
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  Future<void> deleteToken() async {
    await storage.delete(key: 'auth_token');
    _authStateController.add(false);
  }

  Future<void> checkAuthState() async {
    final token = await getToken();
    print('Checking auth state, token exists: ${token != null}');
    _authStateController.add(token != null);
  }

  void dispose() {
    _authStateController.close();
  }
}