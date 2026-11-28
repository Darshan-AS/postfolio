import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/constants/app_info.dart';
import 'package:postfolio/core/enums/start_tab.dart';
import 'package:postfolio/core/env/env.dart';
import 'package:postfolio/core/providers/app_preferences_provider.dart';
import 'package:postfolio/core/providers/theme_provider.dart';
import 'package:postfolio/core/services/intent_service.dart';
import 'package:postfolio/core/services/storage_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_button_group.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/app_sheet_header.dart';
import 'package:postfolio/core/widgets/layout/app_bar_title.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/one_time_deposits/presentation/controllers/one_time_deposits_controller.dart';
import 'package:postfolio/features/recurring_deposits/presentation/controllers/recurring_deposits_controller.dart';
import 'package:postfolio/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:postfolio/i18n/strings.g.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final prefs = ref.watch(appPreferencesProvider);
    final isAccessibleTheme = themeMode == AppThemeMode.accessibleSystem;

    return Scaffold(
      appBar: AppBar(title: AppBarTitle(t.settings.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pageMargin,
            AppDimensions.paddingSm,
            AppDimensions.pageMargin,
            AppDimensions.paddingXl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.maxFormWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DetailSectionTitle(t.settings.appearanceSection),
                  SettingsGroup(
                    itemBuilders: [
                      (position) => AppGroupTile(
                        position: position,
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppDimensions.paddingLg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                t.common.theme.title,
                                style: AppTypography.emphasizedOf(
                                  context,
                                ).bodyLarge,
                              ),
                              AppSpacings.gapMd,
                              AppButtonGroup<AppThemeMode>(
                                selected: themeMode,
                                onChanged: (mode) => ref
                                    .read(themeModeProvider.notifier)
                                    .setThemeMode(mode),
                                segments: [
                                  AppSegment(
                                    value: AppThemeMode.system,
                                    label: t.settings.themeSystemShort,
                                  ),
                                  AppSegment(
                                    value: AppThemeMode.light,
                                    label: t.settings.themeLightShort,
                                  ),
                                  AppSegment(
                                    value: AppThemeMode.dark,
                                    label: t.settings.themeDarkShort,
                                  ),
                                  AppSegment(
                                    value: AppThemeMode.accessibleSystem,
                                    label: t.settings.themeAccessibleShort,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      (position) => SettingsSwitchRow(
                        key: const ValueKey('settings_dynamic_color_switch'),
                        position: position,
                        icon: HugeIcons.strokeRoundedEye,
                        title: t.settings.dynamicColorTitle,
                        subtitle: isAccessibleTheme
                            ? t.settings.dynamicColorDisabledForContrast
                            : t.settings.dynamicColorSubtitle,
                        value: !isAccessibleTheme && prefs.useDynamicColor,
                        onChanged: isAccessibleTheme
                            ? null
                            : (value) => ref
                                  .read(appPreferencesProvider.notifier)
                                  .setUseDynamicColor(value),
                      ),
                    ],
                  ),
                  AppSpacings.gapLg,
                  DetailSectionTitle(t.settings.preferencesSection),
                  SettingsGroup(
                    itemBuilders: [
                      (position) => SettingsRow(
                        key: const ValueKey('settings_start_tab_row'),
                        position: position,
                        icon: HugeIcons.strokeRoundedHome01,
                        title: t.settings.defaultStartScreen,
                        subtitle: prefs.startTab.displayName,
                        showChevron: true,
                        onTap: () =>
                            _showStartTabSheet(context, ref, prefs.startTab),
                      ),
                      (position) => SettingsSwitchRow(
                        key: const ValueKey('settings_mask_ids_switch'),
                        position: position,
                        icon: HugeIcons.strokeRoundedLockKey,
                        title: t.settings.maskSensitiveIdsTitle,
                        subtitle: t.settings.maskSensitiveIdsSubtitle,
                        value: prefs.maskSensitiveIds,
                        onChanged: (value) => ref
                            .read(appPreferencesProvider.notifier)
                            .setMaskSensitiveIds(value),
                      ),
                      (position) => SettingsSwitchRow(
                        key: const ValueKey('settings_haptics_switch'),
                        position: position,
                        icon: HugeIcons.strokeRoundedSmartPhone01,
                        title: t.settings.hapticsTitle,
                        subtitle: t.settings.hapticsSubtitle,
                        value: prefs.hapticsEnabled,
                        onChanged: (value) => ref
                            .read(appPreferencesProvider.notifier)
                            .setHapticsEnabled(value),
                      ),
                      (position) => SettingsRow(
                        key: const ValueKey('settings_reset_filters_row'),
                        position: position,
                        icon: HugeIcons.strokeRoundedFilterRemove,
                        title: t.settings.resetFiltersTitle,
                        subtitle: t.settings.resetFiltersSubtitle,
                        onTap: () async {
                          await ref
                              .read(storageServiceProvider)
                              .clearListCriteria();
                          ref.invalidate(customerListCriteriaProvider);
                          ref.invalidate(oneTimeListCriteriaProvider);
                          ref.invalidate(recurringListCriteriaProvider);
                          if (context.mounted) {
                            AppFeedback.showSuccess(
                              context,
                              t.settings.filtersResetSuccess,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  AppSpacings.gapLg,
                  DetailSectionTitle(t.settings.supportSection),
                  SettingsGroup(
                    itemBuilders: [
                      (position) => SettingsRow(
                        key: const ValueKey('settings_contact_support_row'),
                        position: position,
                        icon: HugeIcons.strokeRoundedMail01,
                        title: t.settings.contactSupportTitle,
                        subtitle: t.settings.contactSupportSubtitle,
                        showChevron: true,
                        onTap: () => ref
                            .read(intentServiceProvider)
                            .launchSupportEmail(
                              to: AppInfo.supportEmail,
                              subject: t.settings.supportEmailSubject(
                                version: AppInfo.displayVersion,
                              ),
                              body: t.settings.supportEmailBody(
                                platform: defaultTargetPlatform.name,
                                version: AppInfo.fullVersion,
                              ),
                            ),
                      ),
                      (position) => SettingsRow(
                        key: const ValueKey('settings_privacy_policy_row'),
                        position: position,
                        icon: HugeIcons.strokeRoundedFile01,
                        title: t.settings.privacyPolicy,
                        showChevron: true,
                        onTap: () => ref
                            .read(intentServiceProvider)
                            .launchExternalUrl(AppInfo.privacyPolicyUrl),
                      ),
                      (position) => SettingsRow(
                        key: const ValueKey('settings_licenses_row'),
                        position: position,
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        title: t.settings.openSourceLicenses,
                        showChevron: true,
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: t.appTitle,
                          applicationVersion: AppInfo.displayVersion,
                          applicationIcon: Padding(
                            padding: const EdgeInsets.all(
                              AppDimensions.paddingSm,
                            ),
                            child: Image.asset(
                              AppConstants.appLogoMarkAsset,
                              width: AppDimensions.avatarMd,
                              height: AppDimensions.avatarMd,
                            ),
                          ),
                        ),
                      ),
                      (position) => SettingsRow(
                        key: const ValueKey('settings_version_row'),
                        position: position,
                        icon: HugeIcons.strokeRoundedTag01,
                        title: t.settings.appVersion,
                        subtitle: Env.isLocalBackend
                            ? '${AppInfo.displayVersion} • ${t.settings.localBackendTag}'
                            : AppInfo.displayVersion,
                        trailing: IconButton(
                          key: const ValueKey('settings_copy_version_button'),
                          tooltip: t.common.copy,
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedCopy01,
                            size: AppDimensions.iconSm,
                            color: scheme.primary,
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              const ClipboardData(text: AppInfo.fullVersion),
                            );
                            AppFeedback.showSuccess(
                              context,
                              t.common.copiedToClipboard,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  AppSpacings.gapLg,
                  Text(
                    t.settings.independentDisclaimer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showStartTabSheet(
    BuildContext context,
    WidgetRef ref,
    AppStartTab current,
  ) {
    return AppAdaptiveSheet.show<void>(
      context,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pageMargin,
            0,
            AppDimensions.pageMargin,
            AppDimensions.paddingLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSheetHeader(title: t.settings.defaultStartScreen),
              AppSpacings.gapMd,
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < AppStartTab.values.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppShapes.groupGap),
                    StartTabOptionTile(
                      tab: AppStartTab.values[i],
                      selected: AppStartTab.values[i] == current,
                      position: AppGroupPosition.at(
                        i,
                        AppStartTab.values.length,
                      ),
                      onTap: () {
                        ref
                            .read(appPreferencesProvider.notifier)
                            .setStartTab(AppStartTab.values[i]);
                        Navigator.of(sheetCtx).pop();
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
