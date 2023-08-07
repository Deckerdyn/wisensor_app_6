import 'package:Wisensor/services/notification_services.dart';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  //FontAwesomeIcons.loadFont('24D6EE65-7B0B-4A1F-A696-F6FA8BD6D23D');
  WidgetsFlutterBinding.ensureInitialized();
  //initialize firebase from firebase core plugin
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
  print('User granted permission: ${settings.authorizationStatus}');
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      print('Notification Title: ${message.notification?.title}');
      print('Notification Body: ${message.notification?.body}');
    }
  });
  prefs.setString('apiUrl', 'http://201.220.112.247:1880/wisensor/api/login');
  prefs.setString('token', '');

  //mostrarNotificacion();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}
Future<String?> getToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("token");
}/*
void checkAuthentication(BuildContext context) async {
  String? token = await getToken();
  if (token != null) {
    // The token exists, the user is authenticated
    // Redirect to the home page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(idu: 1,)),
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
*/
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    //checkAuthentication(); // Llamada a la función checkAuthentication en initState
  }
/*
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
*/
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
