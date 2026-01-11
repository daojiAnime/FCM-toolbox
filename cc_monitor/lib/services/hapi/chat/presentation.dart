import 'package:flutter/material.dart';

import 'types.dart';

/// Event presentation data
///
/// Mirrors web/src/chat/presentation.ts
class EventPresentation {
  final String? icon; // emoji or null
  final String text;
  final IconData? iconData; // Flutter icon alternative

  const EventPresentation({this.icon, required this.text, this.iconData});
}

/// Get presentation data for an agent event
EventPresentation getEventPresentation(AgentEvent event) {
  return switch (event) {
    ApiErrorEvent(:final retryAttempt, :final maxRetries) => () {
      if (retryAttempt >= maxRetries) {
        return const EventPresentation(
          icon: '⚠️',
          text: 'API error: Max retries reached',
          iconData: Icons.warning_amber_rounded,
        );
      } else {
        return EventPresentation(
          icon: '⏳',
          text: 'API error: Retrying ($retryAttempt/$maxRetries)',
          iconData: Icons.hourglass_empty,
        );
      }
    }(),
    SwitchEvent(:final mode) => EventPresentation(
      icon: '🔄',
      text: 'Switched to $mode',
      iconData: Icons.swap_horiz,
    ),
    TitleChangedEvent(:final title) =>
      title.isNotEmpty
          ? EventPresentation(
            icon: null,
            text: 'Title: "$title"',
            iconData: Icons.title,
          )
          : const EventPresentation(
            icon: null,
            text: 'Title changed',
            iconData: Icons.title,
          ),
    LimitReachedEvent(:final endsAt) => EventPresentation(
      icon: '⏳',
      text: 'Usage limit reached until ${formatUnixTimestamp(endsAt)}',
      iconData: Icons.schedule,
    ),
    MessageEvent(:final message) => EventPresentation(
      icon: null,
      text: message,
      iconData: Icons.info_outline,
    ),
    ReadyEvent() => const EventPresentation(
      icon: '✅',
      text: 'Ready',
      iconData: Icons.check_circle_outline,
    ),
    UnknownEvent(:final type) => EventPresentation(
      icon: null,
      text: type,
      iconData: Icons.help_outline,
    ),
  };
}

/// Render event as a simple label string
String renderEventLabel(AgentEvent event) {
  return getEventPresentation(event).text;
}

/// Format a Unix timestamp to a readable string
String formatUnixTimestamp(int value) {
  // Handle both seconds and milliseconds
  final ms = value < 1e12 ? value * 1000 : value;

  try {
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return value.toString();
  }
}
