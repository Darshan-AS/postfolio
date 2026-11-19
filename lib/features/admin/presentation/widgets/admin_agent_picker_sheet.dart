import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/theme/app_shapes.dart';
import 'package:postfolio/core/theme/app_typography.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/core/widgets/expressive/app_group.dart';
import 'package:postfolio/core/widgets/expressive/app_shape_avatar.dart';
import 'package:postfolio/core/widgets/feedback/app_adaptive_sheet.dart';
import 'package:postfolio/core/widgets/feedback/app_sheet_header.dart';
import 'package:postfolio/core/widgets/feedback/error_state_view.dart';
import 'package:postfolio/core/widgets/forms/app_search_bar.dart';
import 'package:postfolio/features/admin/domain/agent_profile.dart';
import 'package:postfolio/features/admin/presentation/controllers/acting_as_controller.dart';
import 'package:postfolio/features/auth/domain/auth_state.dart';
import 'package:postfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:postfolio/i18n/strings.g.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Adaptive sheet (bottom sheet on mobile, dialog on desktop) letting an admin search
/// and choose an agent portfolio to view or act as.
class AdminAgentPickerSheet extends HookConsumerWidget {
  const AdminAgentPickerSheet({super.key});

  static const double _maxHeightFraction = 0.78;
  static const int _skeletonCount = 4;

  static Future<void> show(BuildContext context) {
    return AppAdaptiveSheet.show<void>(
      context,
      builder: (_) => const AdminAgentPickerSheet(),
    );
  }

