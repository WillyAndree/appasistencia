package com.willysandoval.appasistencia

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import SecuGen.FDxSDKPro.JSGFPLib
import SecuGen.FDxSDKPro.SGFDxDeviceName
import SecuGen.FDxSDKPro.SGFingerInfo
import SecuGen.FDxSDKPro.SGFDxErrorCode
import android.hardware.usb.UsbManager
import android.app.PendingIntent
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.util.Log
import SecuGen.FDxSDKPro.SGFDxSecurityLevel
import kotlin.text.map
import kotlin.text.split
import kotlin.text.toByte
import kotlin.text.toByteArray
import kotlin.text.toInt
import kotlin.text.trim

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "biometric_channel"
    private var isDeviceInitialized = false
    private lateinit var sgfplib: JSGFPLib
    private val ACTION_USB_PERMISSION = "com.willysandoval.appasistencia.USB_PERMISSION"

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_USB_PERMISSION) {
                synchronized(this) {
                    val device = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                    if (intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
                        if (device != null) {
                            Log.d("BiometricHelper", "Permiso concedido para dispositivo USB.")
                        } else {
                            Log.e("BiometricHelper", "Permiso no concedido.")
                        }
                    } else {
                        Log.d("BiometricHelper", "Permiso denegado para dispositivo USB.")
                    }
                }
            }
        }
    }


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val filter = IntentFilter(ACTION_USB_PERMISSION)
        registerReceiver(usbReceiver, filter, Context.RECEIVER_EXPORTED)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initDevice" -> {
                    val initMessage = initDevice()
                    result.success(initMessage)
                }
                "captureFingerprint" -> {
                    if (isDeviceInitialized) {
                        val fingerprintData = captureFingerprint()
                        result.success(fingerprintData)
                    } else {
                        result.error("DEVICE_NOT_INITIALIZED", "El dispositivo no ha sido inicializado.", null)
                    }
                }
                "matchFingerprint" -> {
                    val capturedTemplate = call.argument<String>("capturedTemplate")
                    val storedTemplate = call.argument<String>("storedTemplate")

                    if (capturedTemplate != null && storedTemplate != null && isDeviceInitialized) {
                        val isMatched = matchFingerprint(capturedTemplate, storedTemplate)
                        result.success(isMatched)
                    } else {
                        result.error("MATCH_ERROR", "Error al intentar comparar huellas.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initDevice(): String {
        try {
            val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
            sgfplib = JSGFPLib(this, usbManager)

            val error = sgfplib.Init(SGFDxDeviceName.SG_DEV_AUTO)
            if (error != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                return "Error al inicializar el dispositivo. Código de error: $error"
            }

            val usbDevice: UsbDevice? = sgfplib.GetUsbDevice()
            if (usbDevice == null) {
                return "No se encontró ningún dispositivo SecuGen conectado."
            }

            val hasPermission = usbManager.hasPermission(usbDevice)
            if (!hasPermission) {
                val mPermissionIntent = PendingIntent.getBroadcast(
                    this, 0, Intent(ACTION_USB_PERMISSION), PendingIntent.FLAG_IMMUTABLE
                )
                usbManager.requestPermission(usbDevice, mPermissionIntent)
                return "Solicitud de permisos enviada."
            }

            val openError = sgfplib.OpenDevice(0)
            if (openError == SGFDxErrorCode.SGFDX_ERROR_NONE) {
                isDeviceInitialized = true
                return "Dispositivo inicializado correctamente"
            } else {
                return "Error al abrir el dispositivo. Código de error: $openError"
            }
        } catch (e: Exception) {
            return "Error al inicializar el dispositivo: ${e.message}"
        }
    }

    private fun captureFingerprint(): String {
        if (!isDeviceInitialized) {
            return "Dispositivo no inicializado"
        }

        try {
            val buffer = ByteArray(2000 * 2000)
            val template = ByteArray(2048)

            // Crear una instancia de SGFingerInfo
            val fingerInfo = SGFingerInfo()
            fingerInfo.FingerNumber = 1
            fingerInfo.ImageQuality = 100 // Puedes ajustar esto según necesites
            fingerInfo.ImpressionType = 0
            fingerInfo.ViewNumber = 1

            val captureResult = sgfplib.GetImage(buffer)

            if (captureResult == SGFDxErrorCode.SGFDX_ERROR_NONE) {
                val createTemplateResult = sgfplib.CreateTemplate(fingerInfo, buffer, template)

                if (createTemplateResult == SGFDxErrorCode.SGFDX_ERROR_NONE) {
                    val fingerprintTemplateString = template.joinToString(",")
                    Log.d("BiometricHelper", "Plantilla generada correctamente")
                    return fingerprintTemplateString
                } else {
                    return "Error al crear plantilla de la huella. Código de error: $createTemplateResult"
                }
            } else {
                return "Error al capturar la huella. Código de error: $captureResult"
            }
        } catch (e: Exception) {
            return "Error al capturar la huella: ${e.message}"
        }
    }






    private fun matchFingerprint(capturedTemplate: String, storedTemplate: String): Boolean {
        if (!isDeviceInitialized) {
            return false
        }

        try {
            // Convertimos la plantilla de String a ByteArray correctamente
            val capturedTemplateBytes = capturedTemplate.split(",").map { it.trim().toInt() }.map { it.toByte() }.toByteArray()
            val storedTemplateBytes = storedTemplate.split(",").map { it.trim().toInt() }.map { it.toByte() }.toByteArray()

            // Array para guardar el resultado de la comparación
            val matchScore = BooleanArray(1)

            // Realizamos la comparación utilizando la función del SDK
            val matchResult = sgfplib.MatchTemplate(
                capturedTemplateBytes,
                storedTemplateBytes,
                SGFDxSecurityLevel.SL_NORMAL,
                matchScore
            )

            if (matchResult == SGFDxErrorCode.SGFDX_ERROR_NONE) {
                Log.d("BiometricHelper", "Comparación completada con éxito. ¿Coinciden?: ${matchScore[0]}")
                return matchScore[0]  // Devuelve true si hay coincidencia
            } else {
                Log.e("BiometricHelper", "Error en la comparación. Código de error: $matchResult")
                return false
            }
        } catch (e: java.lang.Exception) {
            Log.e("BiometricHelper", "Error al comparar las huellas: ${e.message}")
            return false
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(usbReceiver)
        if (isDeviceInitialized) {
            sgfplib.CloseDevice()
            sgfplib.Close()
        }
    }
}
