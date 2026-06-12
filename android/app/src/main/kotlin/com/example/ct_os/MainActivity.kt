package com.example.ct_os

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val HONEYPOT_CHANNEL = "com.logm1lo.ctos/honeypot"
    private val BT_OFFENSIVE_CHANNEL = "com.logm1lo.ctos/bt_offensive"
    
    private var hotspotReservation: WifiManager.LocalOnlyHotspotReservation? = null
    private lateinit var btOffensiveHandler: BluetoothOffensiveHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        btOffensiveHandler = BluetoothOffensiveHandler(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HONEYPOT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startHotspot" -> startHotspot(result)
                "stopHotspot" -> {
                    stopHotspot()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BT_OFFENSIVE_CHANNEL).setMethodCallHandler { call, result ->
            btOffensiveHandler.handleMethod(call.method, call.arguments as? Map<String, Any>, result)
        }
    }

    private fun startHotspot(result: MethodChannel.Result) {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            wifiManager.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
                override fun onStarted(reservation: WifiManager.LocalOnlyHotspotReservation) {
                    super.onStarted(reservation)
                    hotspotReservation = reservation
                    // On LocalOnlyHotspot, we can't set the SSID programmatically on most devices
                    // but we can return the actual SSID assigned by the system
                    val config = reservation.wifiConfiguration
                    result.success(true)
                }

                override fun onStopped() {
                    super.onStopped()
                    hotspotReservation = null
                }

                override fun onFailed(reason: Int) {
                    super.onFailed(reason)
                    result.error("HOTSPOT_FAILED", "Reason: $reason", null)
                }
            }, Handler(Looper.getMainLooper()))
        } else {
            result.error("UNSUPPORTED_OS", "Requires Android O or higher", null)
        }
    }

    private fun stopHotspot() {
        hotspotReservation?.close()
        hotspotReservation = null
    }
}
