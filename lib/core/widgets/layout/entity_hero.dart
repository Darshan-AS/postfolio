import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/widgets/layout/entity_avatar.dart';

/// The parts of an entity that its row in a list and the head of its screen both show.
///
/// A part is named for its place on the screen. A deposit's account number is the line
/// under the head's title, its [subtitle], also on its customer's screen, where it is the
/// title of the row. Its [amount] is the first figure under the head.
enum EntityHeroPart { avatar, title, subtitle, amount }

/// The zone value that holds where a screen is drawn at the moment a back swipe on it is
/// let go (a `Matrix4`), while [EntityHeroBackSwipe] starts the parts on their way back.
final Object _releasedScreen = Object();

/// A part of an entity that travels between its row in a list and the head of its screen
/// when the screen opens, and back when it is closed: with the back button, or when a back
/// swipe is let go (see [EntityHeroBackSwipe]).
///
/// Give the row's copy and the screen's copy the same [tag] (see [tagFrom]) and [part].
/// It is the framework's `Hero`: the screens keep their page transition, their URL and the
/// back swipe, and a screen that no row opened (a link, a URL) opens as before.
///
/// A line of text changes on the way from the row's style to the screen's: its size, its
/// weight and its colour, so that it leaves and arrives looking as it does there. So does
/// an [EntityAvatar], whose letters are larger for its size at the head of a screen than
/// in a row. Anything else (a name on two lines) is the screen's copy, the larger of the
/// two, scaled to the box on its way.
class EntityHero extends StatelessWidget {
  const EntityHero({
    super.key,
    required this.tag,
    required this.part,
    required this.child,
  });

  /// Identifies the entity and the row. Null where nothing travels: a placeholder, or a
  /// screen that no row opened.
  final Object? tag;
  final EntityHeroPart part;
  final Widget child;

  /// The origin of a row in the entity's own list (see [tagFrom]).
  static const String ownList = 'list';

  /// The tag of the parts of the entity [id] that travel between a row and the head of
  /// the screen that row opens.
  ///
  /// [origin] names where the row is. An entity can have a row in more than one place (a
  /// deposit in the deposits list and on its customer's screen), and those places can be
  /// on the two screens of one transition. The head pairs only with the row that opened
  /// it: the row hands its origin to the route it pushes (`$extra`), and the screen builds
  /// its tag from that. A screen opened any other way has no origin and so no tag.
  static Object? tagFrom(String? origin, String id) =>
      origin == null ? null : (origin, id);

  @override
  Widget build(BuildContext context) {
    final tag = this.tag;
    // A device set to remove animations gets none.
    if (tag == null || MediaQuery.disableAnimationsOf(context)) return child;

    // Detail screens are pages of the root navigator, and a back swipe is its gesture.
    final ValueListenable<bool> backSwipe =
        Navigator.maybeOf(
          context,
          rootNavigator: true,
        )?.userGestureInProgressNotifier ??
        const AlwaysStoppedAnimation(false);
    return ValueListenableBuilder<bool>(
      valueListenable: backSwipe,
      builder: (context, isSwiping, child) => Hero(
        tag: (tag, part),
        // The framework asks this when a back swipe starts, and would move the part with
        // the finger: no, the screen follows the finger whole. [EntityHeroBackSwipe] asks
        // again when the swipe is let go: yes.
        transitionOnUserGestures: isSwiping,
        createRectTween: _path,
        flightShuttleBuilder: _inFlight,
        child: child!,
      ),
      child: child,
    );
  }

  /// The way a part takes: the framework's arc for Material.
  ///
  /// The framework measures a part inside its screen, as if the screen were at rest. A
  /// screen whose back swipe has just been let go is shrunk and moved aside, and the part
  /// sets out from where it is drawn there.
  static Tween<Rect?> _path(Rect? begin, Rect? end) {
    final Object? screen = Zone.current[_releasedScreen];
    return MaterialRectArcTween(
      begin: begin != null && screen is Matrix4
          ? MatrixUtils.transformRect(screen, begin)
          : begin,
      end: end,
    );
  }

