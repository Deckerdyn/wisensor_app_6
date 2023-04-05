import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:wisensor_app_6/pages/weather_page.dart';
import 'dart:convert';
import '../global_data.dart';
import '../modules/weather_module.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _centros = [];
  bool _isLoading = true;
  String _message = "";

  Future<void> _fetchCentros() async {
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer ${GlobalData.token}"
    };

    http.Response response = await http.get(
      Uri.parse("https://wisensor.cl/api/app/user/centros"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      setState(() {
        _centros = jsonResponse["data"];
        _isLoading = false;
        _message = jsonResponse["message"];
      });
    } else {
      var errorResponse = jsonDecode(response.body);
      if (errorResponse.containsKey("message")) {
        var errorMessage = errorResponse["message"];
        if (errorMessage == "Unauthenticated.") {
          GlobalData.token = "";
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer ${GlobalData.token}"
    };

    http.Response response = await http.post(
      Uri.parse("https://wisensor.cl/api/app/logout"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      GlobalData.token = "";
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      var errorResponse = jsonDecode(response.body);
      if (errorResponse.containsKey("message")) {
        var errorMessage = errorResponse["message"];
        if (errorMessage == "Unauthenticated.") {
          GlobalData.token = "";
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCentros();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Centros', style: TextStyle(fontSize: 20.0)),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            AppBar(
              title: const Text('Módulos'),
              leading: const BackButton(),
            ),
            ListTile(
              leading: const Icon(
                  FontAwesomeIcons.fish,
              ),
              title: const Text('Biomasa'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WeatherModule()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.sunny,
              ),
              title: const Text('Clima'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WeatherModule()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.shield,
              ),
              title: const Text('Seguridad'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WeatherModule()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.touch_app,
              ),
              title: const Text('IoT'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WeatherModule()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.battery_5_bar_rounded,
              ),
              title: const Text('Energía'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WeatherModule()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.network_wifi_outlined,
              ),
              title: const Text('Estado de Red'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WeatherModule()),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: const Icon(
                Icons.settings,
              ),
              title: const Text('Configuraciones'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.directions_run,
              ),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                _logout(context);
              },
            ),
            const SizedBox(height: 150.0),
            Container(
              margin: EdgeInsets.fromLTRB(85, 60, 0, 0),
              child: const Text(
                'Wisensor',
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.fromLTRB(90, 0, 0, 0),
              child: const Text(
                'V 1.0',
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
      ),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _message,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                ),

              ),
              Divider(height: 1, color: Colors.grey, thickness: 1,),
              Expanded(
                child: ListView.builder(
                  itemCount: _centros.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                      children: [
                        ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WeatherPage(
                                  idu: _centros[index]["idu"],
                                  idc: _centros[index]["idc"],
                                ),
                              ),
                            );
                          },
                          title: Text(
                            _centros[index]["nombre"],
                            style: TextStyle(
                              fontSize: 21.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.white,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Latitud: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                                  ),
                                  TextSpan(text: '${_centros[index]["latitud"]}\n',style: TextStyle(fontSize: 17)),
                                  TextSpan(
                                    text: 'Longitud: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                                  ),
                                  TextSpan(text: '${_centros[index]["longitud"]}\n', style: TextStyle(fontSize: 17)),
                                ],
                              ),
                            ),
                          ),

                          trailing: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 40.0,
                              height: 40.0,

                              child: Icon(
                                Icons.keyboard_arrow_right,
                                color: Colors.white,
                                size: 60.0,
                              ),
                            ),
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey),

                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}