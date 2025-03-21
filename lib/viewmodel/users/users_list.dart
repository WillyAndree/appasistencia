// Este archivo contiene la función para consumir una API y guardar usuarios en SQLite

import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:appasistencia/model/bduser.dart';
import 'package:sqflite/sqflite.dart';
import 'package:convert/convert.dart';
import 'dart:typed_data';

class UserFetcher {

  String convertIntListToHexString(String input) {
    //if (input is List<dynamic>) {
      List<String> dataStringList = input.replaceAll("[", "").replaceAll("]", "").replaceAll(" ", "").split(",");
      // Convertimos cada elemento al tipo int si es necesario
      List<int> data = dataStringList.map(int.parse).toList();

      // Convertimos la lista de enteros a un string hexadecimal
      return hex.encode(data).toUpperCase();
   /* } else if (input is String) {
      // Si ya es un string, lo retornamos tal cual
      return input;
    } else {
      throw ArgumentError("El dato proporcionado no es una lista de enteros ni un string.");
    }*/
  }

   Future<void> fetchAndStoreUsers(BuildContext context, String apiUrl) async {
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

        if (studentsJson.isEmpty && usersJson.isEmpty) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron usuarios o alumnos en la API.')),
          );
          return;
        }

        if(studentsJson.isNotEmpty){
          await DatabaseHelper().deleteStudent();
        }

        if(usersJson.isNotEmpty){
          await DatabaseHelper().deleteUsers();
        }


        int insertedStudents = 0;
        int duplicatedStudents = 0;


        for (var studentJson in studentsJson) {
          try {
           /* String huella;

            if((studentJson['HUELLA_INDICE_DERECHO'].toString() != "null" || studentJson['HUELLA_INDICE_DERECHO'] != null) || studentJson['HUELLA_INDICE_DERECHO'] != "0" ){
              List<String> dataStringList = studentJson['HUELLA_INDICE_DERECHO'].toString()
                  .replaceAll("[", "")
                  .replaceAll(" ", "")
                  .replaceAll("]", "")
                  .split(",");

              List<int> data = dataStringList.map(int.parse).toList();
               huella = base64Encode(data);
            }else{
              huella = studentJson['HUELLA_INDICE_DERECHO'];
            }*/


            await DatabaseHelper().insertStudentSync(
              studentJson['CODIGOALUMNO'],
              studentJson['APELLIDO_ALUMNO'] + ", " + studentJson['NOMBRE_ALUMNO'],
              studentJson['DNI_ALUMNO'],
              studentJson['TELEFONO01'] ?? "",
              studentJson['HUELLA_INDICE_DERECHO'] ?? '',
              studentJson['GRADO'],
              studentJson['SECCION'],
              "1",
            );
            insertedStudents++;
          } catch (e) {
            print(e);
            if (e is DatabaseException && e.isUniqueConstraintError()) {
              duplicatedStudents++;
            } else {
              rethrow; // Si el error es diferente, se lanza nuevamente
            }

          }
        }

        int insertedUsers = 0;
        int duplicatedUsers = 0;

        for (var userJson in usersJson) {
          try {
            await DatabaseHelper().insertUsersSync(
              userJson['IDUSUARIO'],
              userJson['APELLIDOS'] + ", " + userJson['NOMBRES'],
              userJson['DNI'],
              userJson['LOGIN'] ?? "",
              userJson['PASSWORD'] ?? "",
              userJson['ESTADO'],
            );
            insertedUsers++;
          } catch (e) {
            if (e is DatabaseException && e.isUniqueConstraintError()) {
              duplicatedUsers++;
            } else {
              rethrow;
            }
          }
        }

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuarios registrados correctamente en SQLite. '
              'Nuevos Alumnos: $insertedStudents, Duplicados: $duplicatedStudents. '
              'Nuevos Usuarios: $insertedUsers, Duplicados: $duplicatedUsers.')),
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
