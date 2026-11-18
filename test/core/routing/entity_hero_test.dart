import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/string_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/layout/entity_hero.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:postfolio/features/customers/presentation/screens/customers_screen.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'signed_in_app.dart';

/// A customer's avatar, name and phone number travel between the customer's row and the
/// head of the customer's screen, through the real router.
void main() {
  final name = rameshRao.name;
  final phone = rameshRao.phone!.toPhoneFormat();

  Finder avatar() => find.byType(AppShapeAvatar);

  /// The size of the font [text] is drawn in.
  double fontSize(WidgetTester tester, Finder text) => tester
      .widget<RichText>(find.descendant(of: text, matching: find.byType(RichText)))
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
    final follower = find.ancestor(of: part, matching: find.byType(EntityHeroFollower));
    final fade = find.descendant(of: follower, matching: find.byType(FadeTransition));
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

  testWidgets('they travel from the row to the head of the screen', (tester) async {
    final router = await pumpSignedInApp(tester);
    final rowAvatar = tester.getRect(avatar());
    final rowName = tester.getRect(find.text(name));
    final rowNameSize = fontSize(tester, find.text(name));
    expect(rowAvatar.width, AppDimensions.avatarMd);

    await openFromRow(tester);
    await tester.pump(const Duration(milliseconds: 150));

    // The screen is a page of the router from the start, with its URL.
    expect(router.location(), '/customers/cust-1');
    expect(find.byType(CustomerDetailScreen, skipOffstage: false), findsOneWidget);

    // On the way: one of each, and the avatar is between its two sizes and places.
    await expectOneOfEach(tester);
    final flying = tester.getRect(avatar());
    expect(flying.width, greaterThan(AppDimensions.avatarMd));
    expect(flying.width, lessThan(AppDimensions.avatarLg));
    expect(flying.top, lessThan(rowAvatar.top));
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
    expect(tester.getRect(find.text(name)).height, greaterThan(rowName.height));
    expect(fontSize(tester, find.text(name)), greaterThan(flyingNameSize));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the back button sends them back to the row', (tester) async {
    final router = await pumpSignedInApp(tester);
    final rowAvatar = tester.getRect(avatar());
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

  testWidgets('a back swipe is the theme\'s predictive back: nothing travels', (tester) async {
    final router = await pumpSignedInApp(tester);
    await openFromRow(tester);
    await tester.pumpAndSettle();

    Future<void> send(String method, [Map<String, Object?>? arguments]) =>
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
          (_) {},
        );
    Map<String, Object?> swipe(double progress) => {
      'touchOffset': <double>[5, 300],
      'progress': progress,
      'swipeEdge': 0,
    };

    await send('startBackGesture', swipe(0));
    await tester.pump();
    await send('updateBackGestureProgress', swipe(0.6));
    await tester.pump();

    // Both screens are in view with their own copies: the row's and the screen's.
    expect(router.root().userGestureInProgress, isTrue);
    expect(avatar(), findsNWidgets(2));
    expect(find.text(name), findsNWidgets(2));
    // And nothing has to keep out of the way: the whole screen follows the finger.
    expect(shown(tester, email()), 1);
    expect(shown(tester, call()), 1);
    expect(shown(tester, section()), 1);

    await send('commitBackGesture');
    await tester.pumpAndSettle();
    expect(router.location(), '/customers');
    expect(avatar(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('while the full record loads', () {
    testWidgets('the head of the screen is the customer at once and the rest a placeholder', (
      tester,
    ) async {
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
      Finder placeholders() =>
          find.descendant(of: screen, matching: placeholder, skipOffstage: false);

      // The list's record: the name is the customer's, not the cold start's stand-in.
      expect(
        find.descendant(
          of: header,
          matching: find.text(name, skipOffstage: false),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(find.text(Customer.dummy.name, skipOffstage: false), findsNothing);
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
    });

    testWidgets('a record that arrives mid-flight does not leave two copies', (tester) async {
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

  testWidgets('a screen that no row opened: nothing travels and nothing waits', (tester) async {
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
          matching: find.ancestor(of: part, matching: find.byType(FadeTransition)),
        ),
        findsNothing,
      );
    }

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a device set to remove animations gets no travelling parts', (tester) async {
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
        matching: find.ancestor(of: email(), matching: find.byType(FadeTransition)),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: find.byType(EntityDetailHeader), matching: find.text(name)),
      findsOneWidget,
    );
  });
}
