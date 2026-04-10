import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postfolio/core/routing/app_router.dart';
import 'package:postfolio/features/customers/presentation/controllers/customers_controller.dart';
import 'package:postfolio/features/customers/presentation/widgets/customer_card.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/error_state_view.dart';
import 'package:postfolio/core/utils/intent_service.dart';
import 'package:postfolio/i18n/strings.g.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the Controller state
    final customersState = ref.watch(customersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: Row(
          children: [
            Icon(
              Icons.groups_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            AppSpacings.gapSm,
            Text(
              t.nav.customers,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.check_box_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            // Trigger a manual refresh from the controller
            onPressed: () => ref.refresh(customersControllerProvider),
          ),
        ],
      ),
      // 2. Handle the AsyncValue UI states smoothly
      body: customersState.when(
        data: (customers) {
          if (customers.isEmpty) {
            return Center(child: Text(t.customers.noCustomersFound));
          }
          return RefreshIndicator(
            onRefresh: () async {
              // Trigger a manual refresh from the controller
              ref.invalidate(customersControllerProvider);
              await ref.read(customersControllerProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.only(
                bottom: AppDimensions.listBottomPaddingFAB,
              ),
              itemCount: customers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final customer = customers[index];
                return CustomerCard(
                  name: customer.name,
                  phone: customer.phone ?? t.common.notProvided,
                  onTap: () => CustomerDetailRoute(customer.id).push(context),
                  onEdit: () => CustomerEditRoute(customer.id).push(context),
                  onDelete: () {
                    // Call the controller directly to delete
                    ref
                        .read(customersControllerProvider.notifier)
                        .deleteCustomer(customer.id);
                  },
                  onPhoneTapped: () => ref
                      .read(intentServiceProvider)
                      .launchPhone(customer.phone ?? ''),
                  onWhatsAppTapped: () => ref
                      .read(intentServiceProvider)
                      .launchWhatsApp(customer.phone ?? ''),
                  onSmsTapped: () => ref
                      .read(intentServiceProvider)
                      .launchSms(customer.phone ?? ''),
                  onLocationTapped: () => ref
                      .read(intentServiceProvider)
                      .launchMapSearch(customer.name),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(customersControllerProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => const CustomerCreateRoute().push(context),
        icon: const Icon(Icons.add),
        label: Text(t.customers.newCustomer),
      ),
    );
  }
}
