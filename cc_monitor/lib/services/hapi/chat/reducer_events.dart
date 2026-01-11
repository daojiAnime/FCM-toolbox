import 'dart:convert';

import 'types.dart';

/// Parse a normalized message as an event (if applicable)
///
/// Detects usage limit messages and converts them to events.
/// Mirrors web/src/chat/reducerEvents.ts
AgentEvent? parseMessageAsEvent(NormalizedMessage msg) {
  // Skip sidechain messages
  if (msg.isSidechain) return null;

  // Only process agent messages
  if (msg.role != NormalizedRole.agent) return null;

  // Check for usage limit format in agent content
  final agentContent = msg.agentContent;
  if (agentContent == null) return null;

  for (final content in agentContent) {
    if (content is NormalizedTextContent) {
      final match = _limitReachedRegex.firstMatch(content.text);
      if (match != null) {
        final timestamp = int.tryParse(match.group(1) ?? '') ?? 0;
        return LimitReachedEvent(endsAt: timestamp);
      }
    }
  }

  return null;
}

/// Regex for detecting usage limit messages
final _limitReachedRegex = RegExp(r'^Claude AI usage limit reached\|(\d+)$');

/// Remove duplicate consecutive events
///
/// Filters out events that are effectively the same as the previous one.
List<ChatBlock> dedupeAgentEvents(List<ChatBlock> blocks) {
  if (blocks.isEmpty) return blocks;

  final result = <ChatBlock>[];
  String? prevEventKey;
  String? prevTitleChangedTo;

  for (final block in blocks) {
    if (block is! AgentEventBlock) {
      result.add(block);
      prevEventKey = null;
      continue;
    }

    final event = block.event;
    final key = _getEventKey(event);

    // Check for duplicate title-changed events
    if (event is TitleChangedEvent) {
      final title = event.title;
      if (title == prevTitleChangedTo) {
        // Skip duplicate title change
        continue;
      }
      prevTitleChangedTo = title;
    }

    // Check for duplicate message events
    if (event is MessageEvent) {
      final message = event.message;
      if (message == prevTitleChangedTo) {
        // Skip message that matches previous title
        continue;
      }
    }

    // Check for general duplicate events
    if (key == prevEventKey) {
      continue;
    }

    result.add(block);
    prevEventKey = key;
  }

  return result;
}

/// Fold consecutive API error events, keeping only the latest state
///
/// When multiple API errors occur in sequence, only the last one is kept.
List<ChatBlock> foldApiErrorEvents(List<ChatBlock> blocks) {
  if (blocks.isEmpty) return blocks;

  final result = <ChatBlock>[];
  AgentEventBlock? pendingApiError;

  for (final block in blocks) {
    if (block is AgentEventBlock && block.event is ApiErrorEvent) {
      // Accumulate API error, replacing any pending one
      pendingApiError = block;
    } else {
      // Non-error block: flush any pending error first
      if (pendingApiError != null) {
        result.add(pendingApiError);
        pendingApiError = null;
      }
      result.add(block);
    }
  }

  // Don't forget the trailing error
  if (pendingApiError != null) {
    result.add(pendingApiError);
  }

  return result;
}

/// Generate a unique key for an event
String _getEventKey(AgentEvent event) {
  return switch (event) {
    SwitchEvent(:final mode) => 'switch:$mode',
    MessageEvent(:final message) => 'message:$message',
    TitleChangedEvent(:final title) => 'title:$title',
    LimitReachedEvent(:final endsAt) => 'limit:$endsAt',
    ApiErrorEvent(:final retryAttempt, :final maxRetries) =>
      'api-error:$retryAttempt/$maxRetries',
    ReadyEvent() => 'ready',
    UnknownEvent(:final type, :final data) => () {
      try {
        return 'unknown:$type:${jsonEncode(data)}';
      } catch (_) {
        return 'unknown:$type';
      }
    }(),
  };
}
