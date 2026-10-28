/// Exhaustive display state of a single schedule month.
///
/// Every widget that colours, labels or icons an installment MUST derive from this enum via
/// `RDInstallment.displayStatusAt(now)` so the passbook, tiles and hub cards can never
/// disagree about what a month means.
///
/// Both ledgers are sequential, so a month is in exactly one of these states.
enum RDInstallmentDisplayStatus {
  /// Deposited before the account was onboarded; immutable.
  baseline,

  /// Customer paid the full due (installment + fee) and it is deposited at the PO.
  settled,

  /// Customer paid the full due; cash is with the agent awaiting the PO visit.
  collectedPendingPo,

  /// Customer has paid part of the due; nothing deposited yet.
  partiallyPaid,

  /// Deposited at the PO from the agent's pocket; the customer still owes (all or part).
  frontedByAgent,

  /// Unpaid and past the statutory due date.
  overdue,

  /// Unpaid and due today.
  dueToday,

  /// Unpaid and not yet due.
  upcoming;

  /// Customer still owes money on this month.
  bool get isCustomerPending => switch (this) {
        baseline || settled || collectedPendingPo => false,
        partiallyPaid || frontedByAgent || overdue || dueToday || upcoming => true,
      };

  /// Collected money for this month is physically with the agent.
  bool get isCashWithAgent => this == collectedPendingPo || this == partiallyPaid;

  /// Already at the Post Office.
  bool get isDeposited => switch (this) {
        baseline || settled || frontedByAgent => true,
        collectedPendingPo || partiallyPaid || overdue || dueToday || upcoming => false,
      };
}
