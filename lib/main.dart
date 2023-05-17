import 'package:Wisensor/services/notification_services.dart';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await initNotifications();

  prefs.setString('apiUrl', 'https://wisensor.cl/api/app/login');
  prefs.setString('token', '');

  mostrarNotificacion();
  runApp(MyApp());
}
Future<String?> getToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("token");
}
void checkAuthentication(BuildContext context) async {
  String? token = await getToken();
  if (token != null) {
    // The token exists, the user is authenticated
    // Redirect to the home page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  } else {
    // The token doesn't exist, the user is not authenticated
    // Redirect to the login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    checkAuthentication(); // Llamada a la función checkAuthentication en initState
  }

  void checkAuthentication() async {
    String? token = await getToken();
    if (token != null) {
      // The token exists, the user is authenticated
      // Redirect to the home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // The token doesn't exist, the user is not authenticated
      // Redirect to the login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

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
