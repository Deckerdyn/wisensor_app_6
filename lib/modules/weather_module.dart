import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wisensor_app_6/pages/weather_page.dart';
import 'dart:convert';
import '../global_data.dart';
import '../pages/login_page.dart';

class WeatherModule extends StatefulWidget {
  @override
  _WeatherModuleState createState() => _WeatherModuleState();
}

class _WeatherModuleState extends State<WeatherModule> {
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
        title: Text('Alertas de clima', style: TextStyle(fontSize: 20.0)),
        centerTitle: true,
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
