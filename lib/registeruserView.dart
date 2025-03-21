import 'dart:async';

import 'package:appasistencia/asistenciaView.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appasistencia/constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'model/bduser.dart';
import 'model/biometric_helper.dart';

class RegistroUsuarioPage extends StatefulWidget {
  final Future<String?> Function() captureFingerprint;
  final Future<void> Function(String) onFingerprintCaptured;

  const RegistroUsuarioPage({super.key, required this.captureFingerprint,
  required this.onFingerprintCaptured});

  @override
  State<RegistroUsuarioPage> createState() => _RegistroUsuarioPageState();
}

class _RegistroUsuarioPageState extends State<RegistroUsuarioPage> {
  final _formKey = GlobalKey<FormState>();

  final _dniController = TextEditingController();
  final _nombresController = TextEditingController();
  final _gradoController = TextEditingController();
  final _celularApoderadoController = TextEditingController();
  String _codigo_alumno = '';
 // bool isInitialized = false;
  bool isCapturing = false;
  bool isProcessing = false;
  String _message = '';
  String? _fingerprintData;
  bool _isFormValid = false;
  //Timer? captureTimer;

  @override
  void dispose() {
    _dniController.dispose();
    _nombresController.dispose();
    _gradoController.dispose();
    _celularApoderadoController.dispose();
    //captureTimer?.cancel();
    super.dispose();
  }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initializeDevice();
    });
    DatabaseHelper.getUsers();
    //_startContinuousCapture();
  }

 /* void _startContinuousCapture() {
    captureTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (!isCapturing && !isProcessing) {
        setState(() {
          isCapturing = true;
        });
        await _captureFingerprint();
      }
    });
  }*/

  /*Future<void> _captureFingerprint() async {
    try {
      final fingerprintData = await widget.captureFingerprint();
      if (fingerprintData!.isNotEmpty) {
        setState(() {
          isProcessing = true;
        });
        await widget.onFingerprintCaptured(fingerprintData);
        if (fingerprintData == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al capturar la huella.')),
          );
          return;
        }
        if (fingerprintData == "Dispositivo no inicializado") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al capturar la huella.')),
          );
          return;
        }

        if(fingerprintData != "Error al capturar la huella. Código de error: 57"){
          setState(() {
            _fingerprintData = fingerprintData;
            // _message = 'Huella capturada correctamente.';
          });
        }

      }
    } finally {
      setState(() {
        isCapturing = false;
        isProcessing = false;
      });
    }
  }*/

  void _validateForm() {
    setState(() {
      _isFormValid = _formKey.currentState?.validate() ?? false;
    });
  }

  Future<void> studentsSearch(String dni) async {
    final datos = await DatabaseHelper().buscarUsuarioPorDNI(dni);

    if (datos != null) { // Validamos si se encontró el usuario
      setState(() {
        _nombresController.text = datos["name"];
        _celularApoderadoController.text = datos["celular"];
        _gradoController.text = datos["grado"];
        _codigo_alumno = datos["id"];
      });
    } else {
      // Muestra un mensaje o limpia los campos si no se encontró el usuario
      setState(() {
        _nombresController.clear();
        _celularApoderadoController.clear();
        _gradoController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró un usuario con ese DNI.')),
      );
    }
  }


  void _guardarUsuario(String fingerprintData) async{
    if (_formKey.currentState!.validate()) {

          await DatabaseHelper().updateUser(
              _dniController.text,
              fingerprintData);
          await DatabaseHelper().updateEstadoStudents(_codigo_alumno, '0');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario registrado correctamente'),
              backgroundColor: Colors.green,
            ),
          );

        }
      _dniController.clear();
      _nombresController.clear();
      _celularApoderadoController.clear();
    _gradoController.clear();
      setState(() {
        _isFormValid = false;
      });
        // Limpiar el formulario después de guardar


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

  void _registerFingerprint() async {
    setState(() {
      _message = 'Coloque el dedo en el lector biométrico...';
    });

    String? fingerprintData = await BiometricHelper.captureFingerprint();

    if (fingerprintData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al capturar la huella.')),
      );
      return;
    }
    if (fingerprintData == "Dispositivo no inicializado") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al capturar la huella.')),
      );
      return;
    }
    setState(() {
      _fingerprintData = fingerprintData;
      _message = 'Huella capturada correctamente.';
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading:
          IconButton(onPressed: (){
             Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AsistenciaPage(captureFingerprint: widget.captureFingerprint, onFingerprintCaptured: widget.onFingerprintCaptured)),
            );
          }, icon: Icon(Icons.arrow_back)),

      ),
      body: SingleChildScrollView(child: Container(
        //margin: const EdgeInsets.only(top: 80),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            onChanged: _validateForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Información Personal',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Campo DNI
                TextFormField(
                  controller: _dniController,
                  decoration: InputDecoration(
                    labelText: 'DNI',
                    hintText: 'Ingrese su DNI',
                    prefixIcon: const Icon(Icons.badge, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su DNI';
                    }
                    if (value.length != 8) {
                      return 'El DNI debe tener 8 dígitos';
                    }
                    return null;
                  },
                  onChanged: (val) async{
                    if(val.length == 8) {
                      await studentsSearch(val);
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Campo Nombres
                TextFormField(
                  controller: _nombresController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Nombres',
                    hintText: 'Ingrese sus nombres completos',
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese sus nombres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo Celular de Apoderado
                TextFormField(
                  controller: _celularApoderadoController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Celular de Apoderado',
                    hintText: 'Ingrese el número de celular',
                    prefixIcon: const Icon(Icons.phone_android, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                 /* validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el número de celular';
                    }
                    if (value.length != 9) {
                      return 'El número debe tener 9 dígitos';
                    }
                    return null;
                  },*/
                ),
                const SizedBox(height: 20),

                // Campo Nombres
                TextFormField(
                  controller: _gradoController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Grado',
                    hintText: 'Ingrese su grado',
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su grado';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isInitialized ? _registerFingerprint : null,
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
                      FaIcon(FontAwesomeIcons.fingerprint, size: 25),
                      SizedBox(width: 8),
                      Text(
                        'Capturar Huella',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
               /* ElevatedButton(
                  onPressed: isInitialized ? _registerFingerprint : null,
                  child: const Text('Capturar Huella'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    disabledBackgroundColor: Colors.blue.withOpacity(0.3),
                  ),
                ),*/
               /* isProcessing
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
                ),*/
                const SizedBox(height: 10),
                Text(_message,style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
                const SizedBox(height: 30),

                // Botón Guardar
                ElevatedButton(
                  onPressed: (){
                    if(_isFormValid){
                      _guardarUsuario(_fingerprintData!);
                    }else{
                      print("nada");
                    }

                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    disabledBackgroundColor: Colors.blue.withOpacity(0.3),
                  ),
                  child: const Text(
                    'GUARDAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }
}

