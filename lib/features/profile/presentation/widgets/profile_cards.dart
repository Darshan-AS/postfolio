import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_financial_colors.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/features/admin/domain/acting_as_state.dart';
import 'package:postfolio/features/profile/domain/agent_profile.dart';
import 'package:postfolio/i18n/strings.g.dart';

class AdminSwitchCard extends StatelessWidget {
  const AdminSwitchCard({
    super.key,
    required this.actingAs,
    required this.onTap,
  });

  final ActingAsState actingAs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isActingAs = actingAs is ActingAsStateActive;
    final containerColor = isActingAs
        ? scheme.tertiaryContainer
        : scheme.secondaryContainer;
    final onContainerColor = isActingAs
        ? scheme.onTertiaryContainer
        : scheme.onSecondaryContainer;
    final avatarBg = isActingAs ? scheme.tertiary : scheme.secondary;
    final avatarFg = isActingAs ? scheme.onTertiary : scheme.onSecondary;

    final title = switch (actingAs) {
      ActingAsStateActive(:final targetAgent) => t.admin.actingAs(
        name: targetAgent.displayLabel,
      ),
      ActingAsStateNone() => t.admin.switchAccount,
    };
    final subtitle = isActingAs
        ? t.settings.actingAsProfileNote
        : t.settings.switchAccountSubtitle;

    return AppGroupTile(
      key: const ValueKey('admin_switch_account_button'),
      position: AppGroupPosition.single,
      color: containerColor,
      onTap: onTap,
      child: MetaData(
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Row(
            children: [
              AppShapeAvatar(
                shape: AppAvatarShape.softBurst,
                size: AppDimensions.iconXl,
                backgroundColor: avatarBg,
                foregroundColor: avatarFg,
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUserSwitch,
                  size: AppDimensions.iconMd,
                ),
              ),
              AppSpacings.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.emphasizedOf(
                        context,
                      ).bodyLarge?.copyWith(color: onContainerColor),
                    ),
                    AppSpacings.gapXxs,
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onContainerColor,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacings.gapSm,
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: AppDimensions.iconMd,
                color: onContainerColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileLicenseTile extends StatelessWidget {
  const ProfileLicenseTile({
    super.key,
    required this.title,
    required this.licenseNo,
    required this.validUntil,
    required this.today,
  });

  final String title;
  final String? licenseNo;
  final DateTime? validUntil;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);
    final financial = AppFinancialColors.of(context);
    final status = AgentProfile.licenseStatusAt(validUntil, today);
    final daysRemaining = AgentProfile.licenseDaysRemainingAt(
      validUntil,
      today,
    );

    final palette = switch (status) {
      LicenseValidityStatus.valid => financial.settled,
      LicenseValidityStatus.expiringSoon => financial.warning,
      LicenseValidityStatus.expired => financial.overdue,
      null => null,
    };

    final hasLicenseNo = licenseNo != null && licenseNo!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShapeAvatar(
            shape: AppAvatarShape.neutral,
            size: AppDimensions.iconXl,
            backgroundColor: palette?.container ?? scheme.primaryContainer,
            foregroundColor: palette?.onContainer ?? scheme.onPrimaryContainer,
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedId,
              size: AppDimensions.iconMd,
            ),
          ),
          AppSpacings.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: AppDimensions.paddingSm,
                  runSpacing: AppDimensions.paddingXs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(title, style: emphasized.titleSmall),
                    if (status != null) LicenseValidityBadge(status: status),
                  ],
                ),
                if (hasLicenseNo) ...[
                  AppSpacings.gapXs,
                  Row(
                    children: [
                      Expanded(
                        child: Text(licenseNo!, style: emphasized.bodyLarge),
                      ),
                      IconButton(
                        tooltip: t.common.copy,
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedCopy01,
                          size: AppDimensions.iconSm,
                          color: scheme.primary,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: licenseNo!));
                          AppFeedback.showSuccess(
                            context,
                            t.common.copiedToClipboard,
                          );
                        },
                      ),
                    ],
                  ),
                ],
                if (validUntil != null && daysRemaining != null) ...[
                  AppSpacings.gapXs,
                  Text(
                    '${t.settings.licenseValidUntil(date: validUntil!.toAppFormat())} • ${_formatRelativeDays(daysRemaining)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatRelativeDays(int daysRemaining) {
    if (daysRemaining == 0) return t.settings.licenseExpiresToday;
    if (daysRemaining == 1) return t.settings.licenseDayLeft;
    if (daysRemaining > 1) {
      return t.settings.licenseDaysLeft(count: daysRemaining);
    }
    if (daysRemaining == -1) return t.settings.licenseExpiredDayAgo;
    return t.settings.licenseExpiredDaysAgo(count: -daysRemaining);
  }
}

class ProfilePill extends StatelessWidget {
  const ProfilePill({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMd,
        vertical: AppDimensions.paddingXs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppShapes.extraExtraLarge),
      ),
      child: Text(
        label,
        style: AppTypography.emphasizedOf(context).labelMedium?.copyWith(
          color: foregroundColor ?? scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class LicenseValidityBadge extends StatelessWidget {
  const LicenseValidityBadge({super.key, required this.status});

  final LicenseValidityStatus status;

  @override
  Widget build(BuildContext context) {
    final financial = AppFinancialColors.of(context);
    final (palette, label) = switch (status) {
      LicenseValidityStatus.valid => (
        financial.settled,
        t.settings.licenseValid,
      ),
      LicenseValidityStatus.expiringSoon => (
        financial.warning,
        t.settings.licenseExpiringSoon,
      ),
      LicenseValidityStatus.expired => (
        financial.overdue,
        t.settings.licenseExpired,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.paddingXs,
      ),
      decoration: BoxDecoration(
        color: palette.container,
        borderRadius: BorderRadius.circular(AppShapes.extraExtraLarge),
      ),
      child: Text(
        label,
        style: AppTypography.emphasizedOf(
          context,
        ).labelSmall?.copyWith(color: palette.onContainer),
      ),
    );
  }
}
