// Este archivo contiene la función para consumir una API y guardar usuarios en SQLite

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:appasistencia/model/bduser.dart';

class StudentFetcher {
  static Future<List> TransferStudent(BuildContext context, String apiUrl, String codigoalumno, String fingerprint) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Transfiriendo asistencias...'),
            ],
          ),
        );
      },
    );
    List data = [];
bool rpta = false;
String mensaje = "";
    try {
      print(fingerprint);
      final response = await http.post(Uri.parse(apiUrl), body: {'CODIGOALUMNO':codigoalumno, 'HUELLA_INDICE_DERECHO':fingerprint,'HUELLA_INDICE_IZQUIERDO':fingerprint});

      if (response.statusCode == 200) {
        final Map<String, dynamic> rptaJson = json.decode(response.body);

        print("RPTA2: $rptaJson");
        rpta = true;
        mensaje = "";


        data.add({
          "rpta":rpta,
          "mensaje":mensaje
        });
        Navigator.of(context).pop();
        return data;
      } else {
        rpta = false;

        mensaje = " *Error al transferir huellas de $codigoalumno";


        data.add({
          "rpta":rpta,
          "mensaje":mensaje
        });
        Navigator.of(context).pop();
        return data;
      }
    } catch (e) {
      rpta = false;
      mensaje = " *Error: $e - $codigoalumno";


      data.add({
        "rpta":rpta,
        "mensaje":mensaje
      });
      Navigator.of(context).pop();
      return data;
    }
  }
}
