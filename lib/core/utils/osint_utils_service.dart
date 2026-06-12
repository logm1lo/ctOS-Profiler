import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import 'whats_my_name.dart';

class BreachResult {
  final String name;
  final String domain;
  final String date;
  final List<String> dataClasses;

  BreachResult({required this.name, required this.domain, required this.date, required this.dataClasses});
}

class OSINTUtilsService {
  static const String TAG = "OSINTUtilsService";
  static const String _hibpBaseUrl = 'https://haveibeenpwned.com/api/v3';

  Future<List<BreachResult>> checkEmailBreach(String email, String apiKey) async {
    developer.log('[checkEmailBreach] → Entry: email=$email', name: TAG);
    if (apiKey.isEmpty) {
      developer.log('[checkEmailBreach] → Exit: API key missing', name: TAG);
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_hibpBaseUrl/breachedaccount/$email'),
        headers: {
          'hibp-api-key': apiKey,
          'user-agent': 'ctOS-Profiler',
        },
      );

      developer.log('[checkEmailBreach] → Status: HIBP response received (status=${response.statusCode})', name: TAG);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final results = data.map((b) => BreachResult(
          name: b['Name'],
          domain: b['Domain'],
          date: b['BreachDate'],
          dataClasses: List<String>.from(b['DataClasses']),
        )).toList();
        developer.log('[checkEmailBreach] → Exit: Found ${results.length} breaches', name: TAG);
        return results;
      } else if (response.statusCode == 404) {
        developer.log('[checkEmailBreach] → Exit: No breaches found for this account', name: TAG);
        return [];
      } else {
        developer.log('[checkEmailBreach] → Error: HIBP API returned status ${response.statusCode}', name: TAG);
      }
    } catch (e) {
      developer.log('[checkEmailBreach] → Error: $e', name: TAG, error: e);
    }
    return [];
  }

  Future<Map<String, bool>> scanUsernames(String username) async {
    developer.log('[scanUsernames] → Entry: username=$username', name: TAG);
    final Map<String, bool> results = {};
    final client = http.Client();

    try {
      final platforms = WhatsMyName.platforms.entries.toList();
      developer.log('[scanUsernames] → Status: Checking ${platforms.length} platforms', name: TAG);

      for (var entry in platforms) {
        final url = entry.value.replaceAll('{}', username);
        try {
          final response = await client.get(Uri.parse(url)).timeout(const Duration(seconds: 2));

          if (response.statusCode == 200) {
            final body = response.body.toLowerCase();
            if (!body.contains('not found') && !body.contains('404')) {
              results[entry.key] = true;
              developer.log('[scanUsernames] → Found: ${entry.key}', name: TAG);
            } else {
              results[entry.key] = false;
            }
          } else {
            results[entry.key] = false;
          }
        } catch (_) {
          results[entry.key] = false;
        }
      }
    } finally {
      client.close();
      final count = results.values.where((v) => v).length;
      developer.log('[scanUsernames] → Exit: Scan complete, discovered $count platforms', name: TAG);
    }
    return results;
  }
}
