import 'package:flutter/services.dart';

class BiometricHelper {
  static const MethodChannel _channel = MethodChannel('biometric_channel');

  static Future<String> initDevice() async {
    try {
      final String result = await _channel.invokeMethod('initDevice');
      return result;
    } catch (e) {
      print("Error al inicializar el dispositivo: $e");
      return "Error al inicializar el dispositivo: $e";
    }
  }



  static bool _isProcessing = false;

  static Future<String?> captureFingerprint() async {
    if (_isProcessing) return null;

    _isProcessing = true;
    try {
      final String? fingerprintData = await _channel.invokeMethod('captureFingerprint');
      return fingerprintData;
    } catch (e) {
      print("Error al capturar la huella: $e");
      return null;
    } finally {
      _isProcessing = false;
    }
  }


  static Future<bool> matchFingerprint(String capturedTemplate, String storedTemplate) async {
    try {
      final bool result = await _channel.invokeMethod('matchFingerprint', {
        'capturedTemplate': capturedTemplate,
        'storedTemplate': storedTemplate,
      });
      return result;
    } catch (e) {
      print("Error al comparar las huellas: $e");
      return false;
    }
  }
}