  static Widget _inFlight(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    // The screen is the route on top: where a push goes to and where a pop comes from.
    final isPush = direction == HeroFlightDirection.push;
    final onScreen = isPush ? toHeroContext : fromHeroContext;
    final inRow = isPush ? fromHeroContext : toHeroContext;
    final atScreen = (onScreen.widget as Hero).child;
    final atRow = (inRow.widget as Hero).child;

    if (atScreen is Text &&
        atRow is Text &&
        atScreen.data != null &&
        _isOneLine(onScreen, atScreen) &&
        _isOneLine(inRow, atRow)) {
      final (_, part) =
          (onScreen.widget as Hero).tag as (Object, EntityHeroPart);
      // The route's animation is at 0 with the row and at 1 with the screen, whichever
      // way the parts are going.
      return DefaultTextStyleTransition(
        style: animation.drive(
          TextStyleTween(
            begin: _styleOf(inRow, atRow),
            end: _styleOf(onScreen, atScreen),
          ),
        ),
        child: Align(
          // An amount ends its line at both places; everything else starts it.
          alignment: part == EntityHeroPart.amount
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Text(
            atScreen.data!,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
        ),
      );
    }

    if (atScreen is EntityAvatar && atRow is EntityAvatar) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) => FittedBox(
          child: EntityAvatar.between(atRow, atScreen, animation.value),
        ),
      );
    }

    final size = (onScreen.findRenderObject()! as RenderBox).size;
    return FittedBox(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox.fromSize(
        size: size,
        // In flight the copy is drawn above both screens, where no `Material` gives text
        // its default style.
        child: Material(type: MaterialType.transparency, child: atScreen),
      ),
    );
  }

  /// The style [text] is drawn in at [context], complete, so that two of them can be
  /// blended.
  static TextStyle _styleOf(BuildContext context, Text text) =>
      DefaultTextStyle.of(
        context,
      ).style.merge(text.style).copyWith(inherit: false);

  /// Whether [text] takes one line at [context]. Two lines are at least two and a half
  /// times the font's size tall, one line at most one and a half.
  static bool _isOneLine(BuildContext context, Text text) {
    final fontSize = _styleOf(context, text).fontSize;
    if (fontSize == null) return false;
    final height = (context.findRenderObject()! as RenderBox).size.height;
    return height < 2 * MediaQuery.textScalerOf(context).scale(fontSize);
  }
}

/// Sends the parts back to the row when a back swipe is let go.
///
/// Android's predictive back moves the screen with the finger and, once the finger lifts,
/// plays the screen's exit from its start. The framework's `Hero` has no answer to that:
/// a part either follows the finger and jumps when the exit restarts, or sits the swipe
/// out. This asks the navigator's hero controller for the flights at the moment the swipe
/// is let go, and the parts set out from where the shrunken screen has left them.
///
/// Give it to the navigator that holds the detail screens (`GoRouter.observers`). It leans
/// on the order in which the framework handles a released swipe: the pop is announced to
/// the observers before the exit is restarted. `test/core/routing/entity_hero_test.dart`
/// holds it to that.
class EntityHeroBackSwipe extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final navigator = this.navigator;
    // A pop by the back button is the framework's to handle.
    if (navigator == null || !navigator.userGestureInProgress) return;
    if (route is! ModalRoute || !_exitRestartsWhenLetGo(navigator.context)) {
      return;
    }
    final controller = HeroControllerScope.maybeOf(navigator.context);
    final screen = route.subtreeContext?.findRenderObject();
    if (controller == null || screen == null) return;

    runZoned(
      // What the controller does for a swipe that carries parts: it starts their flights
      // back. They ask for their way inside this call ([EntityHero._path]).
      () => controller.didStartUserGesture(route, previousRoute),
      zoneValues: {
        _releasedScreen: screen.getTransformTo(
          navigator.context.findRenderObject(),
        ),
      },
    );
  }

  /// Only the predictive back transition plays the exit from its start. Under a swipe
  /// that carries on from where the finger left it (iOS), parts sent off now would jump
  /// there; they sit that swipe out.
  static bool _exitRestartsWhenLetGo(BuildContext context) {
    final theme = Theme.of(context);
    return theme.pageTransitionsTheme.builders[theme.platform]
        is PredictiveBackPageTransitionsBuilder;
  }
}

/// A part of a screen that the row does not show: an email address and the actions at
/// its head, the sections under it. It keeps out of the way of the parts that travel
/// ([EntityHero]): it fades in as they land and is gone before they have left, so they
/// never pass over it.
///
/// It follows the screen's own transition, so a screen opened without one (by a link) shows
/// it at once. While a back swipe is dragged it stays, as the screen follows the finger
/// whole; when the swipe is let go it goes first, as for the back button.
class EntityHeroFollower extends StatelessWidget {
  const EntityHeroFollower({super.key, required this.tag, required this.child});

  /// The [EntityHero.tag] of the parts it waits for. Null when nothing travels.
  final Object? tag;
  final Widget child;

  static final Animatable<double> _afterLanding = CurveTween(
    curve: AppMotion.afterSharedElements,
  );

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final transition = route?.animation;
    final navigator = route?.navigator;
    if (tag == null ||
        transition == null ||
        navigator == null ||
        MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final backSwipe = navigator.userGestureInProgressNotifier;
    final afterLanding = transition.drive(_afterLanding);
    return ListenableBuilder(
      listenable: Listenable.merge([backSwipe, transition]),
      builder: (context, child) {
        // A back swipe moves the screen's transition with the finger, and nothing travels
        // until it is let go. From then on the screen's exit is playing.
        final isDragged =
            backSwipe.value && transition.status != AnimationStatus.reverse;
        return FadeTransition(
          opacity: isDragged ? kAlwaysCompleteAnimation : afterLanding,
          child: child,
        );
      },
      child: child,
    );
  }
}
