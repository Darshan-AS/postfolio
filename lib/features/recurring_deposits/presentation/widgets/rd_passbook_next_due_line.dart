import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_installment_model.dart';
import 'package:postfolio/features/recurring_deposits/presentation/widgets/rd_installment_status_theme.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// Compact "Next due" line at the top of the passbook with the single **Collect** CTA.
///
/// [nextDue] is the earliest month the customer still owes on; when `null` the account
/// is fully paid and the line turns into an "all settled" note.
class RDPassbookNextDueLine extends StatelessWidget {
  final RDInstallment? nextDue;
  final DateTime now;
  final bool isBusy;
  final VoidCallback onCollect;

  const RDPassbookNextDueLine({
    super.key,
    required this.nextDue,
    required this.now,
    required this.isBusy,
    required this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final passbook = t.recurringDeposits.ledger.passbook;
    final inst = nextDue;

    if (inst == null) {
      return Card(
        elevation: 0,
        color: scheme.tertiaryContainer,
        child: ListTile(
          leading: HugeIcon(
            icon: HugeIcons.strokeRoundedCheckmarkBadge01,
            size: AppDimensions.iconMd,
            color: scheme.onTertiaryContainer,
          ),
          title: Text(
            passbook.allSettled,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onTertiaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            passbook.allSettledHint,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onTertiaryContainer),
          ),
        ),
      );
    }

    final visual = inst.displayStatusAt(now).visual(scheme);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMd,
          vertical: AppDimensions.paddingSm,
        ),
        child: Row(
          children: [
            HugeIcon(icon: visual.icon, size: AppDimensions.iconMd, color: visual.foreground),
            AppSpacings.gapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passbook.nextDue,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    passbook.nextDueLine(
                      month: inst.installmentNo.toString(),
                      date: inst.dueDate.toAppFormat(),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    inst.outstandingAmount.toRupeeFormat(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: visual.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacings.gapSm,
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppDimensions.minTapTarget),
              ),
              onPressed: isBusy ? null : onCollect,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCoins01,
                size: AppDimensions.iconSm,
              ),
              label: Text(passbook.collect),
            ),
          ],
        ),
      ),
    );
  }
}
