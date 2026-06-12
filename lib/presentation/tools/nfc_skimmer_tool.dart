import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/nfc_service.dart';
import '../camera/widgets/scanline_painter.dart';

class NFCSkimmerTool extends ConsumerStatefulWidget {
  const NFCSkimmerTool({super.key});

  @override
  ConsumerState<NFCSkimmerTool> createState() => _NFCSkimmerToolState();
}

class _NFCSkimmerToolState extends ConsumerState<NFCSkimmerTool> with SingleTickerProviderStateMixin {
  static const String TAG = "NFCSkimmerTool";
  final NFCService _nfcService = NFCService();
  NFCCardData? _cardData;
  bool _isScanning = false;
  late AnimationController _animationController;

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _requestPermissionAndStart();
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _nfcService.stopScanning();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionAndStart() async {
    developer.log('[_requestPermissionAndStart] → Entry', name: TAG);
    final availability = await FlutterNfcKit.nfcAvailability;
    developer.log('[_requestPermissionAndStart] → NFC Status: $availability', name: TAG);
    
    if (availability == NFCAvailability.not_supported) {
      developer.log('[_requestPermissionAndStart] → Error: Hardware not supported', name: TAG);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC_HARDWARE_NOT_SUPPORTED')),
        );
      }
      return;
    }

    if (availability == NFCAvailability.disabled) {
       developer.log('[_requestPermissionAndStart] → Error: NFC disabled in system settings', name: TAG);
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC_DISABLED_IN_SETTINGS')),
        );
      }
      return;
    }

    _startScan();
  }

  void _startScan() {
    developer.log('[_startScan] → Entry', name: TAG);
    setState(() {
      _isScanning = true;
      _cardData = null;
    });

    _nfcService.startScanning().listen((data) {
      if (mounted) {
        developer.log('[_startScan] → Data intercepted: ID=${data.uid}', name: TAG);
        setState(() {
          _cardData = data;
          _isScanning = false;
        });
      }
    }, onError: (e) {
      developer.log('[_startScan] → Error: $e', name: TAG, error: e);
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('NFC_ERROR: $e')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(settingsProvider).theme;
    final accentColor = AppColors.getAccent(theme);
    final backgroundColor = AppColors.getBackground(theme);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('NFC // SKIMMER', style: AppTextStyles.title(theme).copyWith(fontSize: 16, color: accentColor)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: accentColor), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: ScanlinePainter(
              progress: _animationController.value,
              color: AppColors.getScanLine(theme),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isScanning) ...[
                  const Icon(Icons.nfc, size: 80, color: Colors.cyanAccent),
                  const SizedBox(height: 24),
                  Text('HOLD PHONE NEAR TARGET CARD', style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.cyanAccent)),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent)),
                ] else if (_cardData != null) ...[
                  _buildCardDossier(accentColor, theme),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () {
                      developer.log('[Interaction] → New scan requested', name: TAG);
                      _startScan();
                    },
                    style: OutlinedButton.styleFrom(side: BorderSide(color: accentColor)),
                    child: Text('SCAN_NEW_TARGET', style: TextStyle(color: accentColor, fontFamily: 'monospace')),
                  ),
                ] else ...[
                   Text('NFC MODULE READY', style: AppTextStyles.hudStatus(theme).copyWith(color: Colors.grey)),
                   const SizedBox(height: 16),
                   OutlinedButton(
                    onPressed: () {
                      developer.log('[Interaction] → Initializing scan', name: TAG);
                      _startScan();
                    },
                    style: OutlinedButton.styleFrom(side: BorderSide(color: accentColor)),
                    child: Text('INITIALIZE_SCAN', style: TextStyle(color: accentColor, fontFamily: 'monospace')),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDossier(Color color, AppTheme theme) {
    final isMifare = _cardData!.type.toLowerCase().contains('mifare');
    final isIsoDep = _cardData!.type.toLowerCase().contains('isodep');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: color),
              const SizedBox(width: 12),
              Text('DATA_INTERCEPTED', style: AppTextStyles.hudStatus(theme).copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          _buildRow('UID', _cardData!.uid, color),
          _buildRow('TYPE', _cardData!.type, color),
          ..._cardData!.metadata.entries.where((e) => e.value != 'none' && e.value != 'unknown').map((e) => _buildRow(e.key.toUpperCase(), e.value.toString(), color)),
          const SizedBox(height: 12),
          if (isMifare)
             const Text('SECURITY: MIFARE_CLASSIC_ENCRYPTION (WEAK)', style: TextStyle(color: Colors.amberAccent, fontSize: 8, fontFamily: 'monospace'))
          else if (isIsoDep)
             const Text('SECURITY: EMV_SMART_CHIP (ENCRYPTED)', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontFamily: 'monospace'))
          else
             const Text('SECURITY: UNKNOWN_PROTOCOL', style: TextStyle(color: Colors.grey, fontSize: 8, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace')),
          Text(value, style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
