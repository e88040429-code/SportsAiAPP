import 'package:flutter/material.dart';

import '../../core/sport/app_sport.dart';
import '../../core/theme/app_colors.dart';
import 'data/ai_response_mock_data.dart';
import 'widgets/ai_message_bubble.dart';

class AiResponseScreen extends StatefulWidget {
  const AiResponseScreen({super.key});

  @override
  State<AiResponseScreen> createState() => _AiResponseScreenState();
}

class _AiResponseScreenState extends State<AiResponseScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late List<AiMessage> _messages;
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _messages = List.of(AiResponseMockData.seedFor(appSportController.sport));
    appSportController.addListener(_onSportChanged);
  }

  @override
  void dispose() {
    appSportController.removeListener(_onSportChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSportChanged() {
    setState(() {
      _messages = List.of(AiResponseMockData.seedFor(appSportController.sport));
      _isThinking = false;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isThinking) return;

    setState(() {
      _messages.add(AiMessage(role: AiMessageRole.user, text: text));
      _controller.clear();
      _isThinking = true;
    });
    _scrollToEnd();

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final reply = AiResponseMockData.replyFor(text, appSportController.sport);
    setState(() {
      _messages.add(AiMessage(role: AiMessageRole.assistant, text: reply));
      _isThinking = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sport = appSportController.sport;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.midTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sport.icon, size: 16, color: AppColors.midTeal),
                    const SizedBox(width: 6),
                    Text(
                      sport.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.midTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isThinking && index == _messages.length) {
                  return const AiMessageBubble(
                    message: AiMessage(
                      role: AiMessageRole.assistant,
                      text: 'Thinking…',
                    ),
                    isThinking: true,
                  );
                }
                return AiMessageBubble(message: _messages[index]);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Ask about form, timing, rehab…',
                        filled: true,
                        fillColor: AppColors.background.withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _isThinking ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.cta,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
