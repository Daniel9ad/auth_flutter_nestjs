import 'dart:convert';
import 'package:auth_flutter_nestjs/pages/auth_manager.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final AuthManager authManager = AuthManager();

  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb 
          ? '166910892553-te66nr05td8bp336tta0pukkkfjp5u03.apps.googleusercontent.com'  // ID de cliente para web
          : null,  // Esto usará la configuración nativa en Android/iOS
    );
  }

  Future<String> loginWithEmailPassword(String email, String password) async {
    final response = await http.post(
      Uri.parse('http://localhost:8000/auth/login'),
      headers: {
          'Content-Type': 'application/json',
        },
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 201) {
      print("Todo salio bien:"+response.body);
      authManager.saveToken(response.body);
      return response.body;
    } else {
      print("Todo salio mal:"+response.body);
      final data = jsonDecode(response.body);
      throw Exception(data['message']);
    }
  }

  Future<void> logout() async {
    authManager.deleteToken();
  }

  Future<String> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Enviar el token de Google a tu backend
      final response = await http.post(
        Uri.parse('http://localhost:8000/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': googleAuth.idToken}),
      );

      if (response.statusCode == 201) {
        final token = jsonDecode(response.body)['access_token'];
        await authManager.saveToken(token);
        return token;
      } else {
        throw Exception('Failed to login with Google: ${response.body}');
      }
    } catch (error) {
      print('Error during Google sign in: $error');
      rethrow;
    }
  }

  // Future<String> loginWithGoogle() async {
  //   final GoogleSignIn googleSignIn = GoogleSignIn();
  //   final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  //   final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
  //   return 
    // // Send the token to your backend
    // final response = await http.post(
    //   Uri.parse('http://your-api.com/auth/google'),
    //   body: {'token': googleAuth.idToken},
    // );
    // if (response.statusCode == 200) {
    //   // Parse and return the token
    //   return response.body;
    // } else {
    //   throw Exception('Failed to login with Google');
    // }
  // }

  // Future<String> loginWithGithub() async {
  //   final result = await FlutterWebAuth.authenticate(
  //     url: "https://github.com/login/oauth/authorize?client_id=YOUR_CLIENT_ID&redirect_uri=YOUR_REDIRECT_URI",
  //     callbackUrlScheme: "your.scheme"
  //   );
    
  //   // Extract token from resulting url
  //   final token = Uri.parse(result).queryParameters['code'];
    
  //   // Send the token to your backend
  //   final response = await http.post(
  //     Uri.parse('http://your-api.com/auth/github'),
  //     body: {'code': token},
  //   );
  //   if (response.statusCode == 200) {
  //     // Parse and return the token
  //     return response.body;
  //   } else {
  //     throw Exception('Failed to login with GitHub');
  //   }
  // }
}
