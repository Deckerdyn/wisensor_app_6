import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterNotificationPlugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('icono_notificacion');

  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterNotificationPlugin.initialize(initializationSettings);
}

Future<void> mostrarNotificacion() async {
  const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails('your_channel_id', 'your_channel_name');

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );

  await flutterNotificationPlugin.show(1,
      'Titulo de notificacion',
      'Esta es una notificacion de prueba.',
      notificationDetails
  );

}


