import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'design_tokens.dart';

/// 全局应用主题配置
/// 基于 Material 3 规范，集成 Design Tokens
class AppTheme {
  AppTheme._();

  // 种子颜色 - 使用 Claude 品牌色
  static const Color _seedColor = MessageColors.claudeOrange;

  /// 亮色主题
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      surface: const Color(0xFFF9FAFB), // 略带灰色的背景，增加层次感
      surfaceContainerHigh: Colors.white, // 卡片背景
    );

    return _buildTheme(colorScheme);
  }

  /// 暗色主题
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF111827), // 深色背景
      surfaceContainerHigh: const Color(0xFF1F2937), // 深色卡片背景
    );

    return _buildTheme(colorScheme);
  }

  /// 构建通用主题数据
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // AppBar 样式
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: DesignTokens.elevationLow,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // 卡片样式
      cardTheme: CardThemeData(
        elevation: DesignTokens.elevationNone,
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // 浮动按钮样式
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: DesignTokens.elevationMedium,
        highlightElevation: DesignTokens.elevationHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),

      // 按钮通用样式
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingL,
            vertical: DesignTokens.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingL,
            vertical: DesignTokens.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
        ),
      ),

      // 输入框样式
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            colorScheme.brightness == Brightness.light
                ? Colors.white
                : colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),

      // SnackBar 样式
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        insetPadding: const EdgeInsets.all(DesignTokens.spacingM),
      ),

      // 对话框样式
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        ),
        backgroundColor:
            colorScheme.brightness == Brightness.light
                ? Colors.white
                : colorScheme.surfaceContainerLow,
        elevation: DesignTokens.elevationHigh,
      ),

      // 分割线样式
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
      ),

      // 列表项样式
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingXS,
        ),
      ),
    );
  }

  /// 文字样式
  static TextTheme get _textTheme {
    return GoogleFonts.interTextTheme().copyWith(
      headlineLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
      titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.5),
      bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.5),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.5,
        color: Colors.grey[600], // 默认次要文本颜色
      ),
      labelLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        fontSize: 11,
      ),
    );
  }
}
