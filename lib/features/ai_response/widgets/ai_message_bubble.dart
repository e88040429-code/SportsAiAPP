import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/ai_response_mock_data.dart';

class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({
    super.key,
    required this.message,
    this.isThinking = false,
  });

  final AiMessage message;
  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == AiMessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.burntOrange
              : AppColors.darkTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? AppColors.onPrimary : AppColors.onSurface,
            fontStyle: isThinking ? FontStyle.italic : FontStyle.normal,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
