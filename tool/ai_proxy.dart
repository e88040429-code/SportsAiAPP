import 'dart:convert';
import 'dart:io';

/// Tiny local proxy so Flutter web can call Gemini without browser CORS issues.
///
/// Usage:
/// ```bash
/// export GEMINI_API_KEY=your_key_here
/// dart run tool/ai_proxy.dart
/// ```
///
/// Then run the app with:
/// ```bash
/// flutter run -d chrome --dart-define=AI_PROXY_URL=http://localhost:8787
/// ```
Future<void> main(List<String> args) async {
  final apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    stderr.writeln('Missing GEMINI_API_KEY environment variable.');
    stderr.writeln('Get a free key at https://aistudio.google.com/apikey');
    exitCode = 1;
    return;
  }

  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8787;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('SetPoint AI proxy listening on http://localhost:$port');
  stdout.writeln('POST /v1/coach  ·  GET /health');

  await for (final request in server) {
    // CORS for Flutter web
    request.response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type');

    try {
      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        continue;
      }

      if (request.method == 'GET' && request.uri.path == '/health') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'ok': true}));
        await request.response.close();
        continue;
      }

      if (request.method == 'POST' && request.uri.path == '/v1/coach') {
        final body = await utf8.decoder.bind(request).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final model = (data['model'] as String?) ?? 'gemini-2.0-flash';
        final system = (data['system'] as String?) ?? '';
        final messages = (data['messages'] as List<dynamic>? ?? const []);

        final contents = <Map<String, dynamic>>[];
        for (final raw in messages) {
          final m = raw as Map<String, dynamic>;
          contents.add({
            'role': m['role'] == 'user' ? 'user' : 'model',
            'parts': [
              {'text': m['text']},
            ],
          });
        }

        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/'
          '$model:generateContent?key=$apiKey',
        );

        final client = HttpClient();
        try {
          final upstream = await client.postUrl(uri);
          upstream.headers.contentType = ContentType.json;
          upstream.write(
            jsonEncode({
              if (system.isNotEmpty)
                'systemInstruction': {
                  'parts': [
                    {'text': system},
                  ],
                },
              'contents': contents,
              'generationConfig': {
                'temperature': 0.75,
                'maxOutputTokens': 2048,
              },
            }),
          );

          final upstreamResponse = await upstream.close();
          final upstreamBody =
              await utf8.decoder.bind(upstreamResponse).join();

          if (upstreamResponse.statusCode < 200 ||
              upstreamResponse.statusCode >= 300) {
            request.response
              ..statusCode = HttpStatus.badGateway
              ..headers.contentType = ContentType.json
              ..write(
                jsonEncode({
                  'error': 'Gemini error',
                  'status': upstreamResponse.statusCode,
                  'body': upstreamBody,
                }),
              );
            await request.response.close();
            continue;
          }

          final parsed = jsonDecode(upstreamBody) as Map<String, dynamic>;
          final candidates = parsed['candidates'] as List<dynamic>?;
          String? text;
          if (candidates != null && candidates.isNotEmpty) {
            final content =
                candidates.first['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null) {
              for (final part in parts) {
                final t = (part as Map<String, dynamic>)['text'] as String?;
                if (t != null && t.trim().isNotEmpty) {
                  text = t.trim();
                  break;
                }
              }
            }
          }

          if (text == null) {
            request.response
              ..statusCode = HttpStatus.badGateway
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'error': 'Empty model response', 'raw': parsed}));
            await request.response.close();
            continue;
          }

          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'text': text, 'live': true}));
          await request.response.close();
        } finally {
          client.close();
        }
        continue;
      }

      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not found');
      await request.response.close();
    } catch (e, st) {
      stderr.writeln('Proxy error: $e\n$st');
      try {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'error': e.toString()}));
        await request.response.close();
      } catch (_) {}
    }
  }
}
