import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/ai_config.dart';
import '../../../core/sport/app_sport.dart';
import '../../coach/data/clip_analysis_session.dart';
import '../data/ai_response_mock_data.dart';
import 'coach_agent_prompt.dart';

/// SetPoint AI coaching agent — multi-turn chat with Gemini (+ offline fallback).
class CoachAiAgent {
  CoachAiAgent({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String? get _clipContext {
    final analysis = clipAnalysisController.latest;
    if (analysis == null) return null;
    return analysis.aiContextBlock;
  }

  /// Sends the latest user message plus prior history to the model.
  Future<CoachAgentReply> respond({
    required AppSport sport,
    required List<AiMessage> history,
    required String userMessage,
    bool qaMode = false,
  }) async {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) {
      return const CoachAgentReply(
        text: 'Ask me anything about your form, timing, or recovery.',
        isLive: false,
      );
    }

    try {
      if (AiConfig.hasProxyUrl) {
        return await _respondViaProxy(
          sport: sport,
          history: history,
          userMessage: trimmed,
          qaMode: qaMode,
        );
      }

      if (AiConfig.hasGeminiKey && !kIsWeb) {
        return await _respondDirectGemini(
          sport: sport,
          history: history,
          userMessage: trimmed,
          qaMode: qaMode,
        );
      }
    } catch (e) {
      debugPrint('CoachAiAgent live call failed: $e');
      return CoachAgentReply(
        text:
            '${AiResponseMockData.replyFor(trimmed, sport)}\n\n'
            '(Offline tip — start the AI proxy with your Gemini key for live coaching.)',
        isLive: false,
        error: e.toString(),
      );
    }

    return CoachAgentReply(
      text: AiResponseMockData.replyFor(trimmed, sport),
      isLive: false,
    );
  }

  Future<CoachAgentReply> _respondViaProxy({
    required AppSport sport,
    required List<AiMessage> history,
    required String userMessage,
    required bool qaMode,
  }) async {
    final uri = Uri.parse('${AiConfig.proxyUrl}/v1/coach');
    final payload = {
      'sport': sport.name,
      'system': CoachAgentPrompt.systemFor(
        sport,
        qaMode: qaMode,
        clipContext: _clipContext,
      ),
      'model': AiConfig.geminiModel,
      'messages': [
        for (final m in history)
          {
            'role': m.role == AiMessageRole.user ? 'user' : 'model',
            'text': m.text,
          },
        {'role': 'user', 'text': userMessage},
      ],
    };

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Proxy ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (body['text'] as String?)?.trim();
    if (text == null || text.isEmpty) {
      throw Exception('Empty model response');
    }

    return CoachAgentReply(text: text, isLive: true);
  }

  Future<CoachAgentReply> _respondDirectGemini({
    required AppSport sport,
    required List<AiMessage> history,
    required String userMessage,
    required bool qaMode,
  }) async {
    final model = AiConfig.geminiModel;
    final key = AiConfig.geminiApiKey;
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent?key=$key',
    );

    final contents = <Map<String, dynamic>>[
      for (final m in history)
        {
          'role': m.role == AiMessageRole.user ? 'user' : 'model',
          'parts': [
            {'text': m.text},
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': userMessage},
        ],
      },
    ];

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {
                  'text': CoachAgentPrompt.systemFor(
                    sport,
                    qaMode: qaMode,
                    clipContext: _clipContext,
                  ),
                },
              ],
            },
            'contents': contents,
            'generationConfig': {
              'temperature': 0.75,
              'maxOutputTokens': 2048,
            },
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = body['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No candidates from Gemini');
    }
    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts?.firstWhere(
      (p) => (p as Map)['text'] != null,
      orElse: () => null,
    );
    final out = (text as Map?)?['text'] as String?;
    if (out == null || out.trim().isEmpty) {
      throw Exception('Empty Gemini text');
    }

    return CoachAgentReply(text: out.trim(), isLive: true);
  }

  void dispose() {
    _client.close();
  }
}
