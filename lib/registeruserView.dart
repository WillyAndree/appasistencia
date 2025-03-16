import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'model/bduser.dart';
import 'model/biometric_helper.dart';

class RegistroUsuarioPage extends StatefulWidget {
  const RegistroUsuarioPage({super.key});

  @override
  State<RegistroUsuarioPage> createState() => _RegistroUsuarioPageState();
}

class _RegistroUsuarioPageState extends State<RegistroUsuarioPage> {
  final _formKey = GlobalKey<FormState>();

  final _dniController = TextEditingController();
  final _nombresController = TextEditingController();
  final _celularApoderadoController = TextEditingController();
  bool isInitialized = false;
  bool _isFormValid = false;

  @override
  void dispose() {
    _dniController.dispose();
    _nombresController.dispose();
    _celularApoderadoController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    DatabaseHelper.getUsers();
    _initializeDevice();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _formKey.currentState?.validate() ?? false;
    });
  }

  void _guardarUsuario(String fingerprintData) {
    if (_formKey.currentState!.validate()) {

          List<double>? _faceFeatures = [];
          DatabaseHelper.insertUser(
              _nombresController.text, _dniController.text,
              _celularApoderadoController.text, _faceFeatures,
              fingerprintData!);
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
    setState(() {
      _isFormValid = false;
    });
        // Limpiar el formulario después de guardar


  }
  void _initializeDevice() async {
    String initMessage = await BiometricHelper.initDevice();

    if (initMessage.contains("correctamente")) {
      setState(() {
        isInitialized = true; // Marcar como inicializado
      });
      print("✅ $initMessage");
    } else {
      setState(() {
        isInitialized = false; // Marcar como no inicializado
      });
      print("❌ $initMessage");
    }
  }

  void _registerFingerprint() async {
    if (!isInitialized) { // Verificar si el dispositivo está inicializado antes de capturar la huella
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El dispositivo aún no está inicializado.')),
      );
      return;
    }

    String? fingerprintData = await BiometricHelper.captureFingerprint();

    if (fingerprintData != null && fingerprintData != "Dispositivo no inicializado") {
      print("HUELLA LEIDA: "+fingerprintData);

      _guardarUsuario(fingerprintData);

     /* ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Huella registrada correctamente.')),
      );*/
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar la huella.')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
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
                const SizedBox(height: 20),
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
                ),
                const SizedBox(height: 20),

                // Campo Nombres
                TextFormField(
                  controller: _nombresController,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el número de celular';
                    }
                    if (value.length != 9) {
                      return 'El número debe tener 9 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Botón Guardar
                ElevatedButton(
                  onPressed: _isFormValid ? _registerFingerprint : null,
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
      ),
    );
  }
}

