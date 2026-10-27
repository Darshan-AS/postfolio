/// Exhaustive display state of a single schedule month.
///
/// Every widget that colours, labels or icons an installment MUST derive from this enum via
/// `RDInstallment.displayStatusAt(now)` so the heatmap, tiles, inspector and hub cards can never
/// disagree about what a month means.
enum RDInstallmentDisplayStatus {
  /// Paid and deposited before the account was onboarded; immutable.
  baseline,

  /// Customer paid in full, deposited at PO, no fee outstanding.
  settled,

  /// Customer paid in full and PO deposit is done, but a default fee is still owed.
  feePending,

  /// Customer paid in full; cash is with the agent awaiting PO deposit.
  collectedPendingPo,

  /// Customer has paid part of the installment; nothing deposited yet.
  partiallyPaid,

  /// Agent deposited at PO from their own pocket; customer still owes.
  pocketAdvanced,

  /// Unpaid and past the statutory due date.
  overdue,

  /// Unpaid and due today.
  dueToday,

  /// Unpaid and not yet due.
  upcoming;

  /// Customer still owes principal and/or fee.
  bool get isCustomerPending => switch (this) {
        baseline || settled || collectedPendingPo => false,
        feePending ||
        partiallyPaid ||
        pocketAdvanced ||
        overdue ||
        dueToday ||
        upcoming =>
          true,
      };

  /// Cash collected from the customer is physically with the agent.
  bool get isCashWithAgent => this == collectedPendingPo;

  /// The month can be deposited at the PO.
  bool get canDepositToPo => switch (this) {
        baseline || settled || feePending || pocketAdvanced => false,
        collectedPendingPo ||
        partiallyPaid ||
        overdue ||
        dueToday ||
        upcoming =>
          true,
      };

  /// The PO deposit can be reverted.
  bool get canRevertPo => switch (this) {
        settled || feePending || pocketAdvanced => true,
        baseline ||
        collectedPendingPo ||
        partiallyPaid ||
        overdue ||
        dueToday ||
        upcoming =>
          false,
      };
}
