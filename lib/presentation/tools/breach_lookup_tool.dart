import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/osint_utils_service.dart';

class BreachLookupTool extends ConsumerStatefulWidget {
  const BreachLookupTool({super.key});

  @override
  ConsumerState<BreachLookupTool> createState() => _BreachLookupToolState();
}

class _BreachLookupToolState extends ConsumerState<BreachLookupTool> {
  static const String TAG = "BreachLookupTool";
  final TextEditingController _emailController = TextEditingController();
  final OSINTUtilsService _osintUtils = OSINTUtilsService();
  List<BreachResult> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    developer.log('[initState] → Entry', name: TAG);
    super.initState();
  }

  @override
  void dispose() {
    developer.log('[dispose] → Entry', name: TAG);
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkBreaches() async {
    final email = _emailController.text.trim();
    developer.log('[_checkBreaches] → Entry: email=$email', name: TAG);
    if (email.isEmpty) {
      developer.log('[_checkBreaches] → Exit: Email is empty', name: TAG);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Note: HIBP requires a real API key. Using a placeholder or informing user.
      final results = await _osintUtils.checkEmailBreach(email, 'PLACEHOLDER_OR_USER_KEY');
      developer.log('[_checkBreaches] → Status: Query returned ${results.length} breaches', name: TAG);

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
        if (results.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NO BREACHES FOUND OR API KEY MISSING')));
        }
      }
      developer.log('[_checkBreaches] → Exit: Completed successfully', name: TAG);
    } catch (e) {
      developer.log('[_checkBreaches] → Error: $e', name: TAG, error: e);
      if (mounted) setState(() => _isLoading = false);
    }
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
        title: Text('BREACH_LOOKUP', style: AppTextStyles.title(theme).copyWith(fontSize: 16, color: accentColor)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: accentColor), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: InputDecoration(
                labelText: 'TARGET_EMAIL',
                labelStyle: TextStyle(color: accentColor.withValues(alpha: 0.5)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : () {
                  developer.log('[Interaction] → Query initiated', name: TAG);
                  _checkBreaches();
                },
                style: OutlinedButton.styleFrom(side: BorderSide(color: accentColor)),
                child: Text('QUERY_ctOS_DATABASE', style: TextStyle(color: accentColor)),
              ),
            ),
            if (_isLoading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final b = _results[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)), color: Colors.redAccent.withValues(alpha: 0.05)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name.toUpperCase(), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        Text('DOMAIN: ${b.domain}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        Text('DATE: ${b.date}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        const Divider(color: Colors.redAccent),
                        Text('EXPOSED_DATA: ${b.dataClasses.join(", ")}', style: const TextStyle(color: Colors.white, fontSize: 9)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
