import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';

void main() {
  testWidgets('a sheet opened from inside a tab covers the navigation bar', (
    tester,
  ) async {
    const phone = Size(412, 915);
    tester.view.physicalSize = phone * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    var barTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          // A tab's own navigator, as the router's shell gives every destination.
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => AppAdaptiveSheet.show<void>(
                    context,
                    builder: (_) => const SizedBox(
                      height: 200,
                      child: Center(child: Text('Sheet')),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
          bottomNavigationBar: GestureDetector(
            onTap: () => barTaps++,
            child: const SizedBox(height: 80, child: Center(child: Text('Bar'))),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Down to the bottom edge of the screen, not to the top of the bar.
    expect(tester.getRect(find.byType(BottomSheet)).bottom, phone.height);

    // The bar is under the sheet and its scrim: a tap where the bar is does not reach it.
    await tester.tapAt(Offset(phone.width / 2, phone.height - 40));
    await tester.pumpAndSettle();
    expect(barTaps, 0);
  });
}
