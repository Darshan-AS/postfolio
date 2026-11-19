import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/widgets/layout/entity_avatar.dart';

/// An entity's avatar in a row, at the head of a screen, and between the two.
void main() {
  Future<TextTheme> pumpAvatar(WidgetTester tester, EntityAvatar avatar) async {
    late TextTheme emphasized;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) {
                emphasized = AppTypography.emphasizedOf(context);
                return avatar;
              },
            ),
          ),
        ),
      ),
    );
    return emphasized;
  }

  TextStyle styleOf(WidgetTester tester, String text) => tester
      .widget<RichText>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      )
      .text
      .style!;

  double sizeOf(WidgetTester tester) =>
      tester.getSize(find.byType(AppShapeAvatar)).width;

  testWidgets('in a row: small, an initial larger than a code', (tester) async {
    final emphasized = await pumpAvatar(tester, const EntityAvatar(text: 'R'));
    expect(sizeOf(tester), AppDimensions.avatarMd);
    expect(styleOf(tester, 'R').fontSize, emphasized.titleLarge!.fontSize);

    await pumpAvatar(tester, const EntityAvatar(text: 'TD', subtext: '5Y'));
    expect(styleOf(tester, 'TD').fontSize, emphasized.titleSmall!.fontSize);
    expect(styleOf(tester, '5Y').fontSize, AppDimensions.fontXs);
  });

  testWidgets(
    'at the head of a screen: larger, and its letters larger for its size',
    (tester) async {
      final emphasized = await pumpAvatar(
        tester,
        const EntityAvatar(text: 'TD', subtext: '5Y', prominence: 1),
      );
      expect(sizeOf(tester), AppDimensions.avatarLg);
      expect(styleOf(tester, 'TD').fontSize, emphasized.displaySmall!.fontSize);
      expect(styleOf(tester, '5Y').fontSize, emphasized.titleMedium!.fontSize);

      // A larger share of the avatar than in a row: the two forms are not one drawing at
      // two scales, which is why the avatar changes form on its way and is not just scaled.
      final atHead =
          emphasized.displaySmall!.fontSize! / AppDimensions.avatarLg;
      final inRow = emphasized.titleSmall!.fontSize! / AppDimensions.avatarMd;
      expect(atHead, greaterThan(inRow * 1.5));
    },
  );

  testWidgets('between the two: every measure is between its two ends', (
    tester,
  ) async {
    const row = EntityAvatar(text: 'TD', subtext: '5Y');
    const head = EntityAvatar(text: 'TD', subtext: '5Y', prominence: 1);

    final emphasized = await pumpAvatar(
      tester,
      EntityAvatar.between(row, head, 0.5),
    );
    expect(
      sizeOf(tester),
      (AppDimensions.avatarMd + AppDimensions.avatarLg) / 2,
    );
    expect(
      styleOf(tester, 'TD').fontSize,
      (emphasized.titleSmall!.fontSize! + emphasized.displaySmall!.fontSize!) /
          2,
    );
    expect(
      styleOf(tester, '5Y').fontSize,
      (AppDimensions.fontXs + emphasized.titleMedium!.fontSize!) / 2,
    );

    // The ends of the way are the two forms themselves.
    await pumpAvatar(tester, EntityAvatar.between(row, head, 0));
    expect(sizeOf(tester), AppDimensions.avatarMd);
    expect(styleOf(tester, 'TD').fontSize, emphasized.titleSmall!.fontSize);
    await pumpAvatar(tester, EntityAvatar.between(row, head, 1));
    expect(sizeOf(tester), AppDimensions.avatarLg);
    expect(styleOf(tester, 'TD').fontSize, emphasized.displaySmall!.fontSize);
  });
}
