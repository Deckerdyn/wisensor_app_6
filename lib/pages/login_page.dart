import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../global_data.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = "";

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json"
    };

    Map<String, String> body = {"email": email, "password": password};

    http.Response response = await http.post(
      Uri.parse(GlobalData.apiUrl),
      headers: headers,
      body: jsonEncode(body),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      String token = jsonResponse["data"]["token"];
      GlobalData.token = token;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      var errorResponse = jsonDecode(response.body);
      var errorMessage = "";

      if (errorResponse.containsKey("errors")) {
        var errors = errorResponse["errors"];
        if (errors.containsKey("email")) {
          errorMessage = errors["email"][0];
        } else if (errors.containsKey("password")) {
          errorMessage = errors["password"][0];
        }
      } else if (errorResponse.containsKey("message")) {
        var message = errorResponse["message"];
        if (message == "Las credenciales no coinciden") {
          errorMessage = "Las credenciales no coinciden";
        } else if (message == "Email no existe") {
          errorMessage = "Email no existe";
        } else if (message == "Email no es valido") {
          errorMessage = "Email no es valido";
        }
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/fondo_olas.PNG"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Wisensor',
                  style: TextStyle(
                    fontSize: 45.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 120, 0),
                  child: const Text(
                    'Versión 1.0',
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.155),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Correo',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ingrese su correo',
                          hintStyle: TextStyle(
                              fontSize: 18.0, color: Colors.grey[400]),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Contraseña',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Ingrese su contraseña',
                          hintStyle: TextStyle(
                              fontSize: 18.0, color: Colors.grey[400]),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      SizedBox(
                        width: double.infinity,
                        height: 50.0,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffdc3545),
                          ),
                          child: const Text(
                            'Ingresar',
                            style: TextStyle(
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3.0),
                      Center(
                        child: _errorMessage.isNotEmpty
                            ? Text(
                                _errorMessage,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 14),
                              )
                            : Container(),
                      ),
                    ],
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
