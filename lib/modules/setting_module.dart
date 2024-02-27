import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';

class SettingModule extends StatefulWidget {
  @override
  _SettingModuleState createState() => _SettingModuleState();
}

class _SettingModuleState extends State<SettingModule> {
  //bool enableCriticalAlerts = true;

  // Function to handle button press
  void _handleSettingsButtonPress() {
    AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

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
                  'Notificaciones de la aplicación',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20.0),
                ElevatedButton.icon(
                  onPressed: _handleSettingsButtonPress,
                  icon: Icon(Icons.settings, size: 24),
                  label: Text('Configuración de notificaciones'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red, // Color del texto del botón
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
