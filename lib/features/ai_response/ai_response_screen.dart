import 'package:flutter/material.dart';

import '../../core/config/ai_config.dart';
import '../../core/sport/app_sport.dart';
import '../../core/theme/app_colors.dart';
import 'agent/coach_agent_prompt.dart';
import 'agent/coach_ai_agent.dart';
import 'data/ai_response_mock_data.dart';
import 'widgets/ai_message_bubble.dart';

class AiResponseScreen extends StatefulWidget {
  const AiResponseScreen({
    super.key,
    this.lockedSport,
    this.title = 'AI Coach',
    this.hintText = 'Ask your AI coach about form, timing, rehab…',
    this.qaMode = false,
  });

  /// When set, chat always uses this sport (ignores Home sport picker).
  final AppSport? lockedSport;

  final String title;
  final String hintText;

  /// Stronger "ask me anything about this sport" coaching mode.
  final bool qaMode;

  @override
  State<AiResponseScreen> createState() => _AiResponseScreenState();
}

class _AiResponseScreenState extends State<AiResponseScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _agent = CoachAiAgent();

  late List<AiMessage> _messages;
  bool _isThinking = false;
  bool _lastReplyLive = false;

  AppSport get _sport => widget.lockedSport ?? appSportController.sport;

  String get _welcome {
    if (widget.qaMode) {
      return _sport == AppSport.soccer
          ? 'Ask me anything about soccer — shooting, passing, first touch, '
              'dribbling, defending, or recovery. What do you want to know?'
          : 'Ask me anything about volleyball — spikes, serves, setting, '
              'defense, footwork, timing, or recovery. What do you want to know?';
    }
    return CoachAgentPrompt.welcomeFor(_sport);
  }

  @override
  void initState() {
    super.initState();
    _messages = [
      AiMessage(role: AiMessageRole.assistant, text: _welcome),
    ];
    if (widget.lockedSport == null) {
      appSportController.addListener(_onSportChanged);
    }
  }

  @override
  void dispose() {
    if (widget.lockedSport == null) {
      appSportController.removeListener(_onSportChanged);
    }
    _controller.dispose();
    _scrollController.dispose();
    _agent.dispose();
    super.dispose();
  }

  void _onSportChanged() {
    setState(() {
      _messages = [
        AiMessage(role: AiMessageRole.assistant, text: _welcome),
      ];
      _isThinking = false;
      _lastReplyLive = false;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isThinking) return;

    final history = List<AiMessage>.of(_messages);
    setState(() {
      _messages.add(AiMessage(role: AiMessageRole.user, text: text));
      _controller.clear();
      _isThinking = true;
    });
    _scrollToEnd();

    final reply = await _agent.respond(
      sport: _sport,
      history: history,
      userMessage: text,
      qaMode: widget.qaMode,
    );

    if (!mounted) return;

    setState(() {
      _messages.add(AiMessage(role: AiMessageRole.assistant, text: reply.text));
      _isThinking = false;
      _lastReplyLive = reply.isLive;
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
    final sport = _sport;
    final liveReady = AiConfig.hasProxyUrl || AiConfig.hasGeminiKey;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (_lastReplyLive || liveReady)
                          ? AppColors.midTeal.withValues(alpha: 0.14)
                          : AppColors.burntOrange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _lastReplyLive
                          ? 'Live agent'
                          : liveReady
                              ? 'Agent ready'
                              : 'Offline tips',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _lastReplyLive || liveReady
                            ? AppColors.midTeal
                            : AppColors.burntOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                ],
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
                      text: 'Coach is thinking…',
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
                        hintText: widget.hintText,
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
