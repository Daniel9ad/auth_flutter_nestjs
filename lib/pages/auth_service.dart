import 'dart:convert';
import 'package:auth_flutter_nestjs/pages/auth_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String backendURL = "http://localhost:8000";
  final AuthManager authManager = AuthManager();

  Future<String> loginWithEmailPassword(String email, String password) async {
    final response = await http.post(
      Uri.parse('$backendURL/auth/login'),
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
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign in was cancelled');
    }
    print("Se creo googleUser:"+googleUser.toString());
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    print("Se creo googleAuth:"+googleAuth.toString());
    final response = await http.post(
      Uri.parse('$backendURL/auth/login-social'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'email': googleUser.email, 'provider': 'google'}),
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

  Future<String> loginWithGithub() async {
    const githubClientId = 'Ov23liNvdltLDLiUrSLq';
    const githubClientSecret = 'ae9d307bb2447155ae897af9ab509be21cd7b054';
    const redirectUrl = 'app.prueba.movil.ccbol.scheme://callback';

    const url = 'https://github.com/login/oauth/authorize?client_id=$githubClientId&redirect_uri=$redirectUrl';
    print("Url:"+url);
    final result = await FlutterWebAuth.authenticate(
      url: url,
      callbackUrlScheme: "app.prueba.movil.ccbol.scheme"
    );
    print("Creacion:"+result.toString());
    final code = Uri.parse(result).queryParameters['code'];

    final response = await http.post(
      Uri.parse('https://github.com/login/oauth/access_token'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'client_id': githubClientId,
        'client_secret': githubClientSecret,
        'code': code,
      }),
    );
    print("Respuesta1:"+response.toString());
    if (response.statusCode == 200) {
      final accessToken = jsonDecode(response.body)['access_token'];

      // Obtener información del usuario
      final userResponse = await http.get(
        Uri.parse('https://api.github.com/user'),
        headers: {
          'Authorization': 'token $accessToken',
        },
      );

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        final email = userData['email'];

        final backendResponse = await http.post(
          Uri.parse('$backendURL/auth/login-social'),
          headers: {
            'Content-Type': 'application/json'
          },
          body: jsonEncode({'email': email, 'provider': 'github'}),
        );

        if (backendResponse.statusCode == 201) {
          print("Inicio de sesión con GitHub exitoso: " + backendResponse.body);
          authManager.saveToken(backendResponse.body);
          return backendResponse.body;
        } else {
          print("Error del backend: " + backendResponse.body);
          final data = jsonDecode(backendResponse.body);
          throw Exception(data['message']);
        }
      } else {
        throw Exception('No se pudo obtener la información del usuario de GitHub');
      }
    } else {
      throw Exception('Falló la autenticación de GitHub');
    }
  }
}
