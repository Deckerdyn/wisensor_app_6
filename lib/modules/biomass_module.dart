import 'package:flutter/material.dart';

class BiomassModule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alertas de Biomasa', style: TextStyle(fontSize: 20.0)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/biomass.PNG"),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}