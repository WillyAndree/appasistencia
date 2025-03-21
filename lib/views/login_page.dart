import 'package:appasistencia/asistenciaView.dart';
import 'package:appasistencia/model/utils/nisira.dart';
import 'package:appasistencia/viewmodel/users/users_list.dart';
import 'package:appasistencia/views/firgerprint_capture.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telephony/telephony.dart';
import '../constants.dart';
import '../model/bduser.dart';
import '../model/biometric_helper.dart';
import '../model/utils/dialogs.dart';
import '../model/utils/responses.dart';
import 'package:convert/convert.dart';
import 'dart:typed_data';
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _dniController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  final Telephony telephony = Telephony.instance;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initializeDevice();
      _requestSmsPermission();
    });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  void _initializeDevice() async {
    // Mostrar el loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Inicializando dispositivo..."),
              ],
            ),
          ),
        );
      },
    );

    // Ejecutar la inicialización
    String initMessage = await BiometricHelper.initDevice();

    // Cerrar el loader
    Navigator.of(context).pop();

    if (initMessage.contains("correctamente")) {
      setState(() {
        isInitialized = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ $initMessage")),
      );
    } else {
      setState(() {
        isInitialized = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ $initMessage")),
      );
    }
  }

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _requestSmsPermission() async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se requieren permisos para enviar SMS')),
      );
    }
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AsistenciaPage(
            captureFingerprint: captureFingerprint!,
            onFingerprintCaptured: onFingerprintCaptured,
          ),
        ),
      );
    }
  }

  Future<void> loginSearch(String login, String password) async {
    String? clave = Nisira.encriptar(pass: password);
    final datos = await DatabaseHelper().buscarUsuarioLogin(login.toUpperCase(), clave!);

    if (datos != null) { // Validamos si se encontró el usuario
      setState(() {
        idusuario_capturado = datos["id"].toString();
      });

        _login();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales Incorrectas. Revísalas y vuelve a intentar')),
      );
    }
  }

  Future<String?> captureFingerprint() async {
    // Aquí va el código para capturar la huella usando tu comunicación nativa.
    return await BiometricHelper.captureFingerprint();
  }

  Future<void> onFingerprintCaptured(String fingerprintData) async {
    // Aquí manejas el procesamiento y guardado de la huella en SQLite o cualquier otra lógica.
    print('Huella capturada: $fingerprintData');
  }

  String convertIntListToHexString(List<int> intList) {
    // Convierte la lista de enteros a un Uint8List
    Uint8List uint8List = Uint8List.fromList(intList);

    // Convierte a cadena hexadecimal
    return hex.encode(uint8List);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                        Container(
                            //margin: const EdgeInsets.only(right: 20),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                                color: Colors.blue.shade900,
                                borderRadius: BorderRadius.circular(50)),
                            child: IconButton(
                              onPressed: (() async {
                                await UserFetcher().fetchAndStoreUsers(context, "https://colegiojorgebasadre.quipukey.pe/index.php/datosmovil/getSincronizarDatos");
                              }),
                              icon: const Icon(
                                Icons.sync,
                                color: Colors.white,
                              ),
                            ))
                      ],),
                      Text('Inicio de Sesión',
                          style: TextStyle(fontSize: 24, color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _dniController,
                        keyboardType: TextInputType.text,
                        //inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(labelText: 'Usuario', border: OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El USUARIO es requerido.';
                          }
                          /*if (value.length != 8) {
                            return 'El DNI debe tener exactamente 8 dígitos.';
                          }*/
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La contraseña es requerida.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed:() async{
                          await loginSearch(_dniController.text, _passwordController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          backgroundColor: Colors.blue.shade700,
                        ),
                        child: Text('Ingresar', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
