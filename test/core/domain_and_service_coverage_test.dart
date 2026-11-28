import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:postfolio/core/enums/deposit_status.dart';
import 'package:postfolio/core/enums/maturity_urgency.dart';
import 'package:postfolio/core/enums/scheme_type.dart';
import 'package:postfolio/core/enums/sort_direction.dart';
import 'package:postfolio/core/services/intent_service.dart';
import 'package:postfolio/core/theme/app_theme.dart';
import 'package:postfolio/core/widgets/feedback/async_entity_builder.dart';
import 'package:postfolio/features/one_time_deposits/domain/otd_search_criteria.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_search_criteria.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_step_track.dart';
import 'package:postfolio/i18n/strings.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OTDSearchCriteria & RDSearchCriteria', () {
    test('OTDSortField exposes labels and asc/desc direction labels', () {
      expect(
        OTDSortField.maturityDate.label,
        t.sorting.properties['maturityDate'],
      );
      expect(OTDSortField.startDate.label, t.sorting.properties['startDate']);
      expect(OTDSortField.name.label, t.sorting.properties['name']);
      expect(OTDSortField.amount.label, t.sorting.properties['amount']);

      for (final field in OTDSortField.values) {
        final asc = field.directionLabel(SortDirection.asc);
        final desc = field.directionLabel(SortDirection.desc);
        expect(asc, isNotEmpty);
        expect(desc, isNotEmpty);
        expect(asc, isNot(equals(desc)));
      }

      const initial = OTDSearchCriteria();
      expect(initial.sortField, OTDSortField.maturityDate);
      expect(initial.statusFilters, [DepositStatus.active]);
      final updated = initial.copyWith(
        searchQuery: 'Bruce',
        sortField: OTDSortField.amount,
        sortDirection: SortDirection.desc,
        urgencyFilters: const [MaturityUrgency.maturingSoon],
        schemeFilters: const [OneTimeSchemeType.monthlyIncomeScheme],
      );
      expect(updated.searchQuery, 'Bruce');
      expect(updated.schemeFilters, [OneTimeSchemeType.monthlyIncomeScheme]);
    });

    test('RDSortField exposes labels and asc/desc direction labels', () {
      expect(RDSortField.serialNo.label, t.sorting.properties['serialNo']);
      expect(
        RDSortField.maturityDate.label,
        t.sorting.properties['maturityDate'],
      );
      expect(RDSortField.startDate.label, t.sorting.properties['startDate']);
      expect(RDSortField.name.label, t.sorting.properties['name']);
      expect(RDSortField.amount.label, t.sorting.properties['amount']);

      for (final field in RDSortField.values) {
        final asc = field.directionLabel(SortDirection.asc);
        final desc = field.directionLabel(SortDirection.desc);
        expect(asc, isNotEmpty);
        expect(desc, isNotEmpty);
        expect(asc, isNot(equals(desc)));
      }

      const initial = RDSearchCriteria();
      expect(initial.sortField, RDSortField.serialNo);
      final updated = initial.copyWith(
        searchQuery: 'Clark',
        sortField: RDSortField.name,
        sortDirection: SortDirection.desc,
        urgencyFilters: const [MaturityUrgency.matured],
      );
      expect(updated.searchQuery, 'Clark');
      expect(updated.urgencyFilters, [MaturityUrgency.matured]);
    });
  });

  group('RDHubStepTrack value equality', () {
    test('all step types implement value equality and hashCode cleanly', () {
      expect(
        const RDCustomerOverdue(months: 2),
        const RDCustomerOverdue(months: 2),
      );
      expect(
        const RDCustomerOverdue(months: 2),
        isNot(const RDCustomerOverdue(months: 3)),
      );
      expect(const RDCustomerDueToday(), const RDCustomerDueToday());
      expect(const RDCustomerUpcoming(), const RDCustomerUpcoming());
      expect(const RDCustomerPartial(), const RDCustomerPartial());
      expect(const RDCustomerReceivable(), const RDCustomerReceivable());
      expect(const RDCustomerPaid(), const RDCustomerPaid());
      expect(const RDHubBaselineTrack(), const RDHubBaselineTrack());

      const t1 = RDHubTwoStepTrack(
        customer: RDCustomerPaid(),
        po: RDPoStep.deposited,
      );
      const t2 = RDHubTwoStepTrack(
        customer: RDCustomerPaid(),
        po: RDPoStep.deposited,
      );
      const t3 = RDHubTwoStepTrack(
        customer: RDCustomerPaid(),
        po: RDPoStep.pending,
      );
      expect(t1, t2);
      expect(t1.hashCode, t2.hashCode);
      expect(t1, isNot(t3));
      expect(
        {
          const RDCustomerOverdue(months: 1),
          const RDCustomerDueToday(),
          const RDCustomerUpcoming(),
          const RDCustomerPartial(),
          const RDCustomerReceivable(),
          const RDCustomerPaid(),
          const RDHubBaselineTrack(),
          t1,
        }.length,
        8,
      );
    });
  });

  group('IntentService', () {
    test(
      'dispatches tel, sms, wa.me, maps, external URL, and mailto URIs',
      () async {
        final launchedUrls = <String>[];
        var allowLaunch = true;

        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (call) async {
            if (call.method == 'canLaunch') return allowLaunch;
            if (call.method == 'launch') {
              launchedUrls.add((call.arguments as Map)['url'] as String);
              return true;
            }
            return null;
          },
        );
        const codec = StandardMessageCodec();
        for (final channel in [
          'dev.flutter.pigeon.url_launcher_macos.UrlLauncherApi.canLaunchUrl',
          'dev.flutter.pigeon.url_launcher_linux.UrlLauncherApi.canLaunchUrl',
        ]) {
          messenger.setMockMessageHandler(channel, (message) async {
            return codec.encodeMessage(<Object?>[allowLaunch]);
          });
        }
        for (final channel in [
          'dev.flutter.pigeon.url_launcher_macos.UrlLauncherApi.launchUrl',
          'dev.flutter.pigeon.url_launcher_linux.UrlLauncherApi.launchUrl',
        ]) {
          messenger.setMockMessageHandler(channel, (message) async {
            final decoded = codec.decodeMessage(message) as List<Object?>?;
            if (decoded != null && decoded.isNotEmpty) {
              launchedUrls.add(decoded.first as String);
            }
            return codec.encodeMessage(<Object?>[true]);
          });
        }
        addTearDown(() {
          messenger.setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/url_launcher'),
            null,
          );
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);
        final service = container.read(intentServiceProvider);

        await service.launchPhone('9876543210');
        await service.launchSms('9876543210');
        await service.launchWhatsApp('+91 98765-43210');
        await service.launchMapSearch('Bengaluru GPO');
        await service.launchExternalUrl('https://postfolio.dev');
        await service.launchSupportEmail(
          to: 'support@postfolio.dev',
          subject: 'Help',
          body: 'Details',
        );

        expect(launchedUrls, [
          'tel:9876543210',
          'sms:9876543210',
          'https://wa.me/+919876543210',
          'https://maps.google.com/?q=Bengaluru%20GPO',
          'https://postfolio.dev',
          'mailto:support@postfolio.dev?subject=Help&body=Details',
        ]);

        // When canLaunchUrl returns false, launch is skipped without throwing.
        allowLaunch = false;
        await service.launchPhone('123');
        expect(launchedUrls, hasLength(6));
      },
    );
  });

  group('AsyncEntityBuilder & AsyncSingleEntityBuilder', () {
    testWidgets('renders null-id, loading, skeleton, error/retry, and not-found', (
      tester,
    ) async {
      var retried = 0;

      Widget wrap(Widget child) =>
          MaterialApp(theme: AppTheme.lightTheme, home: child);

      // 1. entityId == null builds immediately with null entity.
      await tester.pumpWidget(
        wrap(
          AsyncEntityBuilder<String>(
            state: const AsyncLoading(),
            entityId: null,
            idSelector: (s) => s,
            notFoundMessage: 'Missing item',
            onRetry: () {},
            builder: (entity) => Text('built:${entity ?? "new"}'),
          ),
        ),
      );
      expect(find.text('built:new'), findsOneWidget);

      // 2. Loading with dummyEntity uses Skeletonizer, without dummy shows indicator.
      await tester.pumpWidget(
        wrap(
          AsyncEntityBuilder<String>(
            state: const AsyncLoading(),
            entityId: '1',
            idSelector: (s) => s,
            dummyEntity: 'Placeholder',
            notFoundMessage: 'Missing item',
            onRetry: () {},
            builder: (entity) => Scaffold(body: Text(entity ?? '')),
          ),
        ),
      );
      expect(find.text('Placeholder'), findsOneWidget);

      await tester.pumpWidget(
        wrap(
          AsyncEntityBuilder<String>(
            state: const AsyncLoading(),
            entityId: '1',
            idSelector: (s) => s,
            wrapWithScaffold: false,
            notFoundMessage: 'Missing item',
            onRetry: () {},
            builder: (entity) => Text(entity ?? ''),
          ),
        ),
      );
      expect(find.byType(Scaffold), findsNothing);

      // 3. Data missing item renders notFoundMessage.
      await tester.pumpWidget(
        wrap(
          AsyncEntityBuilder<String>(
            state: const AsyncData(['2']),
            entityId: '1',
            idSelector: (s) => s,
            notFoundMessage: 'Missing item',
            onRetry: () {},
            builder: (entity) => Text(entity ?? ''),
          ),
        ),
      );
      expect(find.text('Missing item'), findsOneWidget);

      // 4. Error state renders message and triggers onRetry.
      await tester.pumpWidget(
        wrap(
          AsyncEntityBuilder<String>(
            state: AsyncError('boom', StackTrace.empty),
            entityId: '1',
            idSelector: (s) => s,
            notFoundMessage: 'Missing item',
            onRetry: () => retried++,
            builder: (entity) => Text(entity ?? ''),
          ),
        ),
      );
      expect(find.text('boom'), findsOneWidget);
      await tester.tap(find.text(t.common.retry));
      expect(retried, 1);

      // 5. AsyncSingleEntityBuilder covers seed, dummyEntity, loading, and error.
      await tester.pumpWidget(
        wrap(
          AsyncSingleEntityBuilder<String>(
            state: const AsyncLoading(),
            seed: 'Seed value',
            notFoundMessage: 'Missing',
            onRetry: () {},
            builder: (entity) => Text('single:$entity'),
          ),
        ),
      );
      expect(find.text('single:Seed value'), findsOneWidget);

      await tester.pumpWidget(
        wrap(
          AsyncSingleEntityBuilder<String>(
            state: const AsyncLoading(),
            dummyEntity: 'Dummy single',
            notFoundMessage: 'Missing',
            onRetry: () {},
            builder: (entity) => Scaffold(body: Text('single:$entity')),
          ),
        ),
      );
      expect(find.text('single:Dummy single'), findsOneWidget);

      await tester.pumpWidget(
        wrap(
          AsyncSingleEntityBuilder<String>(
            state: const AsyncLoading(),
            notFoundMessage: 'Missing',
            onRetry: () {},
            builder: (entity) => Text('single:$entity'),
          ),
        ),
      );
      expect(find.text(t.common.loading), findsOneWidget);

      await tester.pumpWidget(
        wrap(
          AsyncSingleEntityBuilder<String>(
            state: AsyncError('single-err', StackTrace.empty),
            notFoundMessage: 'Missing',
            onRetry: () => retried++,
            builder: (entity) => Text('single:$entity'),
          ),
        ),
      );
      await tester.tap(find.text(t.common.retry));
      expect(retried, 2);
      await tester.pumpAndSettle();
    });
  });
}
