import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';

/// A saved action is felt as well as read.
void main() {
  group('AppFeedback', () {
    testWidgets('a saved action is felt as well as read', (tester) async {
      final haptics = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        call,
      ) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (inner) {
                context = inner;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      AppFeedback.showResult(context, const Success<void, String>(null), successMessage: 'Saved');
      await tester.pump();
      expect(find.text('Saved'), findsOneWidget);
      expect(haptics, ['HapticFeedbackType.lightImpact']);

      // A failure is read, not felt as a success.
      AppFeedback.showResult(context, const Failure<void, String>('No'), successMessage: 'Saved');
      await tester.pump();
      expect(haptics, hasLength(1));
    });
  });
}
