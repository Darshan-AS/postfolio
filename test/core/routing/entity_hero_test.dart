import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/string_extension.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/routing/app_routes.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/widgets/layout/entity_avatar.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/layout/entity_hero.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:postfolio/features/customers/presentation/screens/customers_screen.dart';
import 'package:postfolio/features/recurring_deposits/data/fake_rd_ledger_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/rd_monthly_operations_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/screens/recurring_deposit_detail_screen.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_monthly_operation_card.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'signed_in_app.dart';

/// A customer's avatar, name and phone number travel between the customer's row and the
/// head of the customer's screen, through the real router.
void main() {
  final name = rameshRao.name;
  final phone = rameshRao.phone!.toPhoneFormat();

  Finder avatar() => find.descendant(
    of: find.byType(EntityAvatar),
    matching: find.byType(AppShapeAvatar),
  );

  /// The form of the one avatar on stage: 0 as in a row, 1 as at the head of a screen.
  double avatarForm(WidgetTester tester) =>
      tester.widget<EntityAvatar>(find.byType(EntityAvatar)).prominence;

  /// How tall the avatar's initial is drawn.
  double initialHeight(WidgetTester tester) => tester
      .getRect(find.descendant(of: avatar(), matching: find.text(name[0])))
      .height;

  /// The size of the font [text] is drawn in.
  double fontSize(WidgetTester tester, Finder text) => tester
      .widget<RichText>(
        find.descendant(of: text, matching: find.byType(RichText)),
      )
      .text
      .style!
      .fontSize!;

  /// The travelling parts on stage: a part in flight hides both of its ends.
  Future<void> expectOneOfEach(WidgetTester tester) async {
    expect(avatar(), findsOneWidget);
    expect(find.text(name), findsOneWidget);
    expect(find.text(phone), findsOneWidget);
  }

  /// How much of a part of the head that does not travel is drawn: 0 none of it, 1 all.
  double shown(WidgetTester tester, Finder part) {
    final follower = find.ancestor(
      of: part,
      matching: find.byType(EntityHeroFollower),
    );
    final fade = find.descendant(
      of: follower,
      matching: find.byType(FadeTransition),
    );
    return tester.widget<FadeTransition>(fade.first).opacity.value;
  }

  Finder call() => find.text(t.customers.actions.call);
  Finder email() => find.text(rameshRao.email!);

  /// The title of the first section under the head.
  Finder section() => find.text(t.customers.sections.personalInfo);

  Future<void> openFromRow(WidgetTester tester) async {
    await tester.tap(find.text(name));
    // The router builds the screen; the flight starts once it has been laid out.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('they travel from the row to the head of the screen', (
    tester,
  ) async {
    final router = await pumpSignedInApp(tester);
    final rowAvatar = tester.getRect(avatar());
    final rowName = tester.getRect(find.text(name));
    final rowNameSize = fontSize(tester, find.text(name));
    final rowInitial = initialHeight(tester);
    expect(rowAvatar.width, AppDimensions.avatarMd);
    expect(avatarForm(tester), 0);

    await openFromRow(tester);
    await tester.pump(const Duration(milliseconds: 150));

    // The screen is a page of the router from the start, with its URL.
    expect(router.location(), '/customers/cust-1');
    expect(
      find.byType(CustomerDetailScreen, skipOffstage: false),
      findsOneWidget,
    );

    // On the way: one of each, and the avatar is between its two sizes and places.
    await expectOneOfEach(tester);
    final flying = tester.getRect(avatar());
    expect(flying.width, greaterThan(AppDimensions.avatarMd));
    expect(flying.width, lessThan(AppDimensions.avatarLg));
    expect(flying.top, lessThan(rowAvatar.top));
    // Its initial is larger for the avatar's size at the head than in the row, and is
    // between the two on the way: the avatar does not arrive as the other form, shrunk.
    expect(avatarForm(tester), allOf(greaterThan(0), lessThan(1)));
    final flyingInitial = initialHeight(tester);
    expect(flyingInitial, greaterThan(rowInitial));
    // A line of text changes style on the way: its font is between the row's size and the
    // head's, so it leaves the row and reaches the head without a change of size. (The
    // phone number takes two lines in the row in the test font, so here it travels as the
    // screen's copy, scaled.)
    final flyingNameSize = fontSize(tester, find.text(name));
    expect(flyingNameSize, greaterThan(rowNameSize));

    await tester.pumpAndSettle();

    // Landed at the head of the screen, larger and higher than it was in the row.
    await expectOneOfEach(tester);
    final header = find.byType(EntityDetailHeader);
    expect(find.descendant(of: header, matching: avatar()), findsOneWidget);
    expect(tester.getRect(avatar()).width, AppDimensions.avatarLg);
    expect(tester.getRect(avatar()).top, lessThan(rowAvatar.top));
    expect(avatarForm(tester), 1);
    expect(initialHeight(tester), greaterThan(flyingInitial));
    expect(tester.getRect(find.text(name)).height, greaterThan(rowName.height));
    expect(fontSize(tester, find.text(name)), greaterThan(flyingNameSize));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the back button sends them back to the row', (tester) async {
    final router = await pumpSignedInApp(tester);
    final rowAvatar = tester.getRect(avatar());
    final rowInitial = initialHeight(tester);
    await openFromRow(tester);
    await tester.pumpAndSettle();
    final headAvatar = tester.getRect(avatar());

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    await expectOneOfEach(tester);
    final flying = tester.getRect(avatar());
    expect(flying.width, greaterThan(rowAvatar.width));
    expect(flying.width, lessThan(headAvatar.width));

    // Just before it lands it is the row's avatar, initial and all: nothing is left to
    // change when the row takes over.
    await tester.pump(const Duration(milliseconds: 280));
    expect(avatarForm(tester), lessThan(0.05));
    expect(tester.getRect(avatar()).width, closeTo(rowAvatar.width, 0.5));
    expect(initialHeight(tester), closeTo(rowInitial, 0.5));

    await tester.pumpAndSettle();
    expect(router.location(), '/customers');
    expect(tester.getRect(avatar()), rowAvatar);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the rest of the head keeps out of their way', (tester) async {
    await pumpSignedInApp(tester);

    // On the way in, the email line, the actions and the sections under the head are not
    // drawn: the name and the avatar pass through their places.
    await openFromRow(tester);
    await tester.pump(const Duration(milliseconds: 150));
    expect(shown(tester, email()), 0);
    expect(shown(tester, call()), 0);
    expect(shown(tester, section()), 0);

    await tester.pumpAndSettle();
    expect(shown(tester, email()), 1);
    expect(shown(tester, call()), 1);
    expect(shown(tester, section()), 1);

    // On the way out they are gone while the travelling parts are still near the head.
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(shown(tester, email()), 0);
    expect(shown(tester, call()), 0);
    expect(shown(tester, section()), 0);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('a back swipe', () {
    Future<void> send(
      WidgetTester tester,
      String method, [
      Map<String, Object?>? arguments,
    ]) => tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(method, arguments),
      ),
      (_) {},
    );
    Map<String, Object?> swipe(double progress) => {
      'touchOffset': <double>[5, 300],
      'progress': progress,
      'swipeEdge': 0,
    };

    /// The avatar at the head of the screen that is being swiped away.
    Finder headAvatar() => find.descendant(
      of: find.byType(EntityDetailHeader),
      matching: avatar(),
    );

    /// Opens the customer's screen from its row and drags a back swipe [progress] of the
    /// way. Returns where the row's avatar was.
    Future<Rect> openAndDrag(WidgetTester tester, double progress) async {
      final rowAvatar = tester.getRect(avatar());
      await openFromRow(tester);
      await tester.pumpAndSettle();

      await send(tester, 'startBackGesture', swipe(0));
      await tester.pump();
      await send(tester, 'updateBackGestureProgress', swipe(progress));
      await tester.pump();
      return rowAvatar;
    }

    testWidgets(
      'while it is dragged the screen shrinks whole and nothing travels',
      (tester) async {
        final router = await pumpSignedInApp(tester);
        await openAndDrag(tester, 0.6);

        // Both screens are in view with their own copies: the row's and the screen's.
        expect(router.root().userGestureInProgress, isTrue);
        expect(avatar(), findsNWidgets(2));
        expect(find.text(name), findsNWidgets(2));
        // The screen follows the finger whole: its avatar is drawn smaller than at rest,
        // and nothing has to keep out of anything's way.
        expect(
          tester.getRect(headAvatar()).width,
          lessThan(AppDimensions.avatarLg),
        );
        expect(shown(tester, email()), 1);
        expect(shown(tester, call()), 1);
        expect(shown(tester, section()), 1);
      },
    );

    testWidgets(
      'when it is let go the parts travel from where the screen had them',
      (tester) async {
        final router = await pumpSignedInApp(tester);
        final rowAvatar = await openAndDrag(tester, 0.5);
        final dragged = tester.getRect(headAvatar());

        await send(tester, 'commitBackGesture');
        await tester.pump();

        // One of each again: the parts have left the screen. They start where the shrunken
        // screen had them, not where the screen has them at rest.
        await expectOneOfEach(tester);
        final released = tester.getRect(avatar());
        expect(released.top, closeTo(dragged.top, 1));
        expect(released.left, closeTo(dragged.left, 1));
        expect(released.width, closeTo(dragged.width, 1));

        // On the way to the row, and the rest of the screen is out of the way.
        await tester.pump(const Duration(milliseconds: 150));
        await expectOneOfEach(tester);
        final flying = tester.getRect(avatar());
        expect(flying.top, greaterThan(released.top));
        expect(flying.top, lessThan(rowAvatar.top));
        expect(shown(tester, email()), 0);
        expect(shown(tester, call()), 0);

        await tester.pumpAndSettle();
        expect(router.location(), '/customers');
        expect(tester.getRect(avatar()), rowAvatar);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'when it is dragged back to the edge nothing travels and the screen stays',
      (tester) async {
        final router = await pumpSignedInApp(tester);
        await openAndDrag(tester, 0.5);

        await send(tester, 'cancelBackGesture');
        await tester.pump();
        expect(avatar(), findsNWidgets(2));
        expect(shown(tester, email()), 1);

        await tester.pumpAndSettle();
        expect(router.location(), '/customers/${rameshRao.id}');
        expect(tester.getRect(headAvatar()).width, AppDimensions.avatarLg);
        expect(shown(tester, email()), 1);
        expect(shown(tester, section()), 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('on iOS the swipe from the edge carries no parts', (
      tester,
    ) async {
      // Its transition carries on from where the finger left it. Parts sent off at that
      // moment would jump, so they sit this swipe out.
      final router = await pumpSignedInApp(tester);
      await openFromRow(tester);
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(4, 300));
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(avatar(), findsNWidgets(2));
      expect(router.root().userGestureInProgress, isTrue);

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // Each screen still has its own copy: nothing is drawn above them.
      expect(avatar(), findsNWidgets(2));
      expect(find.text(name), findsNWidgets(2));

      await tester.pumpAndSettle();
      expect(router.location(), '/customers');
      expect(avatar(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

  group('while the full record loads', () {
    testWidgets(
      'the head of the screen is the customer at once and the rest a placeholder',
      (tester) async {
        final customers = LateCustomerRepository();
        await pumpSignedInApp(tester, customers: customers);

        // The screen's first frame, before anything has set out for it.
        await tester.tap(find.text(name));
        await tester.pump();
        final screen = find.byType(CustomerDetailScreen, skipOffstage: false);
        final header = find.byType(EntityDetailHeader, skipOffstage: false);
        // `Skeletonizer` is built through a factory, so it cannot be found by type.
        final placeholder = find.byWidgetPredicate(
          (widget) => widget is Skeletonizer && widget.enabled,
          skipOffstage: false,
        );
        Finder placeholders() => find.descendant(
          of: screen,
          matching: placeholder,
          skipOffstage: false,
        );

        // The list's record: the name is the customer's, not the cold start's stand-in.
        expect(
          find.descendant(
            of: header,
            matching: find.text(name, skipOffstage: false),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
        expect(
          find.text(Customer.dummy.name, skipOffstage: false),
          findsNothing,
        );
        // What the list's record cannot vouch for is drawn as a placeholder, the head is not.
        expect(placeholders(), findsWidgets);
        expect(find.ancestor(of: header, matching: placeholder), findsNothing);

        // Long enough to land. A placeholder shimmers for as long as it shows, so the screen
        // does not settle.
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await expectOneOfEach(tester);
        expect(placeholders(), findsWidgets);
        final head = tester.element(find.byType(EntityDetailHeader));

        customers.answer();
        await tester.pumpAndSettle();

        // The full record: nothing is a placeholder, and the head was rebuilt in place.
        expect(placeholders(), findsNothing);
        expect(tester.element(find.byType(EntityDetailHeader)), same(head));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a record that arrives mid-flight does not leave two copies', (
      tester,
    ) async {
      final customers = LateCustomerRepository();
      await pumpSignedInApp(tester, customers: customers);

      await openFromRow(tester);
      await tester.pump(const Duration(milliseconds: 100));
      customers.answer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Still on the way: the copy at the head of the screen is hidden until they land.
      await expectOneOfEach(tester);
      expect(tester.getRect(avatar()).width, lessThan(AppDimensions.avatarLg));

      await tester.pumpAndSettle();
      await expectOneOfEach(tester);
      expect(tester.getRect(avatar()).width, AppDimensions.avatarLg);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a screen that no row opened: nothing travels and nothing waits', (
    tester,
  ) async {
    final router = await pumpSignedInApp(tester);

    // By its URL, as a link opens it. The row is in view all the same.
    final context = tester.element(find.byType(CustomersScreen));
    unawaited(GoRouter.of(context).push('/customers/${rameshRao.id}'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(router.location(), '/customers/${rameshRao.id}');

    // Each screen keeps its own copies, and the screen is drawn whole from the start.
    expect(avatar(), findsNWidgets(2));
    expect(find.text(name), findsNWidgets(2));
    for (final part in [email(), section()]) {
      expect(
        find.descendant(
          of: find.byType(EntityHeroFollower),
          matching: find.ancestor(
            of: part,
            matching: find.byType(FadeTransition),
          ),
        ),
        findsNothing,
      );
    }

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a device set to remove animations gets no travelling parts', (
    tester,
  ) async {
    final router = await pumpSignedInApp(tester, disableAnimations: true);
    Finder travelling() => find.byWidgetPredicate(
      (widget) => widget is Hero && widget.tag is (Object, EntityHeroPart),
      skipOffstage: false,
    );

    expect(find.byType(CustomersScreen), findsOneWidget);
    expect(travelling(), findsNothing);

    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    expect(router.location(), '/customers/cust-1');
    expect(travelling(), findsNothing);
    // With nothing travelling, nothing waits either.
    expect(
      find.descendant(
        of: find.byType(EntityHeroFollower),
        matching: find.ancestor(
          of: email(),
          matching: find.byType(FadeTransition),
        ),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(EntityDetailHeader),
        matching: find.text(name),
      ),
      findsOneWidget,
    );
  });

  testWidgets('EntityAvatar.between smoothly lerps avatar colours', (
    tester,
  ) async {
    const row = EntityAvatar(
      text: '#1',
      backgroundColor: Color(0xFF000000),
      foregroundColor: Color(0xFFFFFFFF),
      prominence: 0,
    );
    const head = EntityAvatar(
      text: '#1',
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF000000),
      prominence: 1,
    );

    final mid = EntityAvatar.between(row, head, 0.5);
    expect(
      mid.backgroundColor,
      Color.lerp(row.backgroundColor, head.backgroundColor, 0.5),
    );
    expect(
      mid.foregroundColor,
      Color.lerp(row.foregroundColor, head.foregroundColor, 0.5),
    );
    expect(mid.prominence, 0.5);
  });

  testWidgets(
    'Monthly Hub row shares avatar and title Hero tags with RecurringDepositDetailScreen',
    (tester) async {
      final router = await pumpSignedInApp(
        tester,
        recurringDeposits: FakeRecurringDepositRepository(
          deposits: [rameshRecurringDeposit],
        ),
        ledger: FakeRDLedgerRepository(),
      );

      final context = tester.element(find.byType(CustomersScreen));
      RecurringDepositsRoute(
        view: RDViewMode.monthlyHub.queryValue,
      ).go(context);
      await tester.pumpAndSettle();

      final hubCard = find.byType(RDMonthlyOperationCard);
      expect(hubCard, findsOneWidget);
      final expectedTag = EntityHero.tagFrom(
        EntityHero.rdHub,
        rameshRecurringDeposit.id,
      );
      expect(
        tester.widget<RDMonthlyOperationCard>(hubCard).heroTag,
        expectedTag,
      );

      // Verify both avatar and title carry matching EntityHero tags on the Hub row.
      expect(
        find.byWidgetPredicate(
          (w) => w is Hero && w.tag == (expectedTag, EntityHeroPart.avatar),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Hero && w.tag == (expectedTag, EntityHeroPart.title),
        ),
        findsOneWidget,
      );

      // Tapping opens RecurringDepositDetailScreen with matching Hero tags on the destination route.
      await tester.tap(hubCard);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        router.location(),
        startsWith('${AppRoutes.rd}/${rameshRecurringDeposit.id}'),
      );
      expect(
        find.byType(RecurringDepositDetailScreen, skipOffstage: false),
        findsOneWidget,
      );

      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(RecurringDepositDetailScreen),
          matching: find.byWidgetPredicate(
            (w) => w is Hero && w.tag == (expectedTag, EntityHeroPart.avatar),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(RecurringDepositDetailScreen),
          matching: find.byWidgetPredicate(
            (w) => w is Hero && w.tag == (expectedTag, EntityHeroPart.title),
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
