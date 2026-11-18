import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/extensions/string_extension.dart';
import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/expressive/app_loading_indicator.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/features/auth/data/auth_repository.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/customers/data/customer_repository.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/one_time_deposits/presentation/screens/one_time_deposit_detail_screen.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/rd_ledger_repository_provider.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_detail_screen.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show SkeletonizerConfig;

/// The head of a detail screen is one row: the avatar beside the name. It was a centred
/// hero that pushed what the screen is opened for below the middle of a phone.
void main() {
  const phone = Size(360, 800);

  Widget scaled(double textScale, {required Widget child}) => MediaQuery(
    data: MediaQueryData(
      size: phone,
      textScaler: TextScaler.linear(textScale),
      disableAnimations: true,
    ),
    child: child,
  );

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = phone * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
  }

  group('EntityDetailHeader', () {
    const subtitleKey = ValueKey('subtitle');
    const footerKey = ValueKey('footer');

    Future<void> pumpHeader(WidgetTester tester, {double textScale = 1.0}) async {
      usePhone(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => scaled(textScale, child: child!),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(AppDimensions.pageMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EntityDetailHeader(
                    avatarText: '#1',
                    // Short strings. The test font is far wider than the app's, and a
                    // wrapped line would make the row taller than the avatar.
                    title: '1002',
                    subtitle: const Text('RD', key: subtitleKey),
                    badge: StatusBadge(
                      status: DepositStatus.active.displayName,
                      depositStatus: DepositStatus.active,
                    ),
                    footer: const SizedBox(key: footerKey, height: 8),
                    bottomActions: [
                      AppButton(label: 'Call', onPressed: () {}),
                      AppButton.tonal(label: 'SMS', onPressed: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }

    final avatar = find.byType(AppShapeAvatar);
    final title = find.text('1002');
    final subtitle = find.byKey(subtitleKey);
    final badge = find.byType(StatusBadge);
    final footer = find.byKey(footerKey);
    final header = find.byType(EntityDetailHeader);

    testWidgets('the name and its supporting line sit beside the avatar, the badge at the '
        'end of that row', (tester) async {
      await pumpHeader(tester);
      final avatarRect = tester.getRect(avatar);
      final headerRect = tester.getRect(header);

      expect(avatarRect.size, const Size.square(AppDimensions.avatarLg));
      expect(avatarRect.left, headerRect.left);
      for (final beside in [title, subtitle]) {
        final rect = tester.getRect(beside);
        expect(rect.left, greaterThan(avatarRect.right));
        expect(rect.top, greaterThanOrEqualTo(avatarRect.top));
        expect(rect.bottom, lessThanOrEqualTo(avatarRect.bottom));
      }
      expect(tester.getRect(subtitle).left, tester.getRect(title).left);
      expect(tester.getRect(subtitle).top, greaterThanOrEqualTo(tester.getRect(title).bottom));

      final badgeRect = tester.getRect(badge);
      expect(badgeRect.left, greaterThanOrEqualTo(tester.getRect(title).right));
      expect(badgeRect.right, headerRect.right);
      expect(badgeRect.center.dy, moreOrLessEquals(avatarRect.center.dy, epsilon: 1));
    });

    testWidgets('the block and the actions follow under the row, from the start edge', (
      tester,
    ) async {
      await pumpHeader(tester);
      final headerRect = tester.getRect(header);
      final footerRect = tester.getRect(footer);
      final call = tester.getRect(find.widgetWithText(AppButton, 'Call'));
      final sms = tester.getRect(find.widgetWithText(AppButton, 'SMS'));

      expect(footerRect.top, greaterThan(tester.getRect(avatar).bottom));
      expect(footerRect.left, headerRect.left);
      expect(footerRect.right, headerRect.right);
      expect(call.top, greaterThan(footerRect.bottom));
      expect(call.left, headerRect.left);
      expect(sms.left, greaterThan(call.right));
      expect(sms.top, call.top);
    });

    testWidgets('above 1.3x text only the name stays beside the avatar; the supporting '
        'line and the badge get the full width', (tester) async {
      await pumpHeader(tester, textScale: 2.0);
      final avatarRect = tester.getRect(avatar);
      final headerRect = tester.getRect(header);
      final titleRect = tester.getRect(title);
      final subtitleRect = tester.getRect(subtitle);
      final badgeRect = tester.getRect(badge);

      expect(titleRect.left, greaterThan(avatarRect.right));
      expect(titleRect.right, lessThanOrEqualTo(headerRect.right));

      expect(subtitleRect.left, headerRect.left);
      expect(subtitleRect.top, greaterThanOrEqualTo(avatarRect.bottom));
      expect(subtitleRect.top, greaterThanOrEqualTo(titleRect.bottom));
      expect(badgeRect.left, headerRect.left);
      expect(badgeRect.top, greaterThanOrEqualTo(subtitleRect.bottom));
      expect(tester.getRect(footer).top, greaterThanOrEqualTo(badgeRect.bottom));
    });

    testWidgets('at exactly 1.3x the row layout still holds', (tester) async {
      await pumpHeader(tester, textScale: AppDimensions.largeTextScale);
      expect(tester.getRect(subtitle).left, greaterThan(tester.getRect(avatar).right));
      expect(tester.getRect(badge).right, tester.getRect(header).right);
    });
  });

  group('AppButton.text(flushStart)', () {
    Future<void> pumpButtons(
      WidgetTester tester, {
      required VoidCallback onPressed,
      TextDirection direction = TextDirection.ltr,
    }) async {
      usePhone(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingXxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Heading'),
                    AppButton.text(
                      label: 'Flush',
                      icon: HugeIcons.strokeRoundedUser,
                      size: AppButtonSize.extraSmall,
                      flushStart: true,
                      onPressed: onPressed,
                    ),
                    AppButton.text(
                      label: 'Inset',
                      icon: HugeIcons.strokeRoundedUser,
                      size: AppButtonSize.extraSmall,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    Finder iconOf(String label) => find.descendant(
      of: find.widgetWithText(AppButton, label),
      matching: find.byType(AppIcon),
    );

    testWidgets('its icon starts where the text above it starts, and it still takes a tap', (
      tester,
    ) async {
      var presses = 0;
      await pumpButtons(tester, onPressed: () => presses++);

      final heading = tester.getRect(find.text('Heading'));
      expect(tester.getRect(iconOf('Flush')).left, moreOrLessEquals(heading.left, epsilon: 0.5));
      expect(tester.getRect(iconOf('Inset')).left, greaterThan(heading.left + 8));

      await tester.tap(find.text('Flush'));
      await tester.pump();
      expect(presses, 1);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('right to left it is pulled towards the right edge', (tester) async {
      await pumpButtons(tester, onPressed: () {}, direction: TextDirection.rtl);

      final heading = tester.getRect(find.text('Heading'));
      expect(tester.getRect(iconOf('Flush')).right, moreOrLessEquals(heading.right, epsilon: 0.5));
      expect(tester.getRect(iconOf('Inset')).right, lessThan(heading.right - 8));
    });
  });

  group('detail screens', () {
    final source = FakeDataSource();
    final customer = source.customers.first;
    final rd = source.recurringDeposits.first;

    Future<void> pumpScreen(WidgetTester tester, Widget screen, {double textScale = 1.0}) async {
      usePhone(tester);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final authRepo = FakeAuthRepository(
        initialUser: const AuthUser(id: 'agent-1', email: 'agent@postfolio.dev'),
      );
      addTearDown(authRepo.dispose);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => DateTime(2026, 4, 20)),
          authRepositoryProvider.overrideWithValue(authRepo),
          customerRepositoryProvider.overrideWithValue(
            FakeCustomerRepository(customers: source.customers),
          ),
          oneTimeDepositRepositoryProvider.overrideWithValue(
            FakeOneTimeDepositRepository(deposits: source.oneTimeDeposits),
          ),
          recurringDepositRepositoryProvider.overrideWithValue(
            FakeRecurringDepositRepository(deposits: source.recurringDeposits),
          ),
          rdLedgerRepositoryProvider.overrideWithValue(
            FakeRDLedgerRepository(
              transactions: source.rdTransactions,
              poDeposits: source.rdPoDeposits,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: true,
              ),
              child: SkeletonizerConfig(
                data: AppTheme.skeletonizerConfig(Theme.of(context).colorScheme),
                child: child!,
              ),
            ),
            home: screen,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    }

    testWidgets('a recurring deposit shows its tabs in the upper part of a phone, under '
        'the progress', (tester) async {
      await pumpScreen(tester, RecurringDepositDetailScreen(depositId: rd.id));

      final header = tester.getRect(find.byType(EntityDetailHeader));
      final progress = tester.getRect(find.byType(AppLinearProgress));
      final tabs = tester.getRect(find.byType(AppButtonGroup<RDDetailTab>));

      expect(progress.left, header.left);
      expect(progress.right, header.right);
      expect(progress.top, greaterThan(tester.getRect(find.byType(AppShapeAvatar).first).bottom));
      expect(tabs.top, greaterThan(progress.bottom));
      // The hero header put them past the middle of the screen.
      expect(tabs.top, lessThan(phone.height / 2));
    });

    testWidgets('a recurring deposit is headed by its customer\'s name, with the account '
        'number and the way to the customer under it, on the same edge', (tester) async {
      await pumpScreen(tester, RecurringDepositDetailScreen(depositId: rd.id));

      // As the deposit's row in the list: whose it is, then which.
      final header = find.byType(EntityDetailHeader);
      final title = tester.getRect(
        find.descendant(of: header, matching: find.text(rd.customerName!)),
      );
      final number = tester.getRect(
        find.descendant(of: header, matching: find.text(rd.accountNo!)),
      );
      expect(number.left, moreOrLessEquals(title.left, epsilon: 0.5));
      expect(number.top, greaterThanOrEqualTo(title.bottom));

      // The title says the name, so the link says where it leads.
      final link = find.descendant(
        of: header,
        matching: find.widgetWithText(AppButton, t.customers.customerDetails),
      );
      expect(link, findsOneWidget);
      final icon = tester.getRect(find.descendant(of: link, matching: find.byType(AppIcon)));
      expect(icon.left, moreOrLessEquals(title.left, epsilon: 0.5));
      expect(icon.top, greaterThan(number.bottom));
    });

    testWidgets('a one-time deposit is headed by its customer\'s name, with the account '
        'number under it', (tester) async {
      final otd = source.oneTimeDeposits.first;
      await pumpScreen(tester, OneTimeDepositDetailScreen(depositId: otd.id));

      final header = find.byType(EntityDetailHeader);
      final title = tester.getRect(
        find.descendant(of: header, matching: find.text(otd.customerName!)),
      );
      final number = tester.getRect(
        find.descendant(of: header, matching: find.text(otd.accountNo!)),
      );
      expect(number.left, moreOrLessEquals(title.left, epsilon: 0.5));
      expect(number.top, greaterThanOrEqualTo(title.bottom));
    });

    for (final textScale in const [1.0, 2.0]) {
      testWidgets('at ${textScale}x text a customer\'s phone number and email each stay on '
          'one line, inside the screen', (tester) async {
        await pumpScreen(
          tester,
          CustomerDetailScreen(customerId: customer.id),
          textScale: textScale,
        );

        final header = find.byType(EntityDetailHeader);
        final headerRect = tester.getRect(header);
        for (final line in [customer.phone!.toPhoneFormat(), customer.email!]) {
          final finder = find.descendant(of: header, matching: find.text(line));
          expect(finder, findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: finder, matching: find.byType(RichText)),
          );
          // As tall as it is when it has all the width it wants: one line.
          expect(
            paragraph.size.height,
            moreOrLessEquals(paragraph.getMaxIntrinsicHeight(double.infinity), epsilon: 0.01),
          );
          final rect = tester.getRect(finder);
          expect(rect.left, greaterThanOrEqualTo(headerRect.left));
          expect(rect.right, lessThanOrEqualTo(headerRect.right + 0.01));
        }
      });
    }
  });
}
