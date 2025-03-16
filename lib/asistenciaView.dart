import 'package:appasistencia/registeruserView.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_mobile_vision_2/flutter_mobile_vision_2.dart'
as barcode;
import 'package:telephony/telephony.dart';
import 'model/bduser.dart';
import 'package:intl/intl.dart';

class AsistenciaPage extends StatefulWidget {
  const AsistenciaPage({super.key});

  @override
  _AsistenciaPageState createState() => _AsistenciaPageState();
}

class _AsistenciaPageState extends State<AsistenciaPage> {

  String dni = "";
  String dni_capturado = "________";
  String nombre_capturado = "________________";
  String cel_capturado = "";
  String _horaRegistro = "";
  final Telephony telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    _requestSmsPermission();
  }

  Future<void> _requestSmsPermission() async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se requieren permisos para enviar SMS')),
      );
    }
  }

  Future<void> _enviarMensaje() async {
    String numeroApoderado = cel_capturado; // Reemplaza con el número real del apoderado
    const mensaje = 'El estudiante ha registrado su asistencia después de las 19:30.';

    try {
      await telephony.sendSms(
        to: numeroApoderado,
        message: mensaje,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje enviado al apoderado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje: $e')),
      );
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
          dni_capturado = identifiedUser![0]["DNI"];
          nombre_capturado = identifiedUser[0]["NOMBRES"];
          cel_capturado = identifiedUser[0]["CELULAR"];
          _horaRegistro = DateFormat('HH:mm:ss').format(now);
        });

        // Verificar si es después de las 10:30
        final limite = DateTime(now.year, now.month, now.day, 10, 30);
        if (now.isAfter(limite)) {
          await _enviarMensaje();
        }


      }
    } catch (e) {
      print("Error: $e");
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegistroUsuarioPage()),
            );
          }, icon: Icon(Icons.person_add))
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
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person,
                  size: 150,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),

              // Labels para DNI y NOMBRES
               Text(
                'DNI: $dni_capturado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
               Text(
                'NOMBRES: $nombre_capturado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Label para hora de registro
              Container(
                width: size.width*0.8,
                child: Text(
                  'Asistencia registrada a las: ${_horaRegistro ?? "No registrado"}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),

              const SizedBox(height: 40),

              // Botones de asistencia
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
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
                  SizedBox(height: 10,),
                  ElevatedButton(
                    onPressed: () async{


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
                        FaIcon(FontAwesomeIcons.faceSmile, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Face ID',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

