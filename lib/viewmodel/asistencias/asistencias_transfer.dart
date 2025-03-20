// Este archivo contiene la función para consumir una API y guardar usuarios en SQLite

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:appasistencia/model/bduser.dart';

class AsistFetcher {
  static Future<void> TransferAsist(BuildContext context, String apiUrl, String codigoalumno, String fingerprint, String fecha, String hora, String tipo, String fecharegistro, String idusuario) async {
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

    try {
      final response = await http.post(Uri.parse(apiUrl), body: {'CODIGOALUMNO':codigoalumno, 'HUELLA_INDICE_DERECHO':fingerprint,'HUELLA_INDICE_IZQUIERDO':fingerprint,'FECHA': fecha, 'HORA': hora, 'TIPO': tipo, 'FECHAREGISTRO': fecharegistro, 'IDUSUARIO': idusuario });

      if (response.statusCode == 200) {
        final Map<String, dynamic> rptaJson = json.decode(response.body);

        print(rptaJson);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuarios registrados correctamente en SQLite.')),
        );
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al obtener usuarios desde la API.')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
