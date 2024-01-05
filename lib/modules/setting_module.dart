import 'package:flutter/material.dart';

class SettingModule extends StatefulWidget {
  @override
  _SettingModuleState createState() => _SettingModuleState();
}

class _SettingModuleState extends State<SettingModule> {
  bool enableCriticalAlerts = true;
  bool enableWarningAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuraciones', style: TextStyle(fontSize: 20.0)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/fondo_olas.PNG"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(0, 0, 0, 0.5),
            ),
          ),
          const SizedBox(height: 150.0),
          Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 10.0),
                Text(
                  'Ajustes de alertas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20.0),
                ListTile(
                  title: Text('Notificaciones de alertas críticas'),
                  trailing: Switch(
                    value: enableCriticalAlerts,
                    onChanged: (value) {
                      setState(() {
                        enableCriticalAlerts = value;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: Text('Notificaciones de alertas de atención'),
                  trailing: Switch(
                    value: enableWarningAlerts,
                    onChanged: (value) {
                      setState(() {
                        enableWarningAlerts = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
