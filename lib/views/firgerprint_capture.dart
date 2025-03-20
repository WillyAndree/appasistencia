import 'package:flutter/material.dart';
import 'dart:async';

class FingerprintCaptureWidget extends StatefulWidget {
  final Future<String?> Function() captureFingerprint;
  final Future<void> Function(String) onFingerprintCaptured;

  const FingerprintCaptureWidget({
    Key? key,
    required this.captureFingerprint,
    required this.onFingerprintCaptured,
  }) : super(key: key);

  @override
  _FingerprintCaptureWidgetState createState() => _FingerprintCaptureWidgetState();
}

class _FingerprintCaptureWidgetState extends State<FingerprintCaptureWidget> {
  bool isCapturing = false;
  bool isProcessing = false;
  Timer? captureTimer;

  @override
  void initState() {
    super.initState();
    _startContinuousCapture();
  }

  void _startContinuousCapture() {
    captureTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (!isCapturing && !isProcessing) {
        setState(() {
          isCapturing = true;
        });
        await _captureFingerprint();
      }
    });
  }

  Future<void> _captureFingerprint() async {
    try {
      final fingerprintData = await widget.captureFingerprint();
      if (fingerprintData!.isNotEmpty) {
        setState(() {
          isProcessing = true;
        });
        await widget.onFingerprintCaptured(fingerprintData);
      }
    } finally {
      setState(() {
        isCapturing = false;
        isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    captureTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
        ],
      ),
    );
  }
}
