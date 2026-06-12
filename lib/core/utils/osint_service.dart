import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'whats_my_name.dart';

class OSINTService {
  static const String TAG = "OSINTService";
  // FaceCheck.id API integration
  static const String _baseUrl = 'https://facecheck.id/api';

  Future<bool> validateToken(String token) async {
    developer.log('[validateToken] → Entry', name: TAG);
    if (token.isEmpty) {
      developer.log('[validateToken] → Exit: Token is empty', name: TAG);
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/search'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_search': 'VALIDATION_CHECK',
          'status_only': true,
        }),
      );
      final bool isValid = response.statusCode != 401 && response.statusCode != 403;
      developer.log('[validateToken] → Exit: isValid=$isValid (status=${response.statusCode})', name: TAG);
      return isValid;
    } catch (e) {
      developer.log('[validateToken] → Error: $e', name: TAG, error: e);
      return false;
    }
  }

  Future<Map<String, dynamic>> performDeepSearch(
    Uint8List photoBytes,
    String apiKey,
    {bool testingMode = true, Function(double)? onProgress}
  ) async {
    developer.log('[performDeepSearch] → Entry: bytes=${photoBytes.length}, testingMode=$testingMode', name: TAG);
    if (apiKey.isEmpty) {
      developer.log('[performDeepSearch] → Error: API Key missing', name: TAG);
      throw 'API Key missing. Please configure it in settings.';
    }

    onProgress?.call(0.1);

    try {
      // 1. Upload Image
      developer.log('[performDeepSearch] → Status: Uploading biometrics', name: TAG);
      final String searchId = await _uploadImage(photoBytes, apiKey);
      developer.log('[performDeepSearch] → Status: Upload successful, SearchID=$searchId', name: TAG);
      onProgress?.call(0.3);

      // 2. Poll for Results
      developer.log('[performDeepSearch] → Status: Starting results polling', name: TAG);
      final results = await _pollForResults(searchId, apiKey, testingMode, onProgress);
      developer.log('[performDeepSearch] → Status: Results retrieved, enriching with username enumeration', name: TAG);

      // 3. Enrich with Username Enumeration
      final List<String> aliases = List<String>.from(results['aliases'] ?? []);
      if (aliases.isNotEmpty) {
        onProgress?.call(0.9);
        final String targetHandle = aliases.first;
        developer.log('[performDeepSearch] → Status: Enumerating platforms for handle: $targetHandle', name: TAG);
        final enrichedLinks = await _enumerateUsernames(targetHandle);
        final allLinks = {...List<String>.from(results['social_links'] ?? []), ...enrichedLinks}.toList();
        results['social_links'] = allLinks;
        results['summary'] = '${results['summary']}\nUsername enumeration discovered ${enrichedLinks.length} additional profiles.';
        developer.log('[performDeepSearch] → Status: Enrichment complete, found ${enrichedLinks.length} new links', name: TAG);
      }

      onProgress?.call(1.0);
      developer.log('[performDeepSearch] → Exit: Deep search cycle completed successfully', name: TAG);
      return results;
    } catch (e) {
      developer.log('[performDeepSearch] → Error: Deep search failed: $e', name: TAG, error: e);
      rethrow;
    }
  }

  Future<List<String>> _enumerateUsernames(String username) async {
    developer.log('[_enumerateUsernames] → Entry: username=$username', name: TAG);
    final List<String> foundLinks = [];
    final client = http.Client();

    try {
      final platforms = WhatsMyName.platforms.entries.toList();
      developer.log('[_enumerateUsernames] → Probing ${platforms.length} platforms', name: TAG);

      for (var entry in platforms) {
        final url = entry.value.replaceAll('{}', username);
        try {
          final response = await client.get(Uri.parse(url)).timeout(const Duration(seconds: 2));
          if (response.statusCode == 200) {
            if (!response.body.toLowerCase().contains('not found') &&
                !response.body.toLowerCase().contains('404')) {
              foundLinks.add(url);
              developer.log('[_enumerateUsernames] → Match found: ${entry.key}', name: TAG);
            }
          }
        } catch (_) {
          // Timeout or connection error on specific platform
        }
      }
    } finally {
      client.close();
      developer.log('[_enumerateUsernames] → Exit: Found ${foundLinks.length} profile matches', name: TAG);
    }

    return foundLinks;
  }

  Future<String> _uploadImage(Uint8List photoBytes, String apiKey) async {
    developer.log('[_uploadImage] → Entry: bytes=${photoBytes.length}', name: TAG);
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload_pic'));
    request.headers['Authorization'] = apiKey;
    request.files.add(http.MultipartFile.fromBytes(
      'images',
      photoBytes,
      filename: 'search.jpg',
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      developer.log('[_uploadImage] → Error: Upload failed (status=${response.statusCode}): ${response.body}', name: TAG);
      throw 'Upload failed: ${response.statusCode} - ${response.body}';
    }

    final json = jsonDecode(response.body);
    if (json['id_search'] != null) {
      final String id = json['id_search'] as String;
      developer.log('[_uploadImage] → Exit: Upload successful, id=$id', name: TAG);
      return id;
    } else {
      developer.log('[_uploadImage] → Error: No search ID in response: ${response.body}', name: TAG);
      throw json['error'] ?? 'Upload failed - No Search ID returned';
    }
  }

  Future<Map<String, dynamic>> _pollForResults(
    String searchId,
    String apiKey,
    bool testingMode,
    Function(double)? onProgress
  ) async {
    developer.log('[_pollForResults] → Entry: id=$searchId, testingMode=$testingMode', name: TAG);
    int attempts = 0;
    const int maxAttempts = 60; // Max 2 minutes (2s * 60)

    while (attempts < maxAttempts) {
      final response = await http.post(
        Uri.parse('$_baseUrl/search'),
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_search': searchId,
          'status_only': false,
          'testing_mode': testingMode,
        }),
      );

      if (response.statusCode != 200) {
        developer.log('[_pollForResults] → Error: Poll failed (status=${response.statusCode}): ${response.body}', name: TAG);
        throw 'Search failed: ${response.statusCode} - ${response.body}';
      }

      final json = jsonDecode(response.body);
      if (json['error'] != null) {
        developer.log('[_pollForResults] → Error: API error: ${json['error']}', name: TAG);
        throw 'API Error: ${json['error']}';
      }

      final int progress = json['progress'] ?? 0;
      final String message = json['message'] ?? 'SEARCHING...';
      developer.log('[_pollForResults] → Polling: $progress% - $message', name: TAG);

      onProgress?.call(0.3 + (progress / 100 * 0.6));

      if (json['output'] != null) {
        developer.log('[_pollForResults] → Exit: Data retrieved', name: TAG);
        return _processResults(json['output']);
      }

      attempts++;
      await Future.delayed(const Duration(seconds: 2));
    }

    developer.log('[_pollForResults] → Error: Search timed out', name: TAG);
    throw 'Search timed out after 2 minutes.';
  }

  Map<String, dynamic> _processResults(Map<String, dynamic> output) {
    developer.log('[_processResults] → Entry', name: TAG);
    final List<dynamic> items = output['items'] ?? [];
    developer.log('[_processResults] → Processing ${items.length} total items', name: TAG);

    // FaceCheck.id returns scores 0-100. High confidence matches are > 70.
    final List<Map<String, dynamic>> highConfidenceMatches = items
        .where((item) => (item['score'] ?? 0) >= 70)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    developer.log('[_processResults] → Identified ${highConfidenceMatches.length} high-confidence matches', name: TAG);

    final List<String> links = highConfidenceMatches
        .map((item) => item['url'] as String)
        .toList();

    final List<String> aliases = links
        .map((l) => extractHandle(l))
        .whereType<String>()
        .toSet()
        .toList();

    // Aggregating findings for summary
    String summary = '';
    if (links.isNotEmpty) {
      summary = 'Digital footprint detected. Found ${links.length} high-confidence matches across platforms.';
    } else {
      summary = 'No high-confidence social matches found. Footprint remains dark.';
    }

    // Try to derive some "real" traits/history from platforms found
    List<String> history = [];
    if (links.any((l) => l.contains('github.com'))) history.add('Software development activity detected.');
    if (links.any((l) => l.contains('linkedin.com'))) history.add('Professional profile indexed.');
    if (links.any((l) => l.contains('instagram.com') || l.contains('facebook.com'))) history.add('Active social presence.');

    final result = {
      'social_links': links,
      'aliases': aliases,
      'summary': summary,
      'hobby': _inferHobby(links),
      'secret': null,
      'recent_history': history,
      'exif_geo': null,
      'social_metadata': _scrapePublicMetadata(aliases, links),
    };

    developer.log('[_processResults] → Exit: Profile data formed', name: TAG);
    return result;
  }

  String? _inferHobby(List<String> links) {
    developer.log('[_inferHobby] → Analyzing ${links.length} links', name: TAG);
    if (links.any((l) => l.contains('github.com') || l.contains('stackoverflow.com'))) return 'Coding';
    if (links.any((l) => l.contains('behance.net') || l.contains('dribbble.com'))) return 'Design';
    if (links.any((l) => l.contains('soundcloud.com') || l.contains('spotify.com'))) return 'Music';
    if (links.any((l) => l.contains('strava.com'))) return 'Cycling/Running';
    if (links.any((l) => l.contains('twitch.tv'))) return 'Gaming';
    return null;
  }

  Map<String, dynamic> _scrapePublicMetadata(List<String> aliases, List<String> links) {
    if (aliases.isEmpty) return {};
    return {
      'profile_name': aliases.first.replaceAll('.', ' ').toUpperCase(),
      'platforms': links.map((l) => Uri.parse(l).host).toSet().toList(),
    };
  }

  String? extractHandle(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        if (last.isNotEmpty) return last;
        if (uri.pathSegments.length > 1) {
          return uri.pathSegments[uri.pathSegments.length - 2];
        }
      }
    } catch (_) {}
    return null;
  }
}
