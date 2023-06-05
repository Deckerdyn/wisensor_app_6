import 'package:flutter/material.dart';

class SecurityModule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alertas de Seguridad', style: TextStyle(fontSize: 20.0)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/security.PNG"),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}