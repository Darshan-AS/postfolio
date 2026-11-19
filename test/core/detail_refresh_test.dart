import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/expressive/app_refresh_indicator.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/i18n/strings.g.dart';

void main() {
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  Future<void> pumpDetail(WidgetTester tester, {Future<void> Function()? onRefresh}) async {
    tester.view.physicalSize = const Size(360, 800) * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: EntityDetailScaffold(
          appBarTitle: 'Customer',
          onEdit: () {},
          onDelete: () async => null,
          deleteDialogTitle: 'Delete',
          deleteDialogContent: 'Delete this customer?',
          onRefresh: onRefresh,
          header: const EntityDetailHeader(title: 'Ramesh Rao', avatarText: 'R'),
          // Shorter than the screen: there is nothing to scroll, only to pull.
          body: const [Text('One line')],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('pulling a detail screen down reloads it, even when it is short', (tester) async {
    var reloads = 0;
    await pumpDetail(tester, onRefresh: () async => reloads++);

    await tester.drag(find.text('One line'), const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(reloads, 1);
    expect(find.text('One line'), findsOneWidget);
  });

  testWidgets('a detail screen with nothing to reload has no refresh indicator', (tester) async {
    await pumpDetail(tester);
    expect(find.byType(AppRefreshIndicator), findsNothing);
  });
}