  Future<void> _selectAgent(
    BuildContext context,
    WidgetRef ref,
    AgentProfile agent, {
    required bool isOwnAccount,
  }) async {
    final navigator = Navigator.of(context);
    final router = GoRouter.maybeOf(context);
    final controller = ref.read(actingAsControllerProvider.notifier);

    if (isOwnAccount) {
      await controller.stopActingAs();
    } else {
      await controller.startActingAs(agent);
    }

    if (navigator.canPop()) {
      navigator.pop();
    }
    if (router != null) {
      router.go(const DashboardRoute().location);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final agentsAsync = ref.watch(adminAgentsListProvider);
    final effectiveAgentId = ref.watch(effectiveAgentIdProvider);
    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState is AuthStateAuthenticated
        ? authState.user.id
        : null;

    final maxHeight = MediaQuery.sizeOf(context).height * _maxHeightFraction;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pageMargin,
              ),
              child: AppSheetHeader(title: t.admin.pickerTitle),
            ),
            AppSpacings.gapMd,
            AppSearchBar(
              query: searchQuery.value,
              hintText: t.admin.searchAgentsHint,
              onChanged: (value) => searchQuery.value = value,
            ),
            AppSpacings.gapMd,
            Flexible(
              child: switch (agentsAsync) {
                AsyncLoading() => const _AgentListSkeleton(),
                AsyncError() => SingleChildScrollView(
                  child: ErrorStateView(
                    message: t.admin.loadAgentsError,
                    onRetry: () => ref.invalidate(adminAgentsListProvider),
                  ),
                ),
                AsyncData(:final value) => switch (value) {
                  Failure(:final error) => SingleChildScrollView(
                    child: ErrorStateView(
                      message: error.trim().isNotEmpty
                          ? error
                          : t.admin.loadAgentsError,
                      onRetry: () => ref.invalidate(adminAgentsListProvider),
                    ),
                  ),
                  Success(:final value) => _buildAgentList(
                    context,
                    ref,
                    agents: value,
                    query: searchQuery.value,
                    currentUserId: currentUserId,
                    effectiveAgentId: effectiveAgentId,
                    onClearSearch: () => searchQuery.value = '',
                  ),
                },
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentList(
    BuildContext context,
    WidgetRef ref, {
    required List<AgentProfile> agents,
    required String query,
    required String? currentUserId,
    required String? effectiveAgentId,
    required VoidCallback onClearSearch,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final hasOtherAgents = agents.any((a) => a.id != currentUserId);

    if (agents.isEmpty || (!hasOtherAgents && normalizedQuery.isEmpty)) {
      return SingleChildScrollView(
        child: EmptyStateView(
          message: t.admin.noOtherAgents,
          icon: HugeIcons.strokeRoundedUserMultiple,
        ),
      );
    }

    final filtered = normalizedQuery.isEmpty
        ? [...agents]
        : agents.where((agent) {
            final haystacks = [
              agent.displayLabel,
              agent.name,
              agent.email,
              agent.agencyCode,
            ];
            return haystacks.any(
              (field) =>
                  field != null &&
                  field.toLowerCase().contains(normalizedQuery),
            );
          }).toList();

    // Place the admin's own account first in O(N) while strictly preserving backend order.
    if (currentUserId != null) {
      final selfIdx = filtered.indexWhere((a) => a.id == currentUserId);
      if (selfIdx > 0) {
        filtered.insert(0, filtered.removeAt(selfIdx));
      }
    }

    if (filtered.isEmpty) {
      return SingleChildScrollView(
        child: EmptyStateView(
          message: t.admin.noOtherAgents,
          icon: HugeIcons.strokeRoundedSearchRemove,
          actionLabel: t.common.clearFilters,
          actionIcon: HugeIcons.strokeRoundedFilterRemove,
          onAction: onClearSearch,
        ),
      );
    }

    return AppGroupListView(
      itemCount: filtered.length,
      bottomPadding: AppDimensions.paddingLg,
      itemBuilder: (context, index, position) {
        final agent = filtered[index];
        final isOwnAccount = currentUserId != null && agent.id == currentUserId;
        final isActive =
            effectiveAgentId != null && agent.id == effectiveAgentId;

        return _AgentRow(
          agent: agent,
          position: position,
          isOwnAccount: isOwnAccount,
          isActive: isActive,
          onTap: () =>
              _selectAgent(context, ref, agent, isOwnAccount: isOwnAccount),
        );
      },
    );
  }
}

class _AgentRow extends StatelessWidget {
  const _AgentRow({
    required this.agent,
    required this.position,
    required this.isOwnAccount,
    required this.isActive,
    this.onTap,
  });

  final AgentProfile agent;
  final AppGroupPosition position;
  final bool isOwnAccount;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final emphasized = AppTypography.emphasizedOf(context);
    final largeText = AppDimensions.isLargeText(context);

    final label = agent.displayLabel;
    final initial = label.isNotEmpty ? label[0].toUpperCase() : '?';
    final supporting = agent.supportingLabel;

    final titleColor = isActive
        ? scheme.onSecondaryContainer
        : scheme.onSurface;
    final subtitleColor = isActive
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;

    final badges = <Widget>[
      if (isOwnAccount)
        _AccountBadge(
          label: t.admin.yourAccountBadge,
          backgroundColor: isActive
              ? scheme.surface.withValues(alpha: 0.7)
              : scheme.surfaceContainerHighest,
          foregroundColor: isActive
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
        ),
      if (isActive)
        _AccountBadge(
          label: t.admin.currentAccountBadge,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
    ];

    return AppGroupTile(
      position: position,
      selected: isActive,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.rowMinHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLg,
            vertical: AppDimensions.paddingMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppShapeAvatar(
                    size: AppDimensions.avatarMd,
                    shape: AppAvatarShape.forPerson(label),
                    backgroundColor: isActive
                        ? scheme.primary
                        : scheme.primaryContainer,
                    foregroundColor: isActive
                        ? scheme.onPrimary
                        : scheme.onPrimaryContainer,
                    child: Text(initial, style: emphasized.titleMedium),
                  ),
                  AppSpacings.gapLg,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: emphasized.titleMedium?.copyWith(
                            color: titleColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!largeText && supporting != null) ...[
                          AppSpacings.gapXxs,
                          Text(
                            supporting,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subtitleColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!largeText && badges.isNotEmpty) ...[
                    AppSpacings.gapSm,
                    Wrap(
                      spacing: AppDimensions.paddingXs,
                      runSpacing: AppDimensions.paddingXs,
                      children: badges,
                    ),
                  ],
                  if (isActive) ...[
                    AppSpacings.gapSm,
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedTick02,
                      size: AppDimensions.iconMd,
                      color: scheme.onSecondaryContainer,
                    ),
                  ],
                ],
              ),
              if (largeText && supporting != null) ...[
                AppSpacings.gapXs,
                Text(
                  supporting,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subtitleColor,
                  ),
                ),
              ],
              if (largeText && badges.isNotEmpty) ...[
                AppSpacings.gapXs,
                Wrap(
                  spacing: AppDimensions.paddingXs,
                  runSpacing: AppDimensions.paddingXs,
                  children: badges,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountBadge extends StatelessWidget {
  const _AccountBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm,
        vertical: AppDimensions.paddingXs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppShapes.extraExtraLarge),
      ),
      child: Text(
        label,
        style: AppTypography.emphasizedOf(
          context,
        ).labelSmall?.copyWith(color: foregroundColor),
      ),
    );
  }
}

class _AgentListSkeleton extends StatelessWidget {
  const _AgentListSkeleton();

  static const _placeholder = AgentProfile(
    id: 'placeholder-agent',
    name: 'Aarav Kulkarni',
    email: 'agent@postfolio.dev',
    agencyCode: 'AG-1042',
  );

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: AppGroupListView(
        itemCount: AdminAgentPickerSheet._skeletonCount,
        bottomPadding: AppDimensions.paddingLg,
        itemBuilder: (context, index, position) => _AgentRow(
          agent: _placeholder,
          position: position,
          isOwnAccount: false,
          isActive: false,
        ),
      ),
    );
  }
}
