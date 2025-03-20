
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../constants.dart';
import 'colorsLB.dart';

class Dialogs{
  static const int success = 1;
  static const int error = 2;
  static const int warning = 3;
  static const int info = 4;
  static const int question = 5;

  static Widget? getIcon({required int icons}){
    Widget? icon;

    switch(icons){
      case 1:
        icon = const Icon(Icons.check_circle_outline_sharp,color: ColorsAcp.colorPrimaryVerdeOscuroLB,size: 50,);
        break;
      case 2:
        icon = const Icon(Icons.cancel_outlined,color: ColorsAcp.colorPrimaryRojo,size: 50,);
        break;
      case 3:
        icon = const Icon(Icons.error_outline_sharp,color: ColorsAcp.colorComplementaryAmarilloNaranja,size: 50,);
        break;
      case 4:
        icon = const Icon(Icons.info_outlined,color: ColorsAcp.colorComplementaryVerdeAzul,size: 50,);
        break;
      case 5:
        icon = const Icon(Icons.help_outline_sharp,color: ColorsAcp.colorComplementaryPlomo,size: 50,);
        break;
      default:
        icon = null;
    }

    return icon;
  }

  static Widget? getTitle({required int icons}){
    String? titleS;
    Widget? titleW;

    switch(icons){
      case 1:
        titleS = "Éxito";
        break;
      case 2:
        titleS = "Error";
        break;
      case 3:
        titleS = "Advertencia";
        break;
      case 4:
        titleS = "Información";
        break;
      case 5:
        titleS = "Pregunta";
        break;
      default:
        titleS = null;
    }

    if(titleS != null){
      titleW = ListTile(
        contentPadding: EdgeInsets.zero,
        horizontalTitleGap: 0.0,
        visualDensity: const VisualDensity(vertical: -4),
        dense: true,
        title: Text(
          titleS,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: ColorsAcp.colorPrimaryNegro,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return titleW;
  }


  static showMessageGeneralSweeralertgcp({required BuildContext context,int? icon,required List<Widget> content,List<Widget>? actions,Color? backgroundColor,MainAxisAlignment? actionsAlignment,Color? barrierColor,StateSetter? state,required bool paddingdefault}){
    Color barrierColorAux = ColorsAcp.colorPrimaryNegro.withOpacity(0.6);
    Widget? icons = getIcon(icons: icon??-1);
    Widget? title = getTitle(icons: icon??-1);
    List<Widget> contenido = paddingdefault
        ? [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: content,
        ),
      )
    ]
        :content;
    return showMessageGeneral(
      context: context,
      state: state,
      barrierColor: barrierColor??barrierColorAux,
      title: title,
      icon: icons,
      content: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: contenido,
          ),
        )
      ],
      actions: actions,
      actionsAlignment: actionsAlignment,
      backgroundColor: backgroundColor,
    );
  }

  static showMessageGeneralCerrarCesion({required BuildContext context}){
    return showMessageGeneral(context: context,
        barrierColor: ColorsAcp.colorPrimaryNegro.withOpacity(0.6),
        icon: const Icon(Icons.door_back_door_sharp),
        title: const Text("Cerrar Sesión"),
        content: [
          const Text("¿Dese cerrar la sesión Actual?")
        ],
        actions: [
          TextButton(
              onPressed: (){
                Navigator.pop(context);
              },
              child: const Text("No")
          ),
          TextButton(
              onPressed: (){
                /*Global.usuario = null;
              Global.fotoColaborador = "";
              Global.cerrarSesion(context);*/
              },
              child: const Text("Si")
          )
        ]
    );
  }

  static showMessageGeneralNoRegistrado({required BuildContext context, required dni}){
    return showMessageGeneral(context: context,
        barrierColor: ColorsAcp.colorPrimaryNegro.withOpacity(0.6),
        icon: const Icon(Icons.cancel),
        title: const Text("PERSONAL NO REGISTRADO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
        content: [
          Container( padding: const EdgeInsets.all(20), child : Text("¿Dese registrar el dni $dni?", style: TextStyle(fontSize: 16)))
        ],
        actions: [
          TextButton(
              onPressed: (){
                Navigator.pop(context, "No");
              },
              child: const Text("No")
          ),
          TextButton(
              onPressed: (){
                Navigator.pop(context, "Si");
              },
              child: const Text("Si")
          )
        ]
    );
  }

  static showMessageGeneralDelete({required BuildContext context}){
    return showMessageGeneral(context: context,
        barrierColor: ColorsAcp.colorPrimaryNegro.withOpacity(0.6),
        icon: const Icon(Icons.door_back_door_sharp),
        title: const Text("Cerrar Sesión"),
        content: [
          const Text("¿Dese cerrar la sesión Actual?")
        ],
        actions: [
          TextButton(
              onPressed: (){
                Navigator.pop(context);
              },
              child: const Text("No")
          ),
          TextButton(
              onPressed: (){
                /*Global.usuario = null;
              Global.fotoColaborador = "";
              Global.cerrarSesion(context);*/
              },
              child: const Text("Si")
          )
        ]
    );
  }

  static showMessageGeneralCargando({required BuildContext context,required List<Widget> content,Color? barrierColor,StateSetter? state}) {
    var sizeHeight = 120.0;
    List<Widget> contenidoFijo = [
      const SizedBox(
        child: CircularProgressIndicator(),
      ),
      const SizedBox(
        height: 5,
      )
    ];
    contenidoFijo.addAll(content);

    return showMessageGeneral(
        context: context,
        barrierColor: barrierColor,
        state: state,
        content: [
          Container(
            color: ColorsAcp.colorPrimaryBlancoLB,
            height: sizeHeight,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: contenidoFijo,
            ),
          )
        ]
    );
  }

  static showMessageGeneral({required BuildContext context,Widget? title,Widget? icon,required List<Widget> content,List<Widget>? actions,Color? backgroundColor,MainAxisAlignment? actionsAlignment,Color? barrierColor,StateSetter? state}) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: barrierColor,
        // barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return WillPopScope(
                  onWillPop: () async => false,
                  child: AlertDialog(
                    backgroundColor: backgroundColor,
                    title: title,
                    icon: icon,
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: content,
                      ),
                    ),
                    actions: actions,
                    actionsPadding: const EdgeInsets.only(top: 0.0,bottom: 0.0,left: 5.0,right: 5.0),
                    buttonPadding: const EdgeInsets.only(top: 0.0,bottom: 0.0,left: 5.0,right: 5.0),
                    titlePadding: const EdgeInsets.only(top: 2.0,bottom: 2.0,left: 5.0,right: 5.0),
                    contentPadding: const EdgeInsets.only(top: 5.0,bottom: 5.0,left: 5.0,right: 5.0),
                    actionsAlignment: actionsAlignment,
                  ),
                );
              },
            ),
          );
        }
    );
  }


  static ShowDialogListaDefectos({required BuildContext context,int? icon,required List<Widget> content,List<Widget>? actions,Color? backgroundColor,MainAxisAlignment? actionsAlignment,Color? barrierColor,StateSetter? state,required bool paddingdefault}){
    Color barrierColorAux = ColorsAcp.colorPrimaryNegro.withOpacity(0.6);
    Widget? icons = getIcon(icons: icon??-1);
    Widget? title = getTitle(icons: icon??-1);
    List<Widget> contenido = paddingdefault
        ? [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: content,
        ),
      )
    ]
        :content;
    return showMessageGeneral(
      context: context,
      state: state,
      barrierColor: barrierColor??barrierColorAux,
      title: Text("CRITERIO/S"),

      // icon: icons,
      content: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: contenido,
          ),
        )
      ],
      actions:   [
        TextButton(
            onPressed: (){
              Navigator.pop(context);
            },
            child: const Text("CANCELAR")
        ),
        TextButton(
            onPressed: (){
              /*Global.usuario = null;
                    Global.fotoColaborador = "";
                    Global.cerrarSesion(context);*/
            },
            child: const Text("ACEPTAR")
        )
      ],
      actionsAlignment: actionsAlignment,
      backgroundColor: backgroundColor,
    );
  }


}