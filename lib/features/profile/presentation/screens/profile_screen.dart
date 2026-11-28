import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/constants/app_constants.dart';
import 'package:postfolio/core/enums/agency_type.dart';
import 'package:postfolio/core/extensions/date_time_extension.dart';
import 'package:postfolio/core/extensions/string_extension.dart';
import 'package:postfolio/core/providers/app_preferences_provider.dart';
import 'package:postfolio/core/providers/clock_provider.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/services/intent_service.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_motion.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/widgets/expressive/app_button.dart';
import 'package:postfolio/core/widgets/expressive/app_refresh_indicator.dart';
import 'package:postfolio/core/widgets/feedback/app_dialogs.dart';
import 'package:postfolio/core/widgets/feedback/app_feedback.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/core/widgets/layout/app_bar_title.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/core/widgets/layout/entity_detail_scaffold.dart';
import 'package:postfolio/core/widgets/layout/entity_hero.dart';
import 'package:postfolio/features/admin/presentation/controllers/acting_as_controller.dart';
import 'package:postfolio/features/admin/presentation/widgets/admin_agent_picker_sheet.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/domain/auth_user.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/features/profile/domain/agent_profile.dart';
import 'package:postfolio/features/profile/presentation/controllers/profile_controller.dart';
import 'package:postfolio/features/profile/presentation/widgets/agent_avatar.dart';
import 'package:postfolio/features/profile/presentation/widgets/profile_cards.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.openedFrom});

  /// Where the [AgentAvatarButton] that opened this screen sits (`EntityHero.tagFrom`).
  final String? openedFrom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroTag = EntityHero.tagFrom(openedFrom, AppConstants.selfHeroId);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final authState = ref.watch(authControllerProvider);
    final AuthUser? authUser = switch (authState) {
      AuthStateAuthenticated(:final user) => user,
      _ => null,
    };
    final profileAsync = ref.watch(profileControllerProvider);
    final profile = profileAsync.value;
    final isDemoMode = ref.watch(demoModeProvider);
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final actingAs = ref.watch(actingAsControllerProvider);
    final maskSensitiveIds = ref.watch(
      appPreferencesProvider.select((p) => p.maskSensitiveIds),
    );
    final today = ref.watch(currentDateProvider);

    Future<void> refresh() async {
      ref.invalidate(profileControllerProvider);
      ref.invalidate(isAdminProvider);
      await Future.wait([
        ref.read(profileControllerProvider.future),
        ref.read(isAdminProvider.future),
      ]);
    }

    if (profileAsync.hasError && !profileAsync.hasValue) {
      return Scaffold(
        appBar: _buildAppBar(context, scheme),
        body: ErrorStateView(
          message: profileAsync.error.toString(),
          onRetry: refresh,
        ),
      );
    }

    final effective = AgentProfile.effectiveFrom(profile, authUser);
    final displayName = effective.resolveDisplayName(fallbackUser: authUser);
    final email = effective.email?.trim();
    final phone = effective.phone?.trim();
    final initial = effective.resolveInitial(fallbackUser: authUser);
    final photoUrl = isDemoMode ? null : authUser?.photoUrl?.trim();
    final roleBadge = isDemoMode
        ? t.settings.profileFields.roleDemo
        : (isAdmin ? t.settings.profileFields.roleAdmin : null);
    final isLoading = profileAsync.isLoading && !profileAsync.hasValue;
    final viewProfile = isLoading
        ? AgentProfile(
            id: effective.id,
            name: displayName,
            phone: phone,
            email: email,
            agencyCode: effective.agencyCode ?? 'DOP123456',
            postOfficeBranch: effective.postOfficeBranch ?? 'Head Post Office',
            agencyTypes: effective.agencyTypes.isNotEmpty
                ? effective.agencyTypes
                : const [AgencyType.mpkby],
            mpkbyLicenseNo: effective.mpkbyLicenseNo ?? 'MPKBY-0000',
            mpkbyValidUntil: effective.mpkbyValidUntil ?? today,
            panNumber: effective.panNumber ?? 'ABCDE1234F',
          )
        : effective;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    final heroSubtitleText =
        viewProfile.agencySummaryLabel ??
        (email != null && email.isNotEmpty && email != displayName
            ? email
            : null);

    final header = EntityDetailHeader(
      heroTag: heroTag,
      avatarShape: AppAvatarShape.cookie9,
      avatarOpensFrom: heroTag == null ? AppAvatarShape.circle : null,
      avatarText: hasPhoto ? null : initial,
      avatarChild: hasPhoto
          ? AgentAvatarPhoto(
              initial: initial,
              photoUrl: photoUrl,
              textStyle: AppTypography.emphasizedOf(
                context,
              ).titleLarge?.copyWith(color: scheme.onPrimaryContainer),
            )
          : null,
      title: displayName,
      subtitle: heroSubtitleText == null
          ? null
          : Text(
              heroSubtitleText,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
      badge: roleBadge != null ? ProfilePill(label: roleBadge) : null,
      footer: viewProfile.agencyTypes.isNotEmpty
          ? Wrap(
              spacing: AppDimensions.paddingXs,
              runSpacing: AppDimensions.paddingXs,
              children: [
                for (final type in viewProfile.agencyTypes)
                  ProfilePill(
                    label: type.displayName,
                    backgroundColor: scheme.tertiaryContainer,
                    foregroundColor: scheme.onTertiaryContainer,
                  ),
              ],
            )
          : null,
      bottomActions: [
        if (isDemoMode) ...[
          AppButton.tonal(
            key: const ValueKey('settings_reset_demo_button'),
            label: t.common.reset,
            icon: HugeIcons.strokeRoundedRefresh,
            size: AppButtonSize.small,
            onPressed: () {
              ref.read(demoSessionEpochProvider.notifier).reset();
              AppFeedback.showSuccess(context, t.common.demoDataReset);
            },
          ),
          AppButton.outlined(
            key: const ValueKey('settings_exit_demo_button'),
            label: t.common.exitDemoMode,
            icon: HugeIcons.strokeRoundedLogout01,
            size: AppButtonSize.small,
            onPressed: () => ref.read(demoModeProvider.notifier).disable(),
          ),
        ],
      ],
    );

    final hasContactOrPersonal =
        (phone != null && phone.isNotEmpty) ||
        (email != null && email.isNotEmpty) ||
        (effective.address != null && effective.address!.trim().isNotEmpty) ||
        effective.dateOfBirth != null;

    final hasNotes =
        effective.notes != null && effective.notes!.trim().isNotEmpty;

    final sections = <Widget>[
      if (isAdmin && !isDemoMode) ...[
        AdminSwitchCard(
          actingAs: actingAs,
          onTap: () => AdminAgentPickerSheet.show(context),
        ),
        AppSpacings.gapLg,
      ],
      if (hasContactOrPersonal) ...[
        DetailSection(
          title: t.settings.profileFields.contactSection,
          children: [
            DetailItem(
              icon: const AppIcon(
                HugeIcons.strokeRoundedCall02,
                size: AppDimensions.iconMd,
              ),
              label: t.settings.profileFields.phone,
              value: phone?.toPhoneFormat(),
              copyValue: phone,
              hideIfNull: true,
            ),
            DetailItem(
              icon: const AppIcon(
                HugeIcons.strokeRoundedMail01,
                size: AppDimensions.iconMd,
              ),
              label: t.settings.profileFields.email,
              value: email,
              copyValue: email,
              hideIfNull: true,
            ),
            DetailItem(
              icon: const AppIcon(
                HugeIcons.strokeRoundedLocation01,
                size: AppDimensions.iconMd,
              ),
              label: t.settings.profileFields.address,
              value: effective.address?.trim(),
              hideIfNull: true,
              onTap:
                  (effective.address != null &&
                      effective.address!.trim().isNotEmpty)
                  ? () => ref
                        .read(intentServiceProvider)
                        .launchMapSearch(effective.address!.trim())
                  : null,
            ),
            DetailItem(
              icon: const AppIcon(
                HugeIcons.strokeRoundedCalendar01,
                size: AppDimensions.iconMd,
              ),
              label: t.settings.profileFields.dateOfBirth,
              value: effective.dateOfBirth?.toAppFormat(),
              hideIfNull: true,
            ),
          ],
        ),
        AppSpacings.gapLg,
      ],
      if (viewProfile.hasSharedAgencyDetails) ...[
        DetailSection(
          title: t.settings.profileFields.agencySection,
          children: [
            DetailItem(
              icon: const AppIcon(
                HugeIcons.strokeRoundedTicket01,
                size: AppDimensions.iconMd,
              ),
              label: t.settings.profileFields.dopAgentId,
              value: viewProfile.agencyCode?.trim(),
              copyValue: viewProfile.agencyCode?.trim(),
              hideIfNull: true,
            ),
            DetailItem(
              icon: const AppIcon(
                HugeIcons.strokeRoundedBuilding03,
                size: AppDimensions.iconMd,
              ),
              label: t.settings.profileFields.postOfficeBranch,
              value: viewProfile.postOfficeBranch?.trim(),
              copyValue: viewProfile.postOfficeBranch?.trim(),
              hideIfNull: true,
            ),
          ],
        ),
        AppSpacings.gapLg,
      ],
      if (viewProfile.hasLicenses) ...[
        _buildLicensesSection(viewProfile, today),
        AppSpacings.gapLg,
      ],
      if (viewProfile.hasKycOrCommissionDetails) ...[
        _buildKycSection(viewProfile, maskSensitiveIds: maskSensitiveIds),
        AppSpacings.gapLg,
      ],
      if (hasNotes) ...[
        DetailSection(
          title: t.settings.profileFields.notes,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLg,
                vertical: AppDimensions.paddingMd,
              ),
              child: Text(
                effective.notes!.trim(),
                style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
        AppSpacings.gapLg,
      ],
    ];

    // When arriving via an avatar Hero flight, `EntityHeroFollower` holds opacity at 0
    // until landing; skip the competing entrance stagger so motion does not race.
    final disableAnimations =
        heroTag != null || MediaQuery.disableAnimationsOf(context);
    final animatedSections = disableAnimations
        ? sections
        : sections
              .animate(interval: AppMotion.stagger)
              .fade(
                duration: AppMotion.effectsDuration,
                curve: AppMotion.effectsCurve,
              )
              .slideY(
                begin: AppMotion.slideOffset,
                end: 0,
                duration: AppMotion.spatialFastDuration,
                curve: AppMotion.spatialFastCurve,
              );

    return Scaffold(
      appBar: _buildAppBar(context, scheme),
      body: SelectionArea(
        child: SafeArea(
          child: AppRefreshIndicator(
            onRefresh: refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      header,
                      AppSpacings.gapXl,
                      EntityHeroFollower(
                        tag: heroTag,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Skeletonizer(
                              enabled: isLoading,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: animatedSections,
                              ),
                            ),
                            if (!isDemoMode) ...[
                              AppSpacings.gapSm,
                              AppButton.tonal(
                                key: const ValueKey('settings_sign_out_button'),
                                label: t.auth.signOut,
                                icon: HugeIcons.strokeRoundedLogout01,
                                isDestructive: true,
                                size: AppButtonSize.medium,
                                expand: true,
                                onPressed: () => _confirmSignOut(context, ref),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ColorScheme scheme) => AppBar(
    title: AppBarTitle(t.settings.profileTitle),
    actions: [
      IconButton.filledTonal(
        key: const ValueKey('profile_edit_button'),
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSecondaryContainer,
        ),
        tooltip: t.settings.editProfile,
        icon: const AppIcon(
          HugeIcons.strokeRoundedEdit02,
          size: AppDimensions.iconMd,
        ),
        onPressed: () => const ProfileEditRoute().push(context),
      ),
      IconButton(
        key: const ValueKey('profile_settings_button'),
        tooltip: t.settings.title,
        icon: const AppIcon(
          HugeIcons.strokeRoundedSettings01,
          size: AppDimensions.iconMd,
        ),
        onPressed: () => const SettingsRoute().push(context),
      ),
      const SizedBox(width: AppDimensions.paddingXs),
    ],
  );

  Widget _buildLicensesSection(AgentProfile profile, DateTime today) {
    final tiles = <Widget>[
      if (profile.hasMpkbyLicenseDetails)
        ProfileLicenseTile(
          key: const ValueKey('profile_mpkby_license_card'),
          title: AgencyType.mpkby.displayName,
          licenseNo: profile.mpkbyLicenseNo?.trim(),
          validUntil: profile.mpkbyValidUntil,
          today: today,
        ),
      if (profile.hasSasLicenseDetails)
        ProfileLicenseTile(
          key: const ValueKey('profile_sas_license_card'),
          title: AgencyType.sas.displayName,
          licenseNo: profile.sasLicenseNo?.trim(),
          validUntil: profile.sasValidUntil,
          today: today,
        ),
    ];

    return DetailSection(
      title: t.settings.profileFields.licensesSection,
      children: tiles,
    );
  }

  Widget _buildKycSection(
    AgentProfile profile, {
    required bool maskSensitiveIds,
  }) {
    final pan = profile.panNumber?.trim();
    final aadhaar = profile.aadhaarNumber?.trim();
    final sb = profile.commissionSbAccount?.trim();

    return DetailSection(
      title: t.settings.profileFields.kycSection,
      children: [
        DetailItem(
          icon: const AppIcon(
            HugeIcons.strokeRoundedCreditCard,
            size: AppDimensions.iconMd,
          ),
          label: t.settings.profileFields.panNumber,
          value: pan?.toPanFormat(),
          masked: maskSensitiveIds,
          maskedValue: pan?.toMaskedPanFormat(),
          copyValue: pan,
          hideIfNull: true,
        ),
        DetailItem(
          icon: const AppIcon(
            HugeIcons.strokeRoundedId,
            size: AppDimensions.iconMd,
          ),
          label: t.settings.profileFields.aadhaarNumber,
          value: aadhaar?.toAadhaarFormat(),
          masked: maskSensitiveIds,
          maskedValue: aadhaar?.toMaskedAadhaarFormat(),
          copyValue: aadhaar,
          hideIfNull: true,
        ),
        DetailItem(
          icon: const AppIcon(
            HugeIcons.strokeRoundedBank,
            size: AppDimensions.iconMd,
          ),
          label: t.settings.profileFields.commissionSbAccount,
          value: sb,
          copyValue: sb,
          hideIfNull: true,
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialogs.confirmAction(
      context,
      title: t.settings.signOutConfirmTitle,
      content: t.settings.signOutConfirmContent,
      confirmText: t.auth.signOut,
      isDestructive: true,
      icon: HugeIcons.strokeRoundedLogout01,
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}
