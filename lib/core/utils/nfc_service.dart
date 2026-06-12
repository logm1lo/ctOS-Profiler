import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NFCCardData {
  final String uid;
  final String type;
  final Map<String, dynamic> metadata;

  NFCCardData({required this.uid, required this.type, required this.metadata});
}

class NFCService {
  static const String TAG = "NFCService";
  final List<String> _commonMifareKeys = [
    'FFFFFFFFFFFF',
    'A0A1A2A3A4A5',
    'B0B1B2B3B4B5',
    '4D3A99C351DD',
    '1A982C7E459A',
    '000000000000',
    'aabbccddeeff',
  ];

  Stream<NFCCardData> startScanning() async* {
    developer.log('[startScanning] → Entry', name: TAG);
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      developer.log('[startScanning] → NFC Availability: $availability', name: TAG);

      if (availability != NFCAvailability.available) {
        developer.log('[startScanning] → Error: NFC hardware not available', name: TAG);
        throw 'NFC_HARDWARE_NOT_AVAILABLE';
      }

      developer.log('[startScanning] → Polling for NFC tags (20s timeout)', name: TAG);
      NFCTag tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        iosAlertMessage: "ctOS // PROXIMITY_SCAN_INITIATED",
      );

      developer.log('[startScanning] → Tag detected: ID=${tag.id}, Type=${tag.type}', name: TAG);

      String? keyFound;
      if (tag.type == NFCTagType.mifare_classic) {
        developer.log('[startScanning] → Mifare Classic detected, initiating dictionary attack on Sector 0', name: TAG);
        for (var key in _commonMifareKeys) {
          try {
            await FlutterNfcKit.authenticateSector(0, keyA: key);
            keyFound = key;
            developer.log('[startScanning] → Success! Recovered key: $keyFound', name: TAG);
            break;
          } catch (_) {
            // key mismatch, try next
          }
        }
        if (keyFound == null) developer.log('[startScanning] → Dictionary attack failed, no valid keys found', name: TAG);
      }

      final cardData = NFCCardData(
        uid: tag.id,
        type: tag.type.toString().split('.').last,
        metadata: {
          'standard': tag.standard,
          'atqa': tag.atqa ?? 'unknown',
          'sak': tag.sak ?? 'unknown',
          'historical_bytes': tag.historicalBytes ?? 'none',
          'protocol_info': tag.protocolInfo ?? 'none',
          'recovered_key': keyFound ?? 'none',
        },
      );

      developer.log('[startScanning] → Exit: Card data intercepted successfully', name: TAG);
      yield cardData;

      await FlutterNfcKit.finish();
    } catch (e) {
      developer.log('[startScanning] → Error: Interception cycle failed: $e', name: TAG, error: e);
      await FlutterNfcKit.finish();
      rethrow;
    }
  }

  Future<void> stopScanning() async {
    developer.log('[stopScanning] → Entry', name: TAG);
    try {
      await FlutterNfcKit.finish();
      developer.log('[stopScanning] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[stopScanning] → Error: $e', name: TAG, error: e);
    }
  }
}
