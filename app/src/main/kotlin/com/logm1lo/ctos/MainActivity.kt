package com.logm1lo.ctos

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"
    private val HONEYPOT_CHANNEL = "com.logm1lo.ctos/honeypot"
    private val BT_OFFENSIVE_CHANNEL = "com.logm1lo.ctos/bt_offensive"
    
    private var hotspotReservation: WifiManager.LocalOnlyHotspotReservation? = null
    private lateinit var btOffensiveHandler: BluetoothOffensiveHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        Log.d(TAG, "[configureFlutterEngine] → Entry")
        super.configureFlutterEngine(flutterEngine)
        
        btOffensiveHandler = BluetoothOffensiveHandler(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HONEYPOT_CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "[HoneypotChannel] → call=${call.method}")
            when (call.method) {
                "startHotspot" -> startHotspot(result)
                "stopHotspot" -> {
                    stopHotspot()
                    result.success(null)
                }
                else -> {
                    Log.w(TAG, "[HoneypotChannel] → Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BT_OFFENSIVE_CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "[BtOffensiveChannel] → call=${call.method}")
            btOffensiveHandler.handleMethod(call.method, call.arguments as? Map<String, Any>, result)
        }
        Log.d(TAG, "[configureFlutterEngine] → Exit: Channels established")
    }

    private fun startHotspot(result: MethodChannel.Result) {
        Log.d(TAG, "[startHotspot] → Entry")
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                wifiManager.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
                    override fun onStarted(reservation: WifiManager.LocalOnlyHotspotReservation) {
                        Log.d(TAG, "[startHotspot.onStarted] → Hotspot ACTIVE")
                        super.onStarted(reservation)
                        hotspotReservation = reservation
                        result.success(true)
                    }

                    override fun onStopped() {
                        Log.d(TAG, "[startHotspot.onStopped] → Hotspot STOPPED")
                        super.onStopped()
                        hotspotReservation = null
                    }

                    override fun onFailed(reason: Int) {
                        Log.e(TAG, "[startHotspot.onFailed] → Hotspot ERROR: $reason")
                        super.onFailed(reason)
                        result.error("HOTSPOT_FAILED", "Reason: $reason", null)
                    }
                }, Handler(Looper.getMainLooper()))
                Log.d(TAG, "[startHotspot] → Exit: Request submitted to WifiManager")
            } catch (e: SecurityException) {
                Log.e(TAG, "[startHotspot] → Error: Security exception: ${e.message}")
                result.error("PERMISSION_DENIED", "Missing Location or Wifi permissions", e.message)
            } catch (e: Exception) {
                Log.e(TAG, "[startHotspot] → Exception: ${e.message}", e)
                result.error("HOTSPOT_ERROR", e.message, null)
            }
        } else {
            Log.e(TAG, "[startHotspot] → Error: OS version too low")
            result.error("UNSUPPORTED_OS", "Requires Android O or higher", null)
        }
    }

    private fun stopHotspot() {
        Log.d(TAG, "[stopHotspot] → Entry")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            hotspotReservation?.close()
        }
        hotspotReservation = null
        Log.d(TAG, "[stopHotspot] → Exit: Reservation cleared")
    }
}
