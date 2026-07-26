/// AI Coach configuration via `--dart-define` / environment.
///
/// Run examples:
/// ```bash
/// # Terminal 1 — local proxy (recommended for Chrome)
/// GEMINI_API_KEY=your_key dart run tool/ai_proxy.dart
///
/// # Terminal 2 — Flutter app
/// flutter run -d chrome --dart-define=GEMINI_API_KEY=your_key --dart-define=AI_PROXY_URL=http://localhost:8787
/// ```
abstract final class AiConfig {
  /// Google AI Studio key: https://aistudio.google.com/apikey
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Local/CORS proxy base URL (no trailing slash). Example: http://localhost:8787
  static const String proxyUrl = String.fromEnvironment(
    'AI_PROXY_URL',
    defaultValue: '',
  );

  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.0-flash',
  );

  static bool get hasGeminiKey => geminiApiKey.trim().isNotEmpty;

  static bool get hasProxyUrl => proxyUrl.trim().isNotEmpty;
}
