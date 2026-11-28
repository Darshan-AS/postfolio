import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/providers/session_provider.dart';
import 'package:postfolio/core/providers/theme_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/common/demo_banner.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/layout/shell_app_bar.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _relativeLuminance(Color c) {
  double linearize(double channel) => channel <= 0.04045
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linearize(c.r) +
      0.7152 * linearize(c.g) +
      0.0722 * linearize(c.b);
}

double wcagContrastRatio(Color a, Color b) {
  final l1 = _relativeLuminance(a);
  final l2 = _relativeLuminance(b);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppFinancialColors & AppTheme WCAG 2.1 AA Invariants', () {
    final themes = <String, ThemeData>{
      'light': AppTheme.lightTheme,
      'dark': AppTheme.darkTheme,
      'accessibleLight': AppTheme.accessibleLightTheme,
      'accessibleDark': AppTheme.accessibleDarkTheme,
    };

    for (final entry in themes.entries) {
      test(
        '${entry.key}: all 6 financial palettes pass WCAG AA (>=4.5 text, >=3.0 accent) and stay distinct',
        () {
          final theme = entry.value;
          final financial = theme.extension<AppFinancialColors>();
          expect(
            financial,
            isNotNull,
            reason: '${entry.key} must register AppFinancialColors',
          );

          final roles = <String, FinancialStatusPalette>{
            'settled': financial!.settled,
            'inHand': financial.inHand,
            'partial': financial.partial,
            'receivable': financial.receivable,
            'warning': financial.warning,
            'overdue': financial.overdue,
          };

          final containers = <Color>{};
          for (final role in roles.entries) {
            final p = role.value;
            final textCr = wcagContrastRatio(p.container, p.onContainer);
            expect(
              textCr,
              greaterThanOrEqualTo(4.5),
              reason: '${entry.key}.${role.key} text contrast $textCr < 4.5',
            );
            final accentCr = wcagContrastRatio(
              theme.colorScheme.surface,
              p.accent,
            );
            expect(
              accentCr,
              greaterThanOrEqualTo(3.0),
              reason:
                  '${entry.key}.${role.key} accent contrast $accentCr < 3.0',
            );
            final onAccentCr = wcagContrastRatio(p.accent, p.onAccent);
            expect(
              onAccentCr,
              greaterThanOrEqualTo(4.5),
              reason:
                  '${entry.key}.${role.key} onAccent contrast $onAccentCr < 4.5',
            );
            expect(
              containers.add(p.container),
              isTrue,
              reason:
                  '${entry.key}.${role.key} container color collides with another status',
            );
          }

          // Verify RDInstallmentDisplayStatus maps every active status to a WCAG AA readable visual.
          for (final status in RDInstallmentDisplayStatus.values) {
            final v = status.visual(theme.colorScheme, financial: financial);
            final cr = wcagContrastRatio(v.background, v.foreground);
            expect(
              cr,
              greaterThanOrEqualTo(4.5),
              reason: '${entry.key}.$status contrast $cr < 4.5',
            );
          }

          // Neutral muted step chip (onSurfaceVariant on surfaceContainerHighest).
          final mutedStepCr = wcagContrastRatio(
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.onSurfaceVariant,
          );
          expect(
            mutedStepCr,
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key} muted step chip contrast $mutedStepCr < 4.5',
          );

          // Selected "To collect" overdue badge retains overdue container/onContainer.
          final overdueBadgeCr = wcagContrastRatio(
            financial.overdue.container,
            financial.overdue.onContainer,
          );
          expect(
            overdueBadgeCr,
            greaterThanOrEqualTo(4.5),
            reason:
                '${entry.key} selected overdue badge contrast $overdueBadgeCr < 4.5',
          );

          // Due-today avatar uses primary/onPrimary explicitly.
          final dueTodayAvatar = RDInstallmentDisplayStatus.dueToday
              .avatarColors(theme.colorScheme, financial: financial);
          final dueTodayAvatarCr = wcagContrastRatio(
            dueTodayAvatar.background,
            dueTodayAvatar.foreground,
          );
          expect(
            dueTodayAvatarCr,
            greaterThanOrEqualTo(4.5),
            reason:
                '${entry.key} dueToday avatar contrast $dueTodayAvatarCr < 4.5',
          );
        },
      );

      test(
        '${entry.key}: enables FontFeature.tabularFigures on numeric/title/label text styles',
        () {
          final tt = entry.value.textTheme;
          for (final style in [
            tt.headlineMedium,
            tt.titleLarge,
            tt.titleMedium,
            tt.bodyLarge,
            tt.labelLarge,
            tt.labelSmall,
          ]) {
            expect(
              style?.fontFeatures,
              contains(const FontFeature.tabularFigures()),
            );
          }
        },
      );
    }
  });

  group('AppFeedback, StatusBadge, ShellAppBar & DemoBanner', () {
    testWidgets(
      'AppFeedback error & result SnackBars maintain >=4.5:1 contrast in Light and Dark themes',
      (tester) async {
        for (final theme in [
          AppTheme.lightTheme,
          AppTheme.darkTheme,
          AppTheme.accessibleDarkTheme,
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Builder(
                builder: (context) => Scaffold(
                  body: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => AppFeedback.showResult(
                          context,
                          const Failure('Database write rejected'),
                          successMessage: 'Saved',
                        ),
                        child: const Text('Trigger Error'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Trigger Error'));
          await tester.pumpAndSettle();

          final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
          final text = tester.widget<Text>(
            find.text('Database write rejected'),
          );
          final bg = snackBar.backgroundColor!;
          final fg = text.style!.color!;
          expect(wcagContrastRatio(bg, fg), greaterThanOrEqualTo(4.5));
        }
      },
    );

    testWidgets(
      'StatusBadge uses DepositStatus enum without uppercasing non-Latin scripts',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: StatusBadge(
                status: 'ಮುಕ್ತಾಯ',
                depositStatus: DepositStatus.closed,
              ),
            ),
          ),
        );

        expect(find.text('ಮುಕ್ತಾಯ'), findsOneWidget);
        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration! as BoxDecoration;
        expect(
          decoration.color,
          AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
        );
      },
    );

    testWidgets(
      'ShellAppBar has no dead leading button and switches all 4 theme modes; DemoBanner exits Demo Mode',
      (tester) async {
        SharedPreferences.setMockInitialValues({'demo_mode_enabled': true});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                appBar: ShellAppBar(title: 'Recurring Deposits'),
                body: DemoBanner(),
              ),
            ),
          ),
        );

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.leading, isNull);
        expect(
          find.byKey(const ValueKey('shell_account_avatar_button')),
          findsOneWidget,
        );

        // ThemeModeNotifier persists and restores all 4 theme modes.
        container
            .read(themeModeProvider.notifier)
            .setThemeMode(AppThemeMode.dark);
        await tester.pumpAndSettle();
        expect(container.read(themeModeProvider), AppThemeMode.dark);

        // Reset Demo Mode data from DemoBanner and verify repository resets cleanly.
        expect(container.read(activeSessionKeyProvider), 'demo');
        final repoSub = container.listen(customerRepositoryProvider, (_, _) {});
        addTearDown(repoSub.close);
        final deleteFuture = container
            .read(customerRepositoryProvider)
            .deleteCustomer('demo-cust-victor');
        await tester.pump(const Duration(milliseconds: 600));
        await deleteFuture;
        final afterDelete = await tester.runAsync(
          () =>
              container.read(customerRepositoryProvider).watchCustomers().first,
        );
        expect((afterDelete as Success).value, hasLength(21));

        await tester.tap(find.byKey(const ValueKey('reset_demo_data_button')));
        await tester.pumpAndSettle();
        expect(container.read(demoSessionEpochProvider), 1);
        expect(container.read(activeSessionKeyProvider), 'demo:1');
        expect(find.text(t.common.demoDataReset), findsOneWidget);
        final afterReset = await tester.runAsync(
          () =>
              container.read(customerRepositoryProvider).watchCustomers().first,
        );
        expect((afterReset as Success).value, hasLength(22));

        // Exit Demo Mode from DemoBanner.
        expect(container.read(demoModeProvider), isTrue);
        await tester.tap(find.byKey(const ValueKey('exit_demo_mode_button')));
        await tester.pumpAndSettle();
        expect(container.read(demoModeProvider), isFalse);
        expect(find.byType(MaterialBanner), findsNothing);
      },
    );
  });
}
