import 'dart:async';
import 'dart:typed_data';
import 'package:appasistencia/constants.dart';
import 'package:appasistencia/registeruserView.dart';
import 'package:appasistencia/views/register_asist.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_mobile_vision_2/flutter_mobile_vision_2.dart'
as barcode;
import 'package:telephony/telephony.dart';
import 'model/bduser.dart';
import 'package:intl/intl.dart';

import 'model/biometric_helper.dart';

class AsistenciaPage extends StatefulWidget {

  final Future<String?> Function() captureFingerprint;
  final Future<void> Function(String) onFingerprintCaptured;

  const AsistenciaPage({super.key, required this.captureFingerprint,
    required this.onFingerprintCaptured});

  @override
  _AsistenciaPageState createState() => _AsistenciaPageState();
}

class _AsistenciaPageState extends State<AsistenciaPage> {

  String dni = "";
  String dni_capturado = "________";
  String nombre_capturado = "________________";
  String grado_capturado = "________________";
  String seccion_capturado = "________________";
  String cel_capturado = "";
  String _horaRegistro = "";
  String _estado_registro = "";
  String _fechaRegistro = "";
  String id_student_capturado = "";
  bool isCapturing = false;
  bool isProcessing = false;
  Timer? captureTimer;
  //isInitialized = false;
  final Telephony telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    _startContinuousCapture();
    //_initializeDevice();
    //_requestSmsPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!ModalRoute.of(context)!.isCurrent) {
      captureTimer?.cancel(); // Cancela el temporizador si la ruta actual cambia
    }
  }

  @override
  void dispose() {
    captureTimer?.cancel();
    super.dispose();
  }

  void _initializeDevice() async {
    String initMessage = await BiometricHelper.initDevice();

    if (initMessage.contains("correctamente")) {
      setState(() {
        isInitialized = true; // Marcar como inicializado
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ $initMessage")),
      );

    } else {
      setState(() {
        isInitialized = false; // Marcar como no inicializado
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ $initMessage")),
      );
    }
  }

  Future<void> _requestSmsPermission() async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se requieren permisos para enviar SMS')),
      );
    }
  }

  Future<bool> _enviarMensaje(String tipo) async {
    String numeroApoderado = cel_capturado; // Reemplaza con el número real del apoderado
    String mensaje = 'El estudiante $nombre_capturado ha registrado su asistencia a las $_horaRegistro, lo cual se considera $tipo';

    try {
      await telephony.sendSms(
        to: numeroApoderado,
        message: mensaje,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje enviado al apoderado')),
      );
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: $e')),
      );
      return false;
    }
  }

  void scanBarcode2() async {
    List<barcode.Barcode> barcodes = [];
    final now = DateTime.now();
    try {
      barcodes = await barcode.FlutterMobileVision.scan(
        waitTap: false,
        formats: barcode.Barcode.CODE_128,
        scanArea: barcode.FlutterMobileVision.PREVIEW,
        showText: true,
        preview: barcode.FlutterMobileVision.PREVIEW,
        autoFocus: true,
        flash: false,
      );
      if (barcodes.isNotEmpty) {
        for (barcode.Barcode barco in barcodes) {
          print(
              'barcodevalueis ${barco.displayValue} ${barco
                  .getFormatString()} ${barco.getValueFormatString()}');
          // ignore: unnecessary_string_interpolations
          setState(() {
            // ignore: unnecessary_string_interpolations

            dni = '${barco.displayValue}';
          });
        }
        List? identifiedUser = await DatabaseHelper().identifyUserDni(dni);
        setState(() {
          id_student_capturado = identifiedUser![0]["IDSTUDENT"];
          dni_capturado = identifiedUser![0]["DNI"];
          nombre_capturado = identifiedUser[0]["NOMBRES"];
          cel_capturado = identifiedUser[0]["CELULAR"];
          grado_capturado = identifiedUser[0]["GRADO"];
          seccion_capturado = identifiedUser[0]["SECCION"];
          _horaRegistro = DateFormat('HH:mm:ss').format(now);
          _fechaRegistro = DateFormat('yyyy-mm-dd').format(now);
        });

        // Verificar si es después de las 10:30
        final limite = DateTime(now.year, now.month, now.day, 10, 30);
        if (now.isAfter(limite)) {
          await _enviarMensaje("");
        }


      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _guardarAsistencia(String tipo, String mensaje_enviado) async{


      await DatabaseHelper().insertAsist(
          id_student_capturado,
          _fechaRegistro,
      _horaRegistro,tipo, idusuario_capturado, mensaje_enviado);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asistencia registrada correctamente'),
          backgroundColor: Colors.green,
        ),
      );


  }

  void _startContinuousCapture() {
    captureTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (!isCapturing && !isProcessing) {
        setState(() {
          isCapturing = true;
        });
        if(isInitialized == true){
          await _captureFingerprint();
        }

      }
    });
  }

  Future<void> _captureFingerprint() async {
    final now = DateTime.now();
    bool rpta = false;
    String mensaje_enviado = "0";
    try {
      final fingerprintData = await widget.captureFingerprint();
      if (fingerprintData!.isNotEmpty) {
        setState(() {
          isProcessing = true;
        });
        await widget.onFingerprintCaptured(fingerprintData);
        if (fingerprintData == null || fingerprintData == "Dispositivo no inicializado") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al capturar la huella.')),
          );
          return;
        }

        print("HUELLA LEIDA: $fingerprintData");

        if(fingerprintData != "Error al capturar la huella. Código de error: 57"){
          final storedUsers = await DatabaseHelper.getUsers();
          bool userFound = false;
          Map<String, dynamic>? matchedUser; // Almacena el usuario coincidente

          for (var user in storedUsers) {
            Uint8List fingerprintBytes = user['fingerprint'];
            String storedTemplate = fingerprintBytes.join(',');

            bool match = await BiometricHelper.matchFingerprint(
                fingerprintData, storedTemplate);

            if (match) {
              userFound = true;
              matchedUser = user; // Almacena el usuario coincidente
              break;
            }
          }

          // Actualizar la interfaz de usuario solo después de que el bucle esté completo
          if (mounted) { // Comprobar si el widget todavía está en el árbol
            if (userFound && matchedUser != null) {
              setState(() {
                dni_capturado = matchedUser!["dni"];
                id_student_capturado = matchedUser["id"];
                nombre_capturado = matchedUser["name"];
                cel_capturado = matchedUser["celular"];
                grado_capturado = matchedUser["grado"];
                seccion_capturado = matchedUser["seccion"];
                _horaRegistro = DateFormat('HH:mm:ss').format(now);
                _fechaRegistro = DateFormat('yyyy-MM-dd').format(now);
              });

              final limite = DateTime(now.year, now.month, now.day, 07, 50);
              final ingreso = DateTime(now.year, now.month, now.day, 07, 00);
              final limite_ingreso = DateTime(now.year, now.month, now.day, 10, 00);
              final salida = DateTime(now.year, now.month, now.day, 15, 30);
              String tipo = "";
              if(now.isAfter(ingreso) && now.isBefore(limite_ingreso)){
                tipo = "I";
              }else if(now.isAfter(limite_ingreso)){
                tipo = "S";
              }

              if (now.isAfter(limite) && now.isBefore(limite_ingreso)) {
                setState(() {
                  _estado_registro = "TARDANZA";
                });
                rpta = await _enviarMensaje(_estado_registro);

              }else if(now.isAfter(limite_ingreso) && now.isBefore(salida)){
                setState(() {
                  _estado_registro = "SALIDA ANTICIPADA";
                });
               rpta =  await _enviarMensaje(_estado_registro);
              }else{
                _estado_registro= "";
              }
              if(rpta){
                mensaje_enviado = '1';
              }else{
                mensaje_enviado = '0';
              }
              _guardarAsistencia(tipo, mensaje_enviado);
            } else {
              /*ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Huella no registrada.')),
            );*/
            }
          }
        }

      }
    } finally {
      setState(() {
        isCapturing = false;
        isProcessing = false;
      });
    }
  }

  Future<void> _compareFingerprint() async {
    final now = DateTime.now();
    /*if (!isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El dispositivo aún no está inicializado.')),
      );
      return;
    }*/

    String? capturedTemplate = await BiometricHelper.captureFingerprint();

    if (capturedTemplate == null || capturedTemplate == "Dispositivo no inicializado") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al capturar la huella.')),
      );
      return;
    }

    print("HUELLA LEIDA: $capturedTemplate");

    final storedUsers = await DatabaseHelper.getUsers();
    bool userFound = false;
    Map<String, dynamic>? matchedUser; // Almacena el usuario coincidente

     for (var user in storedUsers) {
      Uint8List fingerprintBytes = user['fingerprint'];
      String storedTemplate = fingerprintBytes.join(',');

      bool match = await BiometricHelper.matchFingerprint(
          capturedTemplate, storedTemplate);

      if (match) {
        userFound = true;
        matchedUser = user; // Almacena el usuario coincidente
        break;
      }
    }

    // Actualizar la interfaz de usuario solo después de que el bucle esté completo
    if (mounted) { // Comprobar si el widget todavía está en el árbol
      if (userFound && matchedUser != null) {
        setState(() {
          dni_capturado = matchedUser!["dni"];
          nombre_capturado = matchedUser!["name"];
          cel_capturado = matchedUser!["celular"];
          _horaRegistro = DateFormat('HH:mm:ss').format(now);
        });

        final limite = DateTime(now.year, now.month, now.day, 10, 30);
        if (now.isAfter(limite)) {
          await _enviarMensaje("");
        }
      } else {
       /* ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Huella no registrada.')),
        );*/
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcación de Asistencia'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: (){
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegistroUsuarioPage(captureFingerprint: widget.captureFingerprint, onFingerprintCaptured: widget.onFingerprintCaptured)),
            );
          }, icon: Icon(Icons.person_add)),
          IconButton(onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegistroAsistencias()),
            );
          }, icon: Icon(Icons.list)),
          IconButton(
            icon: Icon(Icons.upload),
            onPressed: () {
              // Acción de transferencia
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cuadro con silueta de persona
              isProcessing
                  ? CircularProgressIndicator()
                  : Icon(
                Icons.fingerprint,
                size: 100,
                color: isCapturing ? Colors.blue : Colors.grey,
              ),
              SizedBox(height: 20),
              Text(
                isCapturing ? 'Capturando huella...' : 'Esperando huella...',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Labels para DNI y NOMBRES
               Text(
                'BIENVENIDO',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
               Container(
                 alignment: Alignment.center,
                 margin: EdgeInsets.symmetric(horizontal: 10),
                 width: size.width*0.9,
                 child:
                   Text(
                     '$nombre_capturado',
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),textAlign: TextAlign.center,
                   ),
               ),
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(horizontal: 10),
                width: size.width*0.9,
                child:
                Text(
                  'Grado: $grado_capturado',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.symmetric(horizontal: 10),
                width: size.width*0.9,
                child:
                Text(
                  'Sección: $seccion_capturado',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),textAlign: TextAlign.center,
                ),
              ),
// Label para hora de registro
              const SizedBox(height: 30),
              Container(
                width: size.width*0.8,
                child: Text(
                  'Asistencia registrada a las: ${_horaRegistro ?? "No registrado"}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              Container(
                width: size.width*0.8,
                child: Text(
                  '$_estado_registro',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),textAlign: TextAlign.center,
                ),
              ),


             /* const SizedBox(height: 40),

              // Botones de asistencia
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  /*ElevatedButton(
                    onPressed: () {
                      scanBarcode2();
                      // Lógica para asistencia con DNI
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    child: const Text(
                      'Asistencia con DNI',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 10,),*/
                  ElevatedButton(
                    onPressed: () async{

                      await _compareFingerprint();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(FontAwesomeIcons.fingerprint, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Registrar asistencia',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}

