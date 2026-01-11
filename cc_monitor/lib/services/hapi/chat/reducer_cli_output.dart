import 'types.dart';

/// CLI output detection and merging utilities
///
/// Mirrors web/src/chat/reducerCliOutput.ts

/// Regex patterns for CLI tags
final _cliTagRegex = RegExp(
  r'<(?:local-command-[a-z-]+|command-(?:name|message|args))>',
  caseSensitive: false,
);
final _commandNameRegex = RegExp(r'<command-name>', caseSensitive: false);
final _localCommandStdoutRegex = RegExp(
  r'<local-command-stdout>',
  caseSensitive: false,
);

/// Check if text is CLI output based on content and meta
bool isCliOutputText(String text, Map<String, dynamic>? meta) {
  if (meta == null) return false;
  final sentFrom = meta['sentFrom'];
  if (sentFrom != 'cli') return false;
  return hasCliOutputTags(text);
}

/// Check if text contains CLI output tags
bool hasCliOutputTags(String text) {
  return _cliTagRegex.hasMatch(text);
}

/// Check if text contains a command name tag
bool hasCommandNameTag(String text) {
  return _commandNameRegex.hasMatch(text);
}

/// Check if text contains a local command stdout tag
bool hasLocalCommandStdoutTag(String text) {
  return _localCommandStdoutRegex.hasMatch(text);
}

/// Create a CLI output block
CliOutputBlock createCliOutputBlock({
  required String id,
  required String? localId,
  required int createdAt,
  required String text,
  required String source,
  Map<String, dynamic>? meta,
}) {
  return CliOutputBlock(
    id: id,
    localId: localId,
    createdAt: createdAt,
    text: text,
    source: source,
    meta: meta,
  );
}

/// Merge consecutive CLI output blocks when appropriate
///
/// Merges when:
/// 1. Two consecutive cli-output blocks have the same source
/// 2. The first block has `<command-name>` but no `<local-command-stdout>`
/// 3. The second block has `<local-command-stdout>`
List<ChatBlock> mergeCliOutputBlocks(List<ChatBlock> blocks) {
  if (blocks.isEmpty) return blocks;

  final result = <ChatBlock>[];
  CliOutputBlock? pendingBlock;

  for (final block in blocks) {
    if (block is! CliOutputBlock) {
      // Flush pending and add current
      if (pendingBlock != null) {
        result.add(pendingBlock);
        pendingBlock = null;
      }
      result.add(block);
      continue;
    }

    if (pendingBlock == null) {
      // Start a new pending block
      pendingBlock = block;
      continue;
    }

    // Check merge conditions
    final canMerge =
        pendingBlock.source == block.source &&
        hasCommandNameTag(pendingBlock.text) &&
        !hasLocalCommandStdoutTag(pendingBlock.text) &&
        hasLocalCommandStdoutTag(block.text);

    if (canMerge) {
      // Merge the two blocks
      final mergedText = '${pendingBlock.text}\n${block.text}';
      pendingBlock = CliOutputBlock(
        id: pendingBlock.id,
        localId: pendingBlock.localId,
        createdAt: pendingBlock.createdAt,
        text: mergedText,
        source: pendingBlock.source,
        meta: pendingBlock.meta,
      );
    } else {
      // Can't merge, flush pending and start new
      result.add(pendingBlock);
      pendingBlock = block;
    }
  }

  // Flush any remaining pending block
  if (pendingBlock != null) {
    result.add(pendingBlock);
  }

  return result;
}
