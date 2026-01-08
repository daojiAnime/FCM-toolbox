import 'package:flutter/material.dart';

/// 消息类型颜色系统
class MessageColors {
  MessageColors._();

  // 8 种消息类型颜色
  static const Color progress = Color(0xFF2196F3); // 蓝 - 进度
  static const Color complete = Color(0xFF4CAF50); // 绿 - 完成
  static const Color error = Color(0xFFF44336); // 红 - 错误
  static const Color warning = Color(0xFFFF9800); // 橙 - 警告
  static const Color code = Color(0xFF607D8B); // 灰 - 代码
  static const Color markdown = Color(0xFF9C27B0); // 紫 - Markdown
  static const Color image = Color(0xFF00BCD4); // 青 - 图片
  static const Color interactive = Color(0xFFE91E63); // 粉 - 交互

  // Claude 品牌色
  static const Color claudeOrange = Color(0xFFD97706);
  static const Color claudeBrown = Color(0xFFCC785C);

  /// 根据消息类型获取颜色
  static Color fromType(String type) {
    return switch (type.toLowerCase()) {
      'progress' => progress,
      'complete' => complete,
      'error' => error,
      'warning' => warning,
      'code' => code,
      'markdown' => markdown,
      'image' => image,
      'interactive' => interactive,
      _ => code, // 默认灰色
    };
  }

  /// 根据消息类型获取图标
  static IconData iconFromType(String type) {
    return switch (type.toLowerCase()) {
      'progress' => Icons.hourglass_empty_rounded,
      'complete' => Icons.check_circle_rounded,
      'error' => Icons.error_rounded,
      'warning' => Icons.warning_rounded,
      'code' => Icons.code_rounded,
      'markdown' => Icons.description_rounded,
      'image' => Icons.image_rounded,
      'interactive' => Icons.touch_app_rounded,
      _ => Icons.article_rounded,
    };
  }

  /// 根据消息类型获取 emoji
  static String emojiFromType(String type) {
    return switch (type.toLowerCase()) {
      'progress' => '⏳',
      'complete' => '✅',
      'error' => '❌',
      'warning' => '⚠️',
      'code' => '💻',
      'markdown' => '📝',
      'image' => '🖼️',
      'interactive' => '🎯',
      _ => '📄',
    };
  }

  /// 根据消息类型获取状态标签文本
  static String labelFromType(String type) {
    return switch (type.toLowerCase()) {
      'progress' => '进行中',
      'complete' => '已完成',
      'error' => '错误',
      'warning' => '警告',
      'code' => '代码',
      'markdown' => '文档',
      'image' => '图片',
      'interactive' => '待响应',
      _ => '消息',
    };
  }
}
