class Responses {

  /* final bool response;
  final int codigo;
  final Object? datos;*/

  /*Responses({
    required this.response,
    required this.codigo,
    this.datos,
  });*/


  final bool rspt;
  final int codigo;
  final List? datos;

  late String mensaje;
  final Object? datos_O;



  Responses({required this.codigo,required this.rspt,required this.mensaje,this.datos,this.datos_O});

  factory Responses.fromMap(Map<String, dynamic> json) => Responses(
      codigo: json['codigo'],
      rspt: json['rspt'],
      mensaje: json['mensaje'],
      datos: json['datos'],
      datos_O: json['datos_O']
  );

  Map<String, dynamic> topMap() {
    return {
      'codigo': codigo,
      'rspt': rspt,
      'mensaje': mensaje,
      'datos': datos,
      'datos_O': datos_O,
    };
  }


/* String toString() {
    // TODO: implement toString
    return 'ResponseService => retorno: $retorno, rspt: $rspt, mensaje: $mensaje, objeto: ${objeto ?? ''}';
  }
*/



}