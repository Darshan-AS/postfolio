import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_fee_absorption_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_ledger_facts.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_po_deposit_model.dart';
import 'package:postfolio/features/recurring_deposits/domain/rd_transaction_model.dart';

part 'rd_ledger_change.freezed.dart';

/// One change to the ledger facts, across one or more accounts, that must be stored as a
/// unit: recording a payment, a Post Office visit, undoing one, absorbing a fee.
///
/// The change is designed to be safe to send twice. Payments and absorptions are upserts,
/// a PO event whose id already exists is left alone, and deleting something already gone is
/// a no-op — so a retry after a lost response cannot record anything a second time.
@freezed
sealed class RDLedgerChange with _$RDLedgerChange {
  const RDLedgerChange._();

  const factory RDLedgerChange({
    /// Payments to add, or to replace when the id is already stored.
    @Default(<RDTransaction>[]) List<RDTransaction> upsertTransactions,
    @Default(<({String rdId, String transactionId})>[])
    List<({String rdId, String transactionId})> deleteTransactions,

    /// PO events to add. An event is a fact: an id that is already stored is not changed.
    @Default(<RDPoDeposit>[]) List<RDPoDeposit> insertPoDeposits,
    @Default(<({String rdId, String eventId})>[])
    List<({String rdId, String eventId})> deletePoDeposits,

    /// Absorbed fees, one per (account, month); replaces the one recorded for that month.
    @Default(<RDFeeAbsorption>[]) List<RDFeeAbsorption> upsertFeeAbsorptions,
    @Default(<({String rdId, int installmentNo})>[])
    List<({String rdId, int installmentNo})> deleteFeeAbsorptions,
  }) = _RDLedgerChange;

  bool get isEmpty =>
      upsertTransactions.isEmpty &&
      deleteTransactions.isEmpty &&
      insertPoDeposits.isEmpty &&
      deletePoDeposits.isEmpty &&
      upsertFeeAbsorptions.isEmpty &&
      deleteFeeAbsorptions.isEmpty;

  /// Every account this change touches.
  Set<String> get rdIds => {
        for (final t in upsertTransactions) t.rdId,
        for (final t in deleteTransactions) t.rdId,
        for (final e in insertPoDeposits) e.rdId,
        for (final e in deletePoDeposits) e.rdId,
        for (final a in upsertFeeAbsorptions) a.rdId,
        for (final a in deleteFeeAbsorptions) a.rdId,
      };

  /// The facts of `facts.deposit` once this change is stored. Parts addressed to other
  /// accounts are ignored, and applying the change again yields the same facts.
  RDLedgerFacts applyTo(RDLedgerFacts facts) {
    final rdId = facts.deposit.id;
    if (!rdIds.contains(rdId)) return facts;

    final deletedTx = {
      for (final d in deleteTransactions)
        if (d.rdId == rdId) d.transactionId,
    };
    final upsertedTx = {
      for (final t in upsertTransactions)
        if (t.rdId == rdId) t.id: t,
    };
    final existingTxIds = {for (final t in facts.transactions) t.id};
    final transactions = <RDTransaction>[
      for (final t in facts.transactions)
        if (!deletedTx.contains(t.id))
          // A replaced payment keeps the stored creation time: it orders payments made on
          // the same day.
          upsertedTx[t.id]?.copyWith(createdAt: t.createdAt) ?? t,
      for (final t in upsertedTx.values)
        if (!existingTxIds.contains(t.id) && !deletedTx.contains(t.id)) t,
    ];

    final deletedPo = {
      for (final d in deletePoDeposits)
        if (d.rdId == rdId) d.eventId,
    };
    final existingPoIds = {for (final e in facts.poDeposits) e.id};
    final addedPoIds = <String>{};
    final poDeposits = <RDPoDeposit>[
      for (final e in facts.poDeposits)
        if (!deletedPo.contains(e.id)) e,
      for (final e in insertPoDeposits)
        if (e.rdId == rdId &&
            !existingPoIds.contains(e.id) &&
            !deletedPo.contains(e.id) &&
            addedPoIds.add(e.id))
          e,
    ];

    final deletedMonths = {
      for (final d in deleteFeeAbsorptions)
        if (d.rdId == rdId) d.installmentNo,
    };
    final upsertedMonths = {
      for (final a in upsertFeeAbsorptions)
        if (a.rdId == rdId) a.installmentNo: a,
    };
    final existingMonths = {for (final a in facts.absorptions) a.installmentNo};
    final absorptions = <RDFeeAbsorption>[
      for (final a in facts.absorptions)
        if (!deletedMonths.contains(a.installmentNo)) upsertedMonths[a.installmentNo] ?? a,
      for (final a in upsertedMonths.values)
        if (!existingMonths.contains(a.installmentNo) &&
            !deletedMonths.contains(a.installmentNo))
          a,
    ];

    return facts.copyWith(
      transactions: transactions,
      poDeposits: poDeposits,
      absorptions: absorptions,
    );
  }
}
