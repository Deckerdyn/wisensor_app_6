import 'package:Wisensor/pages/railway_home_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/security_page.dart'; // Asegúrate de importar SecurityPage
import 'services/notification_services.dart';
import 'package:upgrader/upgrader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';  // Importar localizaciones
import 'package:intl/intl.dart';  // Importar intl

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await initNotifications();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  prefs.setString('apiUrl', 'http://201.220.112.247:1880/wisensor/api/login');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

Future<String?> getToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("token");
}

Future<String?> getDb() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("db");
}

Future<int?> getEmpresasId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt("empresas_id"); // Obtener empresas_id
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wisensor Login Demo',
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white10,
            foregroundColor: Colors.white,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE74D3C),
        ),
      ),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('es', 'ES'), // Español
      ],
      locale: const Locale('es', 'ES'), // Establecer el idioma a español
      home: UpgradeAlert(
        child: AuthenticationHandler(),
      ),
    );
  }
}

class AuthenticationHandler extends StatelessWidget {
  Future<int?> _checkAuthentication() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString("token");
    int? idu = prefs.getInt("idu");

    if (savedToken != null && idu != null) {
      return idu;
    } else {
      return null;
    }
  }

  Future<String?> _checkDatabase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString("token");
    String? db = prefs.getString("db");
    int? idu = prefs.getInt("idu");

    if (savedToken != null && idu != null && db != null) {
      return db;
    } else {
      print(savedToken);
      print(idu);
      print(db);
      return null;
    }
  }

  Future<int?> _checkEmpresasId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt("empresas_id"); // Obtener empresas_id
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>( // Verifica la autenticación
      future: _checkAuthentication(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError || snapshot.data == null) {
          print("Error de autenticación o token no encontrado");
          return LoginPage();
        } else {
          print("ID de usuario: ${snapshot.data}");
          return FutureBuilder<String?>( // Verifica la base de datos
            future: _checkDatabase(),
            builder: (context, dbSnapshot) {
              if (dbSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (dbSnapshot.hasError || dbSnapshot.data == null) {
                print("Error obteniendo la base de datos");
                print(dbSnapshot.data);
                return LoginPage();
              } else {
                String db = dbSnapshot.data!;
                print("Base de datos: $db");

                // Verifica la base de datos y redirige a la página correspondiente
                if (db == "wisensor") {
                  return FutureBuilder<int?>( // Verifica el empresas_id
                    future: _checkEmpresasId(),
                    builder: (context, empresasSnapshot) {
                      if (empresasSnapshot.connectionState == ConnectionState.waiting) {
                        return Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (empresasSnapshot.hasError || empresasSnapshot.data == null) {
                        print("Error obteniendo empresas_id o no encontrado");
                        return SecurityPage(idu: snapshot.data!); // Si hay error, redirige a SecurityPage
                      } else {
                        int empresasId = empresasSnapshot.data!;
                        print("empresas_id: $empresasId");

                        if (empresasId == 2) {
                          print("Redirigiendo a HomePage");
                          return HomePage(idu: snapshot.data!); // Redirige a HomePage si empresas_id es 2
                        } else {
                          print("Redirigiendo a SecurityPage");
                          return SecurityPage(idu: snapshot.data!); // Redirige a SecurityPage para otros valores
                        }
                      }
                    },
                  );
                } else {
                  print("Base de datos desconocida: $db");
                  return LoginPage();
                }
              }
            },
          );
        }
      },
    );
  }
}
