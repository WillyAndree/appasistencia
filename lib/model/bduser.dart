import 'dart:math';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'faces.db');

    return openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute("""
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            dni TEXT,
            celular TEXT,
            features TEXT,
            fingerprint TEXT
          )
        """);
      },
      version: 1,
    );
  }

  static Future<void> insertUser(String name,String dni, String celular, List<double> features,String fingerprintData) async {
    final db = await initDB();
    await db.insert('users', {
      'name': name,
      'dni':dni,
      'celular':celular,
      'fingerprint':fingerprintData,
      'features': features.join(','), // Guardar como String
    });
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await initDB();
    return db.query('users');
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
    final users = await db.query('users');

    List rpta = [];
    String identifiedName = "";
    String identifiedCel= "";

    for (int i = 0; i< users.length; i++) {

      if(users[i]["dni"] == dni){
        identifiedName = users[i]['name'].toString();
        identifiedCel = users[i]['celular'].toString();
        rpta.add({"DNI":dni, "NOMBRES": identifiedName, "CELULAR": identifiedCel});
      }

    }


    return rpta; // Umbral de similitud
  }
}
