import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import 'model/bduser.dart';

class FaceRegistrationScreen extends StatefulWidget {
  @override
  _FaceRegistrationScreenState createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(enableClassification: true),
  );
  final TextEditingController _nameController = TextEditingController();
  List<double>? _faceFeatures;

  Future<void> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      detectFace(_image!);
    }
  }

  Future<void> detectFace(File image) async {
    final inputImage = InputImage.fromFile(image);
    final List<Face> faces = await _faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      Face face = faces.first;
      setState(() {
        _faceFeatures = extractFaceFeatures(face);
      });
      print("✅ Rostro detectado y características extraídas.");
    } else {
      print("❌ No se detectó ningún rostro.");
    }
  }

  List<double> extractFaceFeatures(Face face) {
    return [
      face.headEulerAngleX ?? 0.0,
      face.headEulerAngleY ?? 0.0,
      face.headEulerAngleZ ?? 0.0,
      face.smilingProbability ?? 0.0,
    ];
  }

  Future<void> saveFace() async {
    if (_faceFeatures != null && _nameController.text.isNotEmpty) {
    //  await DatabaseHelper.insertUser(_nameController.text, _faceFeatures!);
      print("✅ Rostro guardado en la base de datos.");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Rostro registrado con éxito"),
      ));
    } else {
      print("❌ Error al guardar el rostro.");
    }
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registrar Rostro")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _image != null
              ? Image.file(_image!, width: 200, height: 200, fit: BoxFit.cover)
              : Icon(Icons.person, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: "Nombre del Usuario"),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: pickImage,
            child: Text("Capturar Rostro"),
          ),
          ElevatedButton(
            onPressed: saveFace,
            child: Text("Guardar Rostro"),
          ),
        ],
      ),
    );
  }
}
