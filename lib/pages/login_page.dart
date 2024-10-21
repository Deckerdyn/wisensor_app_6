import 'package:Wisensor/pages/railway_home_page.dart';
import 'package:Wisensor/pages/security_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isTimeout = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString("email");
    String? savedPassword = prefs.getString("password");

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  bool _isEmailValid(String email) {
    final emailRegExp = RegExp(
        r'^[\w-]+(\.[\w-]+)*@[a-zA-Z\d-]+(\.[a-zA-Z\d-]+)*\.[a-zA-Z\d-]+$');
    return emailRegExp.hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    return password.length >= 6;
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    bool isConnected = await _checkConnectivity();
    if (!isConnected) {
      setState(() {
        _isLoading = false;
        _errorMessage = "No hay conexión a Internet";
      });
      return;
    }

    if (email.isEmpty ||
        password.isEmpty ||
        !_isEmailValid(email) ||
        !_isPasswordValid(password)) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Credenciales inválidas";
      });
      return;
    }

    const Duration timeoutDuration = Duration(seconds: 10);
    Timer timeoutTimer = Timer(timeoutDuration, () {
      http.Client().close();
      setState(() {
        _isLoading = false;
        _isTimeout = true;
        _errorMessage = "No se pudo conectar con el servidor.";
      });
    });

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json"
    };

    Map<String, String> body = {"email": email, "password": password};

    http.Response response = await http.post(
      Uri.parse("http://201.220.112.247:1880/wisensor/api/login"),
      headers: headers,
      body: jsonEncode(body),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      String token = jsonResponse["data"]["token"];
      String db = jsonResponse["data"]["db"];
      int idu = jsonResponse["data"]["idu"];
      int empresasId = jsonResponse["data"]["empresas_id"];
      String message = jsonResponse["message"];

      print("empresas_id: $empresasId"); // Para depuración

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token);
      await prefs.setInt("idu", idu);
      await prefs.setInt("empresas_id", empresasId); // Agregado
      await _saveAuthentication(token, idu, db);

      if (_rememberMe) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString("email", email);
        prefs.setString("password", password);
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.remove("email");
        prefs.remove("password");
      }

      // Lógica de redirección basada en message y empresas_id
      if (message == "wisensor") {
        if (empresasId == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(idu: idu)),
          );
          print("id empresa 2");
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SecurityPage(idu: idu)),
          );
          print("id empresa no 2");
        }
      } else if (message == "efe") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RailwayHomePage(idu: idu)),
        );
      }

      timeoutTimer.cancel();
    } else {
      var errorResponse = jsonDecode(response.body);
      var errorMessage = errorResponse["message"];
      setState(() {
        _errorMessage = (errorMessage == "El usuario no existe en nuestro sistema.")
            ? "El usuario no existe en nuestro sistema."
            : "Las credenciales no son válidas";
      });
    }
  }


  Future<void> _saveAuthentication(String token, int idu, String db) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
    await prefs.setInt("idu", idu);
    await prefs.setString("db", db);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
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
                  const SizedBox(height: 10.0),
                  const Text(
                    'Versión 1.3.8',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
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
                        const SizedBox(height: 4.0),
                        TextField(
                          controller: _emailController,
                          onChanged: (value) {
                            setState(() {
                              _errorMessage = !_isEmailValid(value)
                                  ? 'Correo electrónico no válido'
                                  : '';
                            });
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ingrese su correo',
                            hintStyle: TextStyle(
                                fontSize: 18.0, color: Colors.grey[400]),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        const Text(
                          'Contraseña',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Ingrese su contraseña',
                            hintStyle: TextStyle(
                                fontSize: 18.0, color: Colors.grey[400]),
                            border: OutlineInputBorder(),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              child: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.start,
                          children: <Widget>[
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: Colors.red,
                              checkColor: Colors.white,
                            ),
                            Text(
                              'Recuérdame',
                              style: TextStyle(
                                  fontSize: 16.0, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        SizedBox(
                          width: double.infinity,
                          height: 50.0,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffdc3545),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(
                              valueColor:
                              AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            )
                                : const Text(
                              'Ingresar',
                              style: TextStyle(
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10.0),
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
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  launchUrl(Uri.parse("https://wisensor.cl/politicas"));
                },
                child: Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      'Políticas de Privacidad',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}