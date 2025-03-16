package com.willysandoval.appasistencia

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import SecuGen.FDxSDKPro.JSGFPLib
import SecuGen.FDxSDKPro.SGFDxDeviceName
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
                        }else{
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
        registerReceiver(usbReceiver, filter, Context.RECEIVER_EXPORTED)  // <-- Cambiado aquí

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
            val buffer = ByteArray(400) // Buffer para almacenar la imagen de la huella
            val template = ByteArray(512) // Buffer para almacenar la plantilla de la huella
            val quality = IntArray(1)

            // Captura de la imagen de la huella
            val captureResult = sgfplib.GetImage(buffer)

            if (captureResult == SGFDxErrorCode.SGFDX_ERROR_NONE) {
                // Crear plantilla de la huella
                val createTemplateResult = sgfplib.CreateTemplate(null, buffer, template)

                if (createTemplateResult == SGFDxErrorCode.SGFDX_ERROR_NONE) {
                    // Convierte la plantilla a un String para guardar en SQLite
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
            // Convertimos las plantillas desde Strings separados por comas a ByteArray
            val capturedTemplateBytes = capturedTemplate.split(",").map { it.trim().toInt().toByte() }.toByteArray()
            val storedTemplateBytes = storedTemplate.split(",").map { it.trim().toInt().toByte() }.toByteArray()

            // Array para guardar la respuesta de la comparación (debe ser BooleanArray)
            val matchScore = BooleanArray(1)

            // Realizar la comparación usando el SDK de SecuGen
            val matchResult = sgfplib.MatchTemplate(
                capturedTemplateBytes,
                storedTemplateBytes,
                SGFDxSecurityLevel.SL_NORMAL,
                matchScore
            )

            if (matchResult == SGFDxErrorCode.SGFDX_ERROR_NONE) {
                Log.d("BiometricHelper", "Comparación completada con éxito. Resultado: ${matchScore[0]}")
                return matchScore[0]  // Si es true, entonces la comparación fue exitosa
            } else {
                Log.e("BiometricHelper", "Error al capturar la huella. Código de error: $matchResult")
                return false
            }
        } catch (e: Exception) {
            Log.e("BiometricHelper", "Error al comparar las huellas: ${e.message}")
            return false
        }
    }

   /* private fun captureFingerprint(): String {
        if (!isDeviceInitialized) {
            return "Dispositivo no inicializado"
        }

        try {
            val imageBuffer = ByteArray(400 * 400) // Buffer para la imagen de la huella (tamaño recomendado por el SDK)
            val templateBuffer = ByteArray(512) // Buffer para la plantilla de la huella
            val quality = IntArray(1)

            // Capturamos la huella
            val captureResult = sgfplib.GetImage(imageBuffer)
            if (captureResult != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                return "Error al capturar la huella. Código de error: $captureResult"
            }

            // Validar la calidad de la imagen capturada
            val qualityResult = sgfplib.GetImageQuality(400, 400, imageBuffer, quality)
            if (qualityResult != SGFDxErrorCode.SGFDX_ERROR_NONE || quality[0] < 50) { // Puedes ajustar este umbral de calidad
                return "Imagen de baja calidad. Intenta nuevamente."
            }

            // Crear plantilla de la huella
            val templateResult = sgfplib.CreateTemplate(null, imageBuffer, templateBuffer)
            if (templateResult != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                return "Error al crear el template de la huella. Código de error: $templateResult"
            }

            // Convertir la plantilla a String usando Base64 para almacenarla en SQLite
            val fingerprintTemplate = android.util.Base64.encodeToString(templateBuffer, android.util.Base64.NO_WRAP)

            Log.d("BiometricHelper", "Huella capturada correctamente")
            return fingerprintTemplate

        } catch (e: Exception) {
            Log.e("BiometricHelper", "Error al capturar la huella: ${e.message}")
            return "Error al capturar la huella: ${e.message}"
        }
    }*/


    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(usbReceiver)
        if (isDeviceInitialized) {
            sgfplib.CloseDevice()
            sgfplib.Close()
        }
    }
}
