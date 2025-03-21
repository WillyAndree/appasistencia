import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'biometric_helper.dart';

class DatabaseHelper {
  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'faces.db');

    return openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute("""
          CREATE TABLE students(
            id VARCHAR(50) PRIMARY KEY,
            name TEXT,
            dni VARCHAR(8),
            celular TEXT,
            features TEXT,
            fingerprint BLOB,
            grado TEXT,
            seccion TEXT,
            transferido CHAR(1) DEFAULT '0'
          )
        """);
        await db.execute("""
          CREATE TABLE users(
            id INT PRIMARY KEY,
            name TEXT,
            dni VARCHAR(8),
            login TEXT,
            password TEXT,
            estado CHAR(1)
          )
        """);
        await db.execute('''
  CREATE TABLE asistencia (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    idstudent TEXT,
    fecha TEXT,
    hora TEXT,
    tipo TEXT,
    fecharegistro TEXT DEFAULT (DATETIME('now', 'localtime')),
    idusuario TEXT,
    mensaje_enviado TEXT,
    transferido TEXT DEFAULT '0'
  )
''');
      },
      version: 1,
    );
  }

  Future<void> updateUser( String dni,String fingerprintData) async {
    final db = await initDB();

    // Dividir el string en una lista de strings
    final stringBytes = fingerprintData.split(",");

    // Crear una lista de bytes
    final List<int> byteList = [];

    for (final stringByte in stringBytes) {
      // Eliminar espacios en blanco
      final trimmedStringByte = stringByte.trim();

      // Intentar convertir el string a un entero
      final int? byteValue = int.tryParse(trimmedStringByte);

      // Verificar si la conversión fue exitosa
      if (byteValue == null) {
        // Manejar el error: no se pudo convertir el string a un entero
        print("Error: No se pudo convertir '$trimmedStringByte' a un entero.");
        return; // O lanzar una excepción, dependiendo de cómo quieras manejar el error
      }

      // Verificar si el valor está en el rango de un byte (-128 a 127)
      if (byteValue < -128 || byteValue > 127) {
        // Manejar el error: el valor está fuera del rango de un byte
        print("Error: El valor '$byteValue' está fuera del rango de un byte.");
        return; // O lanzar una excepción, dependiendo de cómo quieras manejar el error
      }

      // Agregar el valor a la lista de bytes
      byteList.add(byteValue);
    }
    // Verificar el tamaño del template
    if (byteList.length != 2048) {
      // Manejar el error: el tamaño del template no es el correcto
      print("Error: El tamaño del template no es el correcto.");
      return; // O lanzar una excepción, dependiendo de cómo quieras manejar el error
    }

    // Convertir la lista de bytes a un Uint8List
    final fingerprintBlob = Uint8List.fromList(byteList);

    await db.update('students', {

      'fingerprint': fingerprintBlob,
    }, where: 'dni = ?', whereArgs: [dni]);
  }
  Future<void> insertUser(String name, String dni, String celular, List<double>? faceFeatures, String fingerprintData, String grado) async {
    final db = await initDB();

    // Dividir el string en una lista de strings
    final stringBytes = fingerprintData.split(",");

    // Crear una lista de bytes
    final List<int> byteList = [];

    for (final stringByte in stringBytes) {
      // Eliminar espacios en blanco
      final trimmedStringByte = stringByte.trim();

      // Intentar convertir el string a un entero
      final int? byteValue = int.tryParse(trimmedStringByte);

      // Verificar si la conversión fue exitosa
      if (byteValue == null) {
        // Manejar el error: no se pudo convertir el string a un entero
        print("Error: No se pudo convertir '$trimmedStringByte' a un entero.");
        return; // O lanzar una excepción, dependiendo de cómo quieras manejar el error
      }

      // Verificar si el valor está en el rango de un byte (-128 a 127)
      if (byteValue < -128 || byteValue > 127) {
        // Manejar el error: el valor está fuera del rango de un byte
        print("Error: El valor '$byteValue' está fuera del rango de un byte.");
        return; // O lanzar una excepción, dependiendo de cómo quieras manejar el error
      }

      // Agregar el valor a la lista de bytes
      byteList.add(byteValue);
    }
    // Verificar el tamaño del template
    if (byteList.length != 2048) {
      // Manejar el error: el tamaño del template no es el correcto
      print("Error: El tamaño del template no es el correcto.");
      return; // O lanzar una excepción, dependiendo de cómo quieras manejar el error
    }

    // Convertir la lista de bytes a un Uint8List
    final fingerprintBlob = Uint8List.fromList(byteList);

    await db.insert('users', {
      'name': name,
      'dni': dni,
      'celular': celular,
      'fingerprint': fingerprintBlob,
      'grado': grado,
    });
  }

  Future<void> insertStudentSync(String id,String name, String dni, String celular, String fingerprintData, String grado, String seccion, String transferido) async {
    final db = await initDB();

    if(fingerprintData.contains(",")){
      final stringBytes = fingerprintData.replaceAll("[", "").replaceAll("]", "").split(",");

      // Crear una lista de bytes
      final List<int> byteList = [];

      for (final stringByte in stringBytes) {
        // Eliminar espacios en blanco
        final trimmedStringByte = stringByte.trim();

        // Intentar convertir el string a un entero
        final int? byteValue = int.tryParse(trimmedStringByte);

        // Verificar si la conversión fue exitosa
        if (byteValue == null) {
          // Manejar el error: no se pudo convertir el string a un entero
          print("Error: No se pudo convertir '$trimmedStringByte' a un entero.");
          return; // O lanzar una excepción, dependiendo de cómo quieras manejar el error
        }

        // Verificar si el valor está en el rango de un byte (-128 a 127)
        /*if (byteValue < -128 || byteValue > 260) {
          // Manejar el error: el valor está fuera del rango de un byte
          print("Error: El valor '$byteValue' está fuera del rango de un byte.");
          return; // O lanzar una excepción, dependiendo de cómo quieras manejar el error
        }*/

        // Agregar el valor a la lista de bytes
        byteList.add(byteValue);
      }
      // Verificar el tamaño del template
      if (byteList.length != 2048) {
        // Manejar el error: el tamaño del template no es el correcto
        print("Error: El tamaño del template no es el correcto.");
        return; // O lanzar una excepción, dependiendo de cómo quieras manejar el error
      }

      // Convertir la lista de bytes a un Uint8List
      final fingerprintBlob = Uint8List.fromList(byteList);
      await db.insert('students', {
        'id': id,
        'name': name,
        'dni': dni,
        'celular': celular,
        'fingerprint': fingerprintBlob,
        'grado': grado,
        'seccion': seccion,
        'transferido':transferido
      });
    }else{
      await db.insert('students', {
        'id': id,
        'name': name,
        'dni': dni,
        'celular': celular,
        'fingerprint': fingerprintData,
        'grado': grado,
        'seccion': seccion,
        'transferido':transferido
      });
    }


  }

  Future<void> uodateMessageState(String id,String estado) async {
    final db = await initDB();

    await db.update('asistencia', {
      'mensaje_enviado':estado
    }, where: 'id', whereArgs: [id]);
  }

  Future<void> updateEstadoState(int id,String estado) async {
    final db = await initDB();

    await db.update('asistencia', {
      'transferido':estado
    }, where: 'id = ? ', whereArgs: [id]);
  }
  Future<void> updateEstadoStudents(String id,String estado) async {
    final db = await initDB();

    await db.update('students', {
      'transferido':estado
    }, where: 'id = ? ', whereArgs: [id]);
  }

  Future<void> deleteStudent() async {
    final db = await initDB();

    await db.delete('students',where: 'transferido = 1');
  }

  Future<void> deleteUsers() async {
    final db = await initDB();

    await db.delete('users');
  }

  Future<void> insertAsist(String idstudent,String fecha, String hora, String tipo, String idusuario, String mensaje_enviado) async {
    final db = await initDB();

    await db.insert('asistencia', {
      'idstudent': idstudent,
      'fecha': fecha,
      'hora': hora,
      'tipo': tipo,
      'idusuario': idusuario,
      'mensaje_enviado':mensaje_enviado
    });
  }

  Future<void> insertUsersSync(String id,String name, String dni, String login, String password, String estado) async {
    final db = await initDB();

    await db.insert('users', {
      'id': id,
      'name': name,
      'dni': dni,
      'login': login,
      'password': password,
      'estado': estado,
    });
  }


  static Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await initDB();
    return db.query('students',where: 'fingerprint != "" ');
  }

  static Future<List<Map<String, dynamic>>> getAsistencias() async {
    final db = await initDB();
    final now = DateTime.now();
    String fecha = DateFormat('yyyy-MM-dd').format(now);
    return db.rawQuery(" select a.id,s.name, a.fecha as fecha, a.hora, s.celular, a.mensaje_enviado from asistencia a inner join students s on (a.idstudent = s.id) where a.fecha = ?   ", [fecha]);
  }

  static Future<List<Map<String, dynamic>>> getSinAsistencias() async {
    final db = await initDB();
    final now = DateTime.now();
    String fecha = DateFormat('yyyy-MM-dd').format(now);
    return db.rawQuery(" select s.id,s.name, s.celular from  students s  where s.id not in (select idstudent from asistencia where fecha = ?)   ", [fecha]);
  }

  static Future<List<Map<String, dynamic>>> getAsistenciasTransf() async {
    final db = await initDB();
    final now = DateTime.now();
    String fecha = DateFormat('yyyy-MM-dd').format(now);
    return db.rawQuery("select a.id,s.id as codigoalumno ,s.fingerprint, a.fecha, a.hora, a.tipo, a.fecharegistro, u.id as idusuario from asistencia a inner join students s on (a.idstudent = s.id) inner join users u on (u.id = a.idusuario) where a.transferido = '0' ");
  }

  static Future<List<Map<String, dynamic>>> getHuellasTransf() async {
    final db = await initDB();
    final now = DateTime.now();
    String fecha = DateFormat('yyyy-MM-dd').format(now);
    return db.rawQuery(" select s.id as codigoalumno ,s.fingerprint from  students s  where s.transferido = '0' ");
  }


  double cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0, normA = 0, normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

   Future<String?> identifyUser(List<double> detectedFeatures) async {
    final db = await initDB();
    final users = await db.query('users');

    String? identifiedName;
    double maxSimilarity = -1.0; // Se busca la mayor similitud

    for (var user in users) {
      List<double> storedFeatures = user['features']
          .toString()
          .split(',')
          .map((e) => double.tryParse(e) ?? 0.0) // Evita errores con valores nulos
          .toList();

      double similarity = cosineSimilarity(storedFeatures, detectedFeatures);

      if (similarity > maxSimilarity) {
        maxSimilarity = similarity;
        identifiedName = user['name'] as String?;
      }
    }

    return (maxSimilarity > 0.8) ? identifiedName : null; // Umbral de similitud
  }

  Future<List?> identifyUserDni(String dni) async {
    final db = await initDB();
    final users = await db.query('students');

    List rpta = [];
    String identifiedName = "";
    String identifiedCel= "";
    String identifiedGrado= "";
    String identifiedSeccion= "";

    for (int i = 0; i< users.length; i++) {

      if(users[i]["dni"] == dni){
        identifiedName = users[i]['name'].toString();
        identifiedCel = users[i]['celular'].toString();
        identifiedGrado = users[i]['grado'].toString();
        identifiedSeccion = users[i]['seccion'].toString();
        rpta.add({"DNI":dni, "NOMBRES": identifiedName, "CELULAR": identifiedCel, "GRADO": identifiedGrado, "SECCION": identifiedSeccion});
      }

    }


    return rpta; // Umbral de similitud
  }

  Future<Map<String, dynamic>?> buscarUsuarioPorDNI(String dni) async {
    final db = await initDB();

    final List<Map<String, dynamic>> result = await db.query(
      'students',          // Nombre de la tabla
      where: 'dni = ?',  // Condición de búsqueda
      whereArgs: [dni],  // Argumentos para evitar inyección SQL
    );


    if (result.isNotEmpty) {
      return result.first; // Devuelve el primer resultado encontrado
    } else {
      return null; // Si no encuentra nada, retorna null
    }
  }

  Future<Map<String, dynamic>?> buscarUsuarioLogin(String login, String password) async {
    final db = await initDB();

    final List<Map<String, dynamic>> result = await db.query(
      'users',          // Nombre de la tabla
      where: 'login = ? and password = ?',  // Condición de búsqueda
      whereArgs: [login, password],  // Argumentos para evitar inyección SQL
    );


    if (result.isNotEmpty) {
      return result.first; // Devuelve el primer resultado encontrado
    } else {
      return null; // Si no encuentra nada, retorna null
    }
  }

  Future<List?> identifyUserFinger(String fingerprintData) async {
    final db = await initDB();
    final users = await db.query('users');

    List rpta = [];
    final capturedFingerprint = Uint8List.fromList(fingerprintData.split(",").map((e) => int.parse(e)).toList());

    for (var user in users) {
      final storedFingerprint = user['fingerprint'] as Uint8List;

      if (storedFingerprint != null && capturedFingerprint != null) {
        if (await BiometricHelper.matchFingerprint(
          capturedFingerprint.toString(),
          storedFingerprint.toString(),
        )) {
          rpta.add({
            "DNI": user['dni'],
            "NOMBRES": user['name'],
            "CELULAR": user['celular'],
          });
        }
      }
    }

    return rpta;
  }
}
