import 'package:Wisensor/services/notification_services.dart';
import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  mostrarNotificacion();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wisensor Login Demo',
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        elevatedButtonTheme: ElevatedButtonThemeData(

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white10, // background (button) color
            foregroundColor: Colors.white, // foreground (text) color
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE74D3C),
        ),
        /* dark theme settings */
      ),

      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: LoginPage(),

    );
  }
}
