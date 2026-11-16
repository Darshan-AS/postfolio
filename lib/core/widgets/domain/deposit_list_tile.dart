import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/double_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/layout/entity_list_tile.dart';
import 'package:postfolio/i18n/strings.g.dart';

/// The avatar shape that stands for each scheme, so a scheme is recognisable by outline as
/// well as by its short code.
extension OneTimeSchemeAvatarShape on OneTimeSchemeType {
  AppAvatarShape get avatarShape => switch (this) {
    OneTimeSchemeType.timeDeposit => AppAvatarShape.cookie4,
    OneTimeSchemeType.monthlyIncomeScheme => AppAvatarShape.clover4,
    OneTimeSchemeType.nationalSavingsCertificate => AppAvatarShape.pentagon,
    OneTimeSchemeType.kisanVikasPatra => AppAvatarShape.sunny,
  };
}

extension RecurringSchemeAvatarShape on RecurringSchemeType {
  AppAvatarShape get avatarShape => switch (this) {
    RecurringSchemeType.recurringDeposit => AppAvatarShape.cookie12,
  };
}

/// A deposit row for list screens: scheme avatar, holder and account, then the amount,
/// maturity date and status on the trailing side. Deposits that have matured or are about
/// to are marked with a coloured bar and a countdown line.
///
/// One-time and recurring deposits share this row; they differ in the avatar and in which
/// amount they show.
class DepositListTile extends StatelessWidget {
  const DepositListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.avatarText,
    this.avatarSubtext,
    required this.avatarShape,
    required this.avatarBackgroundColor,
    required this.avatarForegroundColor,
    required this.amount,
    required this.amountColor,
    required this.status,
    required this.urgency,
    required this.relativeTimeText,
    required this.maturityDate,
    this.position = AppGroupPosition.single,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
  });

  final String title;
  final String subtitle;
  final String avatarText;
  final String? avatarSubtext;
  final AppAvatarShape avatarShape;
  final Color avatarBackgroundColor;
  final Color avatarForegroundColor;
  final double amount;
  final Color amountColor;
  final DepositStatus status;
  final MaturityUrgency urgency;
  final String relativeTimeText;
  final DateTime maturityDate;
  final AppGroupPosition position;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);

    final needsAttention =
        urgency == MaturityUrgency.maturingSoon ||
        urgency == MaturityUrgency.matured;
    final attentionColor = urgency == MaturityUrgency.matured
        ? scheme.error
        : scheme.tertiary;
    final Color? indicatorColor = switch (urgency) {
      MaturityUrgency.matured => scheme.error,
      MaturityUrgency.maturingSoon => scheme.tertiary,
      _ => null,
    };

    return EntityListTile(
      position: position,
      indicatorColor: indicatorColor,
      leadingText: avatarText,
      leadingSubtext: avatarSubtext,
      leadingShape: avatarShape,
      leadingBackgroundColor: avatarBackgroundColor,
      leadingForegroundColor: avatarForegroundColor,
      title: title,
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppDimensions.paddingXs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (needsAttention) ...[
              if (subtitle.isNotEmpty) AppSpacings.gapXs,
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedTimer02,
                    size: AppDimensions.iconSm,
                    color: attentionColor,
                  ),
                  AppSpacings.gapXs,
                  // Wraps rather than being cut: beside the amount there is room for
                  // "Matured 14 …", which drops the word that says whether it is past.
                  Flexible(
                    child: Text(
                      relativeTimeText,
                      style: emphasized.bodySmall?.copyWith(
                        color: attentionColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      onTap: onTap,
      trailing: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount.toRupeeFormat(),
              style: emphasized.titleMedium?.copyWith(color: amountColor),
            ),
            AppSpacings.gapXs,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar01,
                  size: AppDimensions.iconSm,
                  color: scheme.onSurfaceVariant,
                ),
                AppSpacings.gapXs,
                Text(
                  maturityDate.toAppFormat(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            // Only a status that is not the usual one. The lists open filtered to Active,
            // so the badge was on every row; what is close to maturity is said by the
            // row's bar and the line under its title.
            if (status != DepositStatus.active) ...[
              AppSpacings.gapXs,
              StatusBadge(
                status: status.displayName,
                depositStatus: status,
                compact: true,
                urgency: urgency,
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (onToggleStatus != null)
          if (status == DepositStatus.active)
            EntityAction(
              label: t.common.closeDeposit,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                size: AppDimensions.iconMd,
              ),
              onTap: onToggleStatus!,
            )
          else if (status == DepositStatus.closed)
            EntityAction(
              label: t.common.reopenDeposit,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowTurnBackward,
                size: AppDimensions.iconMd,
              ),
              onTap: onToggleStatus!,
            ),
        if (onEdit != null) EntityAction.edit(onTap: onEdit!),
        if (onDelete != null) EntityAction.delete(onTap: onDelete!),
      ],
    );
  }
}
