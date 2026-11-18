import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/theme/app_motion.dart';

/// The parts of an entity that its row in a list and the head of its screen both show.
enum EntityHeroPart { avatar, title, subtitle }

/// A part of an entity that travels between its row in a list and the head of its screen
/// when the screen opens, and back when it is closed with the back button.
///
/// Give the row's copy and the screen's copy the same [tag] and [part]. It is the
/// framework's `Hero`: the screens keep their page transition, their URL and the back
/// swipe, and a screen opened without its row in view (by a link) opens as before.
///
/// What travels is the copy at the head of the screen, the larger of the two, scaled to
/// the box on its way. Laid out in a box of another size, a name would wrap or be cut.
class EntityHero extends StatelessWidget {
  const EntityHero({super.key, required this.tag, required this.part, required this.child});

  /// Identifies the entity. Null for a placeholder, which has nowhere to travel to.
  final Object? tag;
  final EntityHeroPart part;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tag = this.tag;
    // A device set to remove animations gets none.
    if (tag == null || MediaQuery.disableAnimationsOf(context)) return child;
    return Hero(tag: (tag, part), flightShuttleBuilder: _inFlight, child: child);
  }

  static Widget _inFlight(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    // The screen is the route on top: where a push goes to and where a pop comes from.
    final onScreen = direction == HeroFlightDirection.push ? toHeroContext : fromHeroContext;
    final size = (onScreen.findRenderObject()! as RenderBox).size;

    return FittedBox(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox.fromSize(
        size: size,
        // In flight the copy is drawn above both screens, where no `Material` gives text
        // its default style.
        child: Material(
          type: MaterialType.transparency,
          child: (onScreen.widget as Hero).child,
        ),
      ),
    );
  }
}

/// A part of the head of a screen that the row does not show: an email address, the
/// actions. It keeps out of the way of the parts that travel ([EntityHero]): it fades in as
/// they land and is gone before they have left, so they never pass over it.
///
/// It follows the screen's own transition, so a screen opened without one (by a link) shows
/// it at once. Like the parts that travel, it sits out a back swipe.
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

    return ValueListenableBuilder<bool>(
      // A back swipe moves the screen's transition with the finger, and nothing travels.
      valueListenable: navigator.userGestureInProgressNotifier,
      builder: (context, isBackSwipe, child) => FadeTransition(
        opacity: isBackSwipe ? kAlwaysCompleteAnimation : transition.drive(_afterLanding),
        child: child,
      ),
      child: child,
    );
  }
}
