import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/expressive/app_loading_indicator.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_display_status.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// How far a month is: the accounts whose installment for the month is settled (collected
/// and deposited) of the accounts due, as a bar. When the last one is settled the bar gives
/// way to the month's one statement that it is done, in the colours of a settled row.
///
/// The statement arrives with a motion only when the month becomes settled while it is on
/// screen. A month that is already settled when it is opened shows it plainly, and so does
/// a device set to remove animations.
///
/// Nothing is drawn for a month with no account due, nor for a past month that is settled:
/// that is what a past month is expected to be, and saying so on each would make the
/// statement ordinary.
class RDHubMonthProgress extends StatelessWidget {
  const RDHubMonthProgress({
    super.key,
    required this.month,
    required this.settled,
    required this.total,
    required this.isPast,
  });

  final DateTime month;
  final int settled;
  final int total;

  /// Whether [month] is before the current one.
  final bool isPast;

  /// The statement comes in from this much of its size.
  static const double _entranceScale = 0.9;

  @override
  Widget build(BuildContext context) {
    final isSettled = settled >= total;
    if (total == 0 || (isSettled && isPast)) return const SizedBox.shrink();

    final content = isSettled
        ? _Settled(key: const ValueKey('settled'), month: month)
        : _Bar(
            key: const ValueKey('bar'),
            month: month,
            settled: settled,
            total: total,
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageMargin,
        AppDimensions.paddingNone,
        AppDimensions.pageMargin,
        AppDimensions.paddingMd,
      ),
      child: MediaQuery.disableAnimationsOf(context)
          ? content
          : AnimatedSize(
              duration: AppMotion.effectsSlowDuration,
              curve: AppMotion.effectsSlowCurve,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: AppMotion.spatialDuration,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: const Interval(
                      0,
                      0.4,
                      curve: AppMotion.effectsCurve,
                    ),
                  ),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: _entranceScale, end: 1).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: AppMotion.spatialCurve,
                      ),
                    ),
                    child: child,
                  ),
                ),
                child: content,
              ),
            ),
    );
  }
}

String _monthName(DateTime month) =>
    DateFormat.MMMM(resolvedDateLocale()).format(month);

class _Bar extends StatelessWidget {
  const _Bar({
    super.key,
    required this.month,
    required this.settled,
    required this.total,
  });

  final DateTime month;
  final int settled;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = t.recurringDeposits.monthlyOperations.progress;

    return Semantics(
      container: true,
      label: strings.semantics(
        settled: settled,
        total: total,
        month: _monthName(month),
      ),
      excludeSemantics: true,
      child: Row(
        children: [
          // The flat track: a share that is done, and the wavy one never stops moving.
          Expanded(child: AppLinearProgress(value: settled / total)),
          AppSpacings.gapMd,
          Flexible(
            child: Text(
              strings.settledOf(settled: settled, total: total),
              style: AppTypography.emphasizedOf(
                context,
              ).labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _Settled extends StatelessWidget {
  const _Settled({super.key, required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = t.recurringDeposits.monthlyOperations.progress;
    final visual = RDInstallmentDisplayStatus.settled.visualOf(context);

    return Semantics(
      container: true,
      child: Material(
        color: visual.background,
        shape: AppShapes.rounded(AppShapes.extraLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          child: Row(
            children: [
              AppShapeAvatar(
                shape: AppAvatarShape.sunny,
                size: AppDimensions.avatarMd,
                backgroundColor: visual.foreground,
                foregroundColor: visual.background,
                child: const AppIcon(
                  HugeIcons.strokeRoundedTick02,
                  size: AppDimensions.iconMd,
                ),
              ),
              AppSpacings.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.settledTitle(month: _monthName(month)),
                      style: AppTypography.emphasizedOf(
                        context,
                      ).titleLarge?.copyWith(color: visual.foreground),
                    ),
                    Text(
                      strings.settledBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: visual.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
