/// Customer-side step of the 2-step flipbook track.
sealed class RDCustomerStep {
  const RDCustomerStep();
}

final class RDCustomerOverdue extends RDCustomerStep {
  const RDCustomerOverdue({required this.months});
  final int months;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RDCustomerOverdue && months == other.months;

  @override
  int get hashCode => months.hashCode;
}

final class RDCustomerDueToday extends RDCustomerStep {
  const RDCustomerDueToday();

  @override
  bool operator ==(Object other) => other is RDCustomerDueToday;

  @override
  int get hashCode => (RDCustomerDueToday).hashCode;
}

final class RDCustomerUpcoming extends RDCustomerStep {
  const RDCustomerUpcoming();

  @override
  bool operator ==(Object other) => other is RDCustomerUpcoming;

  @override
  int get hashCode => (RDCustomerUpcoming).hashCode;
}

final class RDCustomerPartial extends RDCustomerStep {
  const RDCustomerPartial();

  @override
  bool operator ==(Object other) => other is RDCustomerPartial;

  @override
  int get hashCode => (RDCustomerPartial).hashCode;
}

final class RDCustomerReceivable extends RDCustomerStep {
  const RDCustomerReceivable();

  @override
  bool operator ==(Object other) => other is RDCustomerReceivable;

  @override
  int get hashCode => (RDCustomerReceivable).hashCode;
}

final class RDCustomerPaid extends RDCustomerStep {
  const RDCustomerPaid();

  @override
  bool operator ==(Object other) => other is RDCustomerPaid;

  @override
  int get hashCode => (RDCustomerPaid).hashCode;
}

/// Post Office deposit step of the 2-step flipbook track (strictly binary).
enum RDPoStep { pending, deposited }

/// Unified flipbook track descriptor: either a pre-onboarding baseline month or an active
/// 2-step `Customer | PO` track.
sealed class RDHubStepTrack {
  const RDHubStepTrack();
}

final class RDHubBaselineTrack extends RDHubStepTrack {
  const RDHubBaselineTrack();

  @override
  bool operator ==(Object other) => other is RDHubBaselineTrack;

  @override
  int get hashCode => (RDHubBaselineTrack).hashCode;
}

final class RDHubTwoStepTrack extends RDHubStepTrack {
  const RDHubTwoStepTrack({required this.customer, required this.po});
  final RDCustomerStep customer;
  final RDPoStep po;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RDHubTwoStepTrack &&
          customer == other.customer &&
          po == other.po;

  @override
  int get hashCode => Object.hash(customer, po);
}
