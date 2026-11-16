import 'dart:async';

import 'package:postfolio/core/mocks/fake_data_source.dart';
import 'package:postfolio/core/providers/demo_mode_provider.dart';
import 'package:postfolio/core/providers/supabase_provider.dart';
import 'package:postfolio/core/utils/result.dart';
import 'package:postfolio/features/customers/data/supabase_customer_repository.dart';
import 'package:postfolio/features/customers/domain/customer_model.dart';
import 'package:postfolio/features/one_time_deposits/data/one_time_deposit_repository.dart';
import 'package:postfolio/features/recurring_deposits/data/recurring_deposit_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'customer_repository.g.dart';

abstract class CustomerRepository {
  Stream<Result<List<Customer>, String>> watchCustomers();
  Stream<Result<Customer, String>> watchCustomerById(String id);
  Future<Result<void, String>> createCustomer(Customer customer);
  Future<Result<void, String>> updateCustomer(Customer customer);
  Future<Result<void, String>> deleteCustomer(String id);
}

class FakeCustomerRepository implements CustomerRepository {
  FakeCustomerRepository({
    List<Customer>? customers,
    this.delay = const Duration(milliseconds: 500),
    this.hasLinkedDeposits,
  }) : _customers = [...(customers ?? FakeDataSource().customers)];

  final Duration delay;
  final bool Function(String customerId)? hasLinkedDeposits;

  final _controller =
      StreamController<Result<List<Customer>, String>>.broadcast();

  final List<Customer> _customers;

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(Success([..._customers]));
    }
  }

  @override
  Stream<Result<List<Customer>, String>> watchCustomers() async* {
    yield Success([..._customers]);
    yield* _controller.stream;
  }

  @override
  Stream<Result<Customer, String>> watchCustomerById(String id) async* {
    final customer = _customers.where((c) => c.id == id).firstOrNull;
    if (customer != null) {
      yield Success(customer);
    } else {
      yield const Failure('Customer not found');
    }

    yield* _controller.stream.map((result) {
      return switch (result) {
        Success(value: final customers) => () {
          final c = customers.where((c) => c.id == id).firstOrNull;
          if (c != null) {
            return Success<Customer, String>(c);
          }
          return const Failure<Customer, String>('Customer not found');
        }(),
        Failure(error: final error) => Failure(error),
      };
    });
  }

  @override
  Future<Result<void, String>> createCustomer(Customer customer) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    _customers.add(customer);
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void, String>> updateCustomer(Customer customer) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    final index = _customers.indexWhere((u) => u.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      _emit();
      return const Success(null);
    }
    return const Failure('Customer not found');
  }

  @override
  Future<Result<void, String>> deleteCustomer(String id) async {
    if (delay > Duration.zero) await Future.delayed(delay);
    if (hasLinkedDeposits?.call(id) ?? false) {
      return const Failure(
        'Cannot delete this record while linked accounts or transactions exist.',
      );
    }
    final initialLength = _customers.length;
    _customers.removeWhere((u) => u.id == id);
    if (_customers.length < initialLength) {
      _emit();
      return const Success(null);
    }
    return const Failure('Customer not found');
  }

  void dispose() {
    _controller.close();
  }
}

@riverpod
CustomerRepository customerRepository(Ref ref) {
  if (ref.watch(demoModeProvider)) {
    final repo = FakeCustomerRepository(
      hasLinkedDeposits: (customerId) {
        final otd = ref.read(oneTimeDepositRepositoryProvider);
        final rd = ref.read(recurringDepositRepositoryProvider);
        return (otd is FakeOneTimeDepositRepository &&
                otd.deposits.any((d) => d.customerId == customerId)) ||
            (rd is FakeRecurringDepositRepository &&
                rd.deposits.any((d) => d.customerId == customerId));
      },
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  return SupabaseCustomerRepository(ref.watch(supabaseClientProvider));
}
