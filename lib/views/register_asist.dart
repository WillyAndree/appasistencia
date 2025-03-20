import 'package:appasistencia/model/biometric_helper.dart';
import 'package:appasistencia/viewmodel/asistencias/asistencias_transfer.dart';
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import '../model/bduser.dart';

class RegistroAsistencias extends StatefulWidget {
  @override
  _RegistroAsistenciasState createState() => _RegistroAsistenciasState();
}

class _RegistroAsistenciasState extends State<RegistroAsistencias> {
   List<Map<String, dynamic>> asistencias = [
  ];
   final Telephony telephony = Telephony.instance;

  Future<void>ListAsist() async{

     asistencias = await DatabaseHelper.getAsistencias();
     setState(() {
       print(asistencias);
     });

  }

  Future<void> _refreshList() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      ListAsist();
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ListAsist();
  }

   Future<bool> _enviarMensaje(String id,String tipo, String cel, String nombre_capturado,_horaRegistro ) async {
     String numeroApoderado = cel; // Reemplaza con el número real del apoderado
     String mensaje = 'El estudiante $nombre_capturado ha registrado su asistencia a las $_horaRegistro, lo cual se considera $tipo';

     try {
       await telephony.sendSms(
         to: numeroApoderado,
         message: mensaje,
       );
       await DatabaseHelper().uodateMessageState(
           id,'1'
           );

       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Mensaje enviado al apoderado')),
       );
       return true;
     } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error al enviar mensaje: $e')),
       );
       return false;
     }
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Text('Registro de Asistencias'),
        actions: [
          IconButton(
            icon: Icon(Icons.send_and_archive_sharp),
            onPressed: () async{
              final now = DateTime.now();
              String _estado_registro = "";
              final limite = DateTime(now.year, now.month, now.day, 07, 50);
              final ingreso = DateTime(now.year, now.month, now.day, 07, 00);
              final limite_ingreso = DateTime(now.year, now.month, now.day, 10, 00);
              final salida = DateTime(now.year, now.month, now.day, 15, 30);

              for(int i = 0; i <asistencias.length; i++){
                if(asistencias[i]["mensaje_enviado"] == "0"){
                  print("DATA: "+DateTime.parse(asistencias[i]["fecha"]+' '+asistencias[i]["hora"]).toString());
                  if (DateTime.parse(asistencias[i]["fecha"]+' '+asistencias[i]["hora"]).isAfter(limite) && DateTime.parse(asistencias[i]["fecha"]+' '+asistencias[i]["hora"]).isBefore(limite_ingreso)) {
                    setState(() {
                      _estado_registro = "TARDANZA";
                    });
                    if(asistencias[i]["celular"] != ''){
                      await _enviarMensaje(asistencias[i]["id"],_estado_registro, asistencias[i]["celular"], asistencias[i]["name"], asistencias[i]["hora"]);
                    }


                  }else if(DateTime.parse(asistencias[i]["fecha"]+' '+asistencias[i]["hora"]).isAfter(limite_ingreso) && DateTime.parse(asistencias[i]["fecha"]+' '+asistencias[i]["hora"]).isBefore(salida)){
                    setState(() {
                      _estado_registro = "SALIDA ANTICIPADA";
                    });
                    if(asistencias[i]["celular"] != ''){
                      await _enviarMensaje(asistencias[i]["id"],_estado_registro, asistencias[i]["celular"], asistencias[i]["name"], asistencias[i]["hora"]);
                    }
                  }
                }
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () {
              // Acción de sincronización
            },
          ),
          IconButton(
            icon: Icon(Icons.upload),
            onPressed: () async{
              List asist = await DatabaseHelper.getAsistenciasTransf();
              for(int i = 0; i < asist.length; i++){

                AsistFetcher.TransferAsist(context, "https://colegiojorgebasadre.quipukey.pe/index.php/datosmovil/setAsistenciaHuellaAlumno",
                    asist[i]['codigoalumno'],  asist[i]['fingerprint'].toString(), asist[i]['fecha'], asist[i]['hora'], asist[i]['tipo'], asist[i]['fecharegistro'], asist[i]['idusuario']);

                DatabaseHelper().updateEstadoState(asist[i]['codigoalumno'], '1');
              }

            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshList,
        child: ListView.builder(
          itemCount: asistencias.length,
          itemBuilder: (context, index) {
            final asistencia = asistencias[index];
            return ListTile(
              leading: Icon(asistencia['celular'] == '' ? Icons.phone_disabled: Icons.phone ,color: asistencia['celular'] == '' ? Colors.red: Colors.blue ),
              title: Text(asistencia['name']!),
              subtitle: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(asistencia['fecha']!+' '+asistencia['hora']!),
                //SizedBox(height: 5,),
                Text("Mensaje enviado: ${asistencia['mensaje_enviado'] == '0' ? 'NO': 'SI'}"),
                  Divider(thickness: 2,color: Colors.black,)
              ],),

            );
          },
        ),
      ),
    );
  }
}
