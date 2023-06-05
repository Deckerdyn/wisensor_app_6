import 'package:flutter/material.dart';

class IotModule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alertas de Iot', style: TextStyle(fontSize: 20.0)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/energy.PNG"),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}