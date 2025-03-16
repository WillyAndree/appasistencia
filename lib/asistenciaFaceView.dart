import 'package:appasistencia/registerUserFacial.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'model/bduser.dart'; // Importar nuestra base de datos

class FaceRecognitionScreen extends StatefulWidget {
  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool isDetecting = false;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );
  late Interpreter _interpreter;

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  Future<void> initCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[1], ResolutionPreset.medium);
    await _cameraController!.initialize();
    if (mounted) setState(() {});

    _startFaceDetection();
  }

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
  }

  void _startFaceDetection() {
    _cameraController!.startImageStream((CameraImage image) async {
      if (isDetecting) return;
      isDetecting = true;

      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final InputImage inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        print("✅ Rostro detectado");
        _compareFace(faces.first, inputImage);
      }

      isDetecting = false;
    });
  }

  Future<void> _compareFace(Face face, InputImage inputImage) async {
    List<double> faceEmbedding = await _getFaceEmbedding(inputImage);

    // 📌 🔥 Comparar con la base de datos
    String? identifiedUser = await DatabaseHelper().identifyUser(faceEmbedding);

    if (identifiedUser != null) {
      print("🟢 Usuario identificado: $identifiedUser");
    } else {
      print("🔴 Usuario no registrado");
    }
  }

  Future<List<double>> _getFaceEmbedding(InputImage image) async {
    // 🔥 Aquí iría la extracción de embeddings con TFLite (Simulación)
    List<double> embedding = List.filled(128, 0);
    return embedding;
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reconocimiento Facial"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cerrar"))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Registrar Asistencia"),
        actions: [
          IconButton(onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FaceRegistrationScreen()),
            );
          }, icon: Icon(Icons.person))
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          Center(
            child: CustomPaint(
              size: Size(300, 400),
              painter: FaceFramePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class FaceFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 200,
      height: 250,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(20)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
