import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cc_monitor/widgets/base/responsive_builder.dart';
import 'package:cc_monitor/common/constants.dart';

void main() {
  group('ResponsiveBuilder', () {
    testWidgets('Compact mode - width < 600', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final r = ResponsiveBuilder.of(context);
                expect(r.isCompact, true);
                expect(
                  r.cardBorderRadius,
                  AppConstants.cardBorderRadiusCompact,
                );
                expect(r.cardPadding, AppConstants.cardPaddingCompact);
                expect(r.cardMarginH, AppConstants.cardMarginHCompact);
                expect(r.cardMarginV, AppConstants.cardMarginVCompact);
                expect(r.titleIconGap, AppConstants.titleIconGapCompact);
                expect(r.contentGap, AppConstants.contentGapCompact);
                expect(r.timestampTopGap, AppConstants.timestampTopGapCompact);
                expect(
                  r.statusLabelPaddingH,
                  AppConstants.statusLabelPaddingHCompact,
                );
                expect(
                  r.statusLabelPaddingV,
                  AppConstants.statusLabelPaddingVCompact,
                );
                expect(
                  r.statusLabelBorderRadius,
                  AppConstants.statusLabelBorderRadiusCompact,
                );
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('Normal mode - width >= 600', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final r = ResponsiveBuilder.of(context);
                expect(r.isCompact, false);
                expect(r.cardBorderRadius, AppConstants.cardBorderRadius);
                expect(r.cardPadding, AppConstants.cardPadding);
                expect(r.cardMarginH, AppConstants.cardMarginH);
                expect(r.cardMarginV, AppConstants.cardMarginV);
                expect(r.titleIconGap, AppConstants.titleIconGap);
                expect(r.contentGap, AppConstants.contentGap);
                expect(r.timestampTopGap, AppConstants.timestampTopGap);
                expect(r.statusLabelPaddingH, AppConstants.statusLabelPaddingH);
                expect(r.statusLabelPaddingV, AppConstants.statusLabelPaddingV);
                expect(
                  r.statusLabelBorderRadius,
                  AppConstants.statusLabelBorderRadius,
                );
                return Container();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('Extension method works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final r = context.responsive;
              expect(r, isA<ResponsiveValues>());
              expect(r.isCompact, isA<bool>());
              expect(r.screenWidth, isA<double>());
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    });

    test('fromWidth - compact boundary', () {
      final compact = ResponsiveBuilder.fromWidth(599.0);
      expect(compact.isCompact, true);

      final normal = ResponsiveBuilder.fromWidth(600.0);
      expect(normal.isCompact, false);
    });

    test('fromWidth - returns correct values for compact', () {
      final r = ResponsiveBuilder.fromWidth(400.0);
      expect(r.isCompact, true);
      expect(r.screenWidth, 400.0);
      expect(r.cardBorderRadius, AppConstants.cardBorderRadiusCompact);
    });

    test('fromWidth - returns correct values for normal', () {
      final r = ResponsiveBuilder.fromWidth(800.0);
      expect(r.isCompact, false);
      expect(r.screenWidth, 800.0);
      expect(r.cardBorderRadius, AppConstants.cardBorderRadius);
    });
  });

  group('ResponsiveValues', () {
    test('cardBorderRadiusGeometry - returns BorderRadius', () {
      const values = ResponsiveValues(
        isCompact: false,
        screenWidth: 800,
        cardBorderRadius: 12.0,
        cardPadding: 12.0,
        cardMarginH: 12.0,
        cardMarginV: 4.0,
        titleIconGap: 8.0,
        contentGap: 4.0,
        timestampTopGap: 8.0,
        statusLabelPaddingH: 8.0,
        statusLabelPaddingV: 3.0,
        statusLabelBorderRadius: 10.0,
      );

      expect(values.cardBorderRadiusGeometry, isA<BorderRadius>());
      expect(values.cardBorderRadiusGeometry, BorderRadius.circular(12.0));
    });

    test('cardPaddingGeometry - returns EdgeInsets', () {
      const values = ResponsiveValues(
        isCompact: false,
        screenWidth: 800,
        cardBorderRadius: 12.0,
        cardPadding: 12.0,
        cardMarginH: 12.0,
        cardMarginV: 4.0,
        titleIconGap: 8.0,
        contentGap: 4.0,
        timestampTopGap: 8.0,
        statusLabelPaddingH: 8.0,
        statusLabelPaddingV: 3.0,
        statusLabelBorderRadius: 10.0,
      );

      expect(values.cardPaddingGeometry, const EdgeInsets.all(12.0));
    });

    test('cardMarginGeometry - returns EdgeInsets', () {
      const values = ResponsiveValues(
        isCompact: false,
        screenWidth: 800,
        cardBorderRadius: 12.0,
        cardPadding: 12.0,
        cardMarginH: 12.0,
        cardMarginV: 4.0,
        titleIconGap: 8.0,
        contentGap: 4.0,
        timestampTopGap: 8.0,
        statusLabelPaddingH: 8.0,
        statusLabelPaddingV: 3.0,
        statusLabelBorderRadius: 10.0,
      );

      expect(
        values.cardMarginGeometry,
        const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      );
    });

    test('statusLabelPadding - returns EdgeInsets', () {
      const values = ResponsiveValues(
        isCompact: false,
        screenWidth: 800,
        cardBorderRadius: 12.0,
        cardPadding: 12.0,
        cardMarginH: 12.0,
        cardMarginV: 4.0,
        titleIconGap: 8.0,
        contentGap: 4.0,
        timestampTopGap: 8.0,
        statusLabelPaddingH: 8.0,
        statusLabelPaddingV: 3.0,
        statusLabelBorderRadius: 10.0,
      );

      expect(
        values.statusLabelPadding,
        const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      );
    });

    test('statusLabelBorderRadiusGeometry - returns BorderRadius', () {
      const values = ResponsiveValues(
        isCompact: false,
        screenWidth: 800,
        cardBorderRadius: 12.0,
        cardPadding: 12.0,
        cardMarginH: 12.0,
        cardMarginV: 4.0,
        titleIconGap: 8.0,
        contentGap: 4.0,
        timestampTopGap: 8.0,
        statusLabelPaddingH: 8.0,
        statusLabelPaddingV: 3.0,
        statusLabelBorderRadius: 10.0,
      );

      expect(
        values.statusLabelBorderRadiusGeometry,
        BorderRadius.circular(10.0),
      );
    });

    test('maxBubbleWidth - calculates correctly', () {
      const values = ResponsiveValues(
        isCompact: false,
        screenWidth: 800,
        cardBorderRadius: 12.0,
        cardPadding: 12.0,
        cardMarginH: 12.0,
        cardMarginV: 4.0,
        titleIconGap: 8.0,
        contentGap: 4.0,
        timestampTopGap: 8.0,
        statusLabelPaddingH: 8.0,
        statusLabelPaddingV: 3.0,
        statusLabelBorderRadius: 10.0,
      );

      expect(values.maxBubbleWidth(), 800 * 0.85);
      expect(values.maxBubbleWidth(0.9), 800 * 0.9);
      expect(values.maxBubbleWidth(0.7), 800 * 0.7);
    });
  });
}
