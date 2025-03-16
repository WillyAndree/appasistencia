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
        registerReceiver(usbReceiver, filter)

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
            val buffer = ByteArray(400) // Buffer para almacenar la imagen cruda
            val templateBuffer = ByteArray(400) // Buffer para almacenar la plantilla generada
            val quality = IntArray(1)

            try {
                // Capturar imagen de la huella
                val captureResult = sgfplib.GetImage(buffer)
                if (captureResult != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                    return "Error al capturar la huella. Código de error: $captureResult"
                }
            } catch (e: Exception) {
                return "Error al intentar capturar la huella: ${e.message}"
            }

            try {
                // Generar plantilla a partir de la imagen capturada
                val createTemplateResult = sgfplib.CreateTemplate(null, buffer, templateBuffer)
                if (createTemplateResult != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                    return "Error al crear plantilla de la huella. Código de error: $createTemplateResult"
                }
            } catch (e: Exception) {
                return "Error al intentar crear la plantilla de la huella: ${e.message}"
            }

            try {
                // Convertimos la plantilla a String para almacenarla en SQLite
                val fingerprintData = templateBuffer.joinToString(",")
                Log.d("BiometricHelper", "Huella capturada correctamente")
                return fingerprintData
            } catch (e: Exception) {
                return "Error al convertir la plantilla a texto: ${e.message}"
            }

        } catch (e: Exception) {
            Log.e("BiometricHelper", "Error general al capturar la huella: ${e.message}")
            return "Error general al capturar la huella: ${e.message}"
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
