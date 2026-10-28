# RD Ledger — Ground-truth use cases & agreed design (Phase 7 input)

Source: interview 2026-10-28 + India Post RD rules / DOP Agent Portal behaviour. Each row records what happens on the ground, the official rule, and the decision.

## A. How money moves (confirmed)

| # | On the ground | Official rule / portal behaviour | Decision |
|---|---|---|---|
| A1 | Agent builds **lots** on the DOP portal (C-number, ≤ ₹20,000 cash per lot), prints, pays at the counter in bulk. | MPKBY agent lot flow; cash cap per lot. | Lots are **out of scope now**; every PO deposit event carries an optional `batch_id` + amount so lots can be layered on later (auto-group to ₹20k, editable). |
| A2 | Per account the agent enters only a **count of installments**; the portal assigns them to the next due months and computes fee/rebate. | RD deposits are strictly sequential (passbook order). | **PO deposit = event `(rd_id, deposited_on, installment_count, default_fee_paid, amount, batch_id)`**. No per-month selection anywhere in the UI. Undo = delete latest event only. |
| A3 | Default fee is **bundled into the lot total**; an installment cannot be paid without its fee. | ₹1 per ₹100 per month of default, payable with the defaulted installment. | A month's **due amount = installment + fee(months late)**, one number. No split modes, no separate fee pool, no "fee pending at PO" state. Drop `split_mode / installment_amount / late_fee_amount` columns. |
| A4 | Fee usually collected from the customer; sometimes **absorbed by the agent** for good customers. | — | New fact **`rd_fee_absorptions (rd_id, installment_no, amount, on)`**. Recorded at collection time ("absorb remaining ₹50"). Counts in agent float, never reduces what the PO receives. Replaces `rd_fee_waivers`. |
| A5 | Fee is charged by the PO **as of the deposit date**. Agent enters the deposit date (default today). | Portal computes on lot date. | Customer owes fee as of the **PO deposit date once deposited; estimated as of today until then.** |
| A6 | **Partial payments are common** (several small amounts in a month). | PO accepts whole installments only. | First-class: partial allowed **only on the earliest open month**; cash held by agent until whole. PO deposit of a partial month = agent **top-up from pocket** (explicit label). |
| A7 | Paying ahead is **rare**; rebate not needed now. | 6/12-month advance rebate exists. | Overpayment → `customerCredit`, auto-applied to the next months. Rebate deferred (data already sufficient). |
| A8 | Agents **regularly front installments from pocket** to keep customers out of default before the 15th/EOM. | — | **`depositedThrough > paidThrough` = receivable.** Tracked per account and in total (agent float). |
| A9 | Corrections: customer payments fully editable; PO deposits — undo latest only. | PO is sequential. | As stated. |
| A10 | Two collection passes per month: **1–15 window** (deposit by 15th) and **16–EOM window** (deposit by month-end). Primary list = "still to collect in this window", sorted by customer. | Due-date rule by opening day. | Hub keeps the window segmentation as the primary axis; month switcher stays (cheap with counters), status shown as-of-today. |
| A11 | Households with several RDs pay lump sums. | — | **Deferred**: per-account transactions now; schema must allow one collection split into N transactions later (add nullable `collection_id` to `rd_transactions` now). |
| A12 | No receipts issued; passbook is proof. | — | No receipt feature. |
| A13 | Onboarding an existing RD: only the **passbook count** is known; pre-existing customer dues entered as a **one-off opening receivable**. | — | Keep `initial_paid_installments` (= deposited-through baseline). Add optional `opening_receivable` amount on the deposit (fact), projected as owed-to-agent. |
| A14 | One agent, maybe two devices. Always online. | — | Last-write-wins on the fact log is acceptable. No offline design. |
| A15 | Mostly cash, some UPI to agent's account; cheque/bank rare. | Only **cash** lots are capped at ₹20k. | Keep `payment_mode`; agent float splits **cash in hand vs digital in hand**. |
| A16 | Commission (4% MPKBY) wanted later. | — | PO deposit events carry `amount`; derivable later. |
| A17 | Discontinuation after 4 defaults rarely happens. | > 4 defaults → discontinued; revival within 2 months. | **Skipped** for now. |
| A18 | Maturity: nothing beyond status. | — | No change. |

## B. Resulting ledger model (what the projector derives per account)

```
facts:  deposit terms (+ initial_paid_installments, opening_receivable)
        rd_transactions      (amount, paid_date, mode, collection_id?)        ← customer → agent
        rd_po_deposits       (deposited_on, installment_count, fee_paid, amount, batch_id?)  ← agent → PO
        rd_fee_absorptions   (installment_no, amount, on)                     ← agent eats fee

derived: paidThroughNo, partialOnNo + partialAmount, customerCredit
         depositedThroughNo
         per month: dueAmount(asOf) = installment + fee(monthsLate(asOf or depositedOn))
         owedByCustomer  = Σ open months' due − partial − credit + openingReceivable − absorbed
         receivable      = money agent fronted = Σ due of months deposited but not customer-paid
         cashInHand      = collected but not yet deposited (split by mode)
         arrears         = count of unpaid months past due
```

Month display status collapses to: `baseline · settled · collected (awaiting PO) · partial · fronted by agent · overdue · due today · upcoming`.

## C. What this removes vs. today's code

- `PaymentSplitMode`, split components, the 4-way split selector and `custom` validation.
- Two-pass allocator, overflow passes, `paidLateFee`, `feePending` status, "collected but fee pending".
- Per-month PO selection in Hub and Detail (checkbox multi-select across arbitrary months) → replaced by "Deposit next N" per account and "Deposit all ready" for the window.
- `rd_fee_waivers` (→ `rd_fee_absorptions`), 60-cell heatmap (→ passbook list), `openItems` JSON in the summary (→ counters + partial + credit).

## D. At-a-glance numbers (Hub header)

1. Still to collect in current window — count + ₹
2. Cash in hand ready to deposit — cash vs digital
3. Receivable from customers (pocket advances)
4. Arrears — accounts with 2+ unpaid months

## E. Proposed Phase 7 scope ("Sequential ledger")

1. Migration: reshape `rd_po_deposits` to events; `rd_fee_waivers` → `rd_fee_absorptions`; drop split columns; add `collection_id` (nullable) and `opening_receivable`.
2. Projector: single due-amount allocation, sequential PO counter, absorption + opening receivable, cash/digital split.
3. Controller/UI: payment sheet = amount + mode + date + "absorb remaining fee"; PO = "Deposit next N (₹X incl. ₹Y fee) on <date>" with undo-latest; Detail = passbook view; Hub = window-first list, 4 header numbers.
4. Tests: port projector tables; e2e against local stack; seed updated.

> [!IMPORTANT]
> Two rules this design leans on were confirmed by you from portal behaviour: (A2) deposits are count-based/sequential and (A3) the fee is inseparable from the installment. If either turns out to differ at a particular post office, A3 is the one that would reintroduce complexity — flag it early.
