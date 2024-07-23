import 'package:auth_flutter_nestjs/pages/auth_manager.dart';
import 'package:auth_flutter_nestjs/pages/home_page.dart';
import 'package:auth_flutter_nestjs/pages/login_page.dart';
import 'package:flutter/material.dart';


class AuthPage extends StatelessWidget {
  AuthPage({super.key});

  final AuthManager authManager = AuthManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<bool?>(
        stream: authManager.authStateStream,
        initialData: false, 
        builder: (context, snapshot) {
          print("Builder: "+ snapshot.connectionState.toString());
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("En espera...");
            return const CircularProgressIndicator();
          } else {
            if (snapshot.data == true) {
              return HomePage();
            } else {
              return LoginPage();
            }
          }
        },
      ),
    );
  }
}
