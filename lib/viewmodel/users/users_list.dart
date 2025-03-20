// Este archivo contiene la función para consumir una API y guardar usuarios en SQLite

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:appasistencia/model/bduser.dart';

class UserFetcher {
  static Future<void> fetchAndStoreUsers(BuildContext context, String apiUrl) async {
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
              Text('Cargando usuarios...'),
            ],
          ),
        );
      },
    );

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> rptaJson = json.decode(response.body);
        List studentsJson = rptaJson["Alumnos"] ?? [];
        List usersJson = rptaJson["Usuarios"] ?? [];

        if (studentsJson.isEmpty) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron alumnos en la API.')),
          );
          return;
        }

        if (usersJson.isEmpty) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron usuarios en la API.')),
          );
          return;
        }

        await DatabaseHelper().deleteStudent();

        for (var studentJson in studentsJson) {
          await DatabaseHelper().insertStudentSync(
              studentJson['CODIGOALUMNO'],
              studentJson['APELLIDO_ALUMNO']+", "+studentJson['NOMBRE_ALUMNO'],
              studentJson['DNI_ALUMNO'],
              studentJson['TELEFONO01'] ?? "",
              studentJson['HUELLA_INDICE_DERECHO'] ?? "",
              studentJson['GRADO'],
              studentJson['SECCION']
          );
        }

        await DatabaseHelper().deleteUsers();

        for (var userJson in usersJson) {
          await DatabaseHelper().insertUsersSync(
              userJson['IDUSUARIO'],
              userJson['APELLIDOS']+", "+userJson['NOMBRES'],
              userJson['DNI'],
              userJson['LOGIN'] ?? "",
              userJson['PASSWORD'] ?? "",
              userJson['ESTADO']
          );
        }

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
