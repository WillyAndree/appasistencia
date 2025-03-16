class UserFace {
  final int id;
  final String name;
  final String dni;
  final String celular;
  final List<double> features; // Características faciales extraídas

  UserFace({required this.id, required this.name, required this.features, required this.dni, required this.celular});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dni': dni,
      'celular': celular,
      'features': features.join(','), // Guardar como String
    };
  }

  static UserFace fromMap(Map<String, dynamic> map) {
    return UserFace(
      id: map['id'],
      name: map['name'],
      dni: map['dni'],
      celular: map['celular'],
      features: map['features'].split(',').map((e) => double.parse(e)).toList(),
    );
  }
}
