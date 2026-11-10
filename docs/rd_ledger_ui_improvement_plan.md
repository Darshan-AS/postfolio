# RD Ledger UI — improvement plan (interview + code review, 2026-10-29)

## What the interview settled

| Fact | UI consequence |
|---|---|
| House-to-house route, phone in one hand | Row actions reachable with the thumb; horizontal scrolling is fine where needed (your call). |
| Agent identifies accounts by **serial number** (1, 2, 3…) | **Customer name stays the main label**; serial and account number are the secondary line and both are search targets (serial matched first). |
| Customer almost always hands over **exactly the due amount** | Row button reads **"Collect ₹1,050"** and opens the sheet **prefilled with that amount** so the happy path is tap → Record (2 taps). The sheet stays for now — long-press shortcuts are hard to discover. Toast + Undo after. |
| 2–5 RDs per customer at the door, one lump sum | **Deferred** (your call). Keep "Group by customer" so the household's accounts sit together and are collected one by one; the `collection_id` hook stays for later. |
| PO visit prepared beforehand: serial + count + ₹, running total, ≤₹20k cash groups; fronting decided per account during prep | A dedicated **PO visit planner** screen replaces "Deposit all": account rows with count/₹/fee, "front this one too" toggles with a from-pocket subtotal, cash vs UPI totals, ≤₹20k grouping, one date, one tap, one Undo (batch). |
| Fronted money is chased later and repaid via normal Collect | Rows keep an **"owes you ₹X"** badge; a **Receivables** filter in the Hub. |
| Landing = Accounts directory; Hub opens on full month (as now); badges suffice for arrears; toast+Undo is enough; modern phones | No "Today" dashboard, no default window filter, no arrears pass, no receipt screen, density is fine. |

## Tier A — correctness bugs visible in the UI (must fix, small)

| # | Problem | Fix |
|---|---|---|
| A1 | "Deposit all" / "Deposit selected" dialogs show Σ *this month's* due, but the action deposits every ready month per account, fee excluded → dialog ≠ cash handed over. | Quote via `projector.quoteNextDeposit` per account in the controller; dialog: "N accounts · M installments · ₹X incl. ₹Y fee". |
| A2 | Hub "Deposit from pocket" yes/no quotes this month's outstanding, but fronts *all* months up to it, no fee, no date. | Route it through `showRDDepositSheet(initialCount: …)`; delete the dialog path. |
| A3 | Two different absorb-fee rules (hub vs inspector vs sheet); hub can over-absorb. | One `RDInstallment.absorbableFee` getter used everywhere. |
| A4 | Two different "ready/cash" numbers on one header (this-month KPI vs cross-month chip). | Keep the cross-month summary numbers only. |
| A5 | Inspector "Collect" on a later month prefills that month, but allocation is sequential → money lands earlier. | Collect only on `nextDue`; later months show a hint. |
| A6 | Batch deposits write sequentially; a mid-way failure leaves earlier accounts deposited with only an error shown; no Undo. | One `batch_id` per visit; "Undo visit" deletes all events with that id; report "Deposited 4 of 7" on partial failure. |
| A7 | Money ellipsised in KPI cards / batch bar ("₹1,2…"). | `FittedBox` or compact rupee (₹1.2L); never ellipsise money. |

## Tier B — the two primary loops

### B1 · Collection row (Hub)
- Row layout: **Ramesh** (name, main) · `12 · A/c …7890` · due text → trailing **big `owes ₹1,050`** (+ caption `incl. ₹50 fee · +2 months`) → full-width ≥44dp button **`Collect ₹1,050`**.
- The button opens the payment sheet prefilled with ₹1,050 (happy path: tap → Record); toast "₹1,050 from Ramesh → #14 Mar · Undo".
- `/mo` nominal amount moves to the subtitle; drop the `ready: N` badge (the Deposit button already says it).
- Status pill colours: give `frontedByAgent` its own colour; derive header tile colours from the same `RDStatusVisual` family so "To collect" ≠ "Collected" colour.
- Search matches serial first, then account digits, then name — one field, no mode switch.

### B2 · Households (deferred)
- No lump-sum split for now. Keep "Group by customer" (default **on**, since households are the norm) so a customer's accounts are adjacent and each has its own Collect. The `collection_id` hook remains for the future split feature.

### B3 · Hub header (height → ~150dp at 360dp)
- Replace pipeline cards + chip strip + PO strip with a **2×2 grid**: *To collect (this month)* · *In hand ₹T (cash ₹C · UPI ₹D)* · *Receivable ₹R (N accts)* · *Arrears (N accts 2+ months)*. Each tile is a filter (add `RDMonthlyFilter.fronted`). "Plan PO visit" button lives in the In-hand tile.
- Month switcher becomes a one-line `‹ Mar 2026 ▾ ›`; Accounts⇄Hub toggle moves to the app bar; header collapses on scroll.
- Window segmented control counts *still to collect* per window, not all rows.

### B4 · PO visit planner (new screen, replaces "Deposit all")
- Entry: In-hand tile → **Plan PO visit**.
- List of accounts with ready months, serial-first: `12 · Ramesh · 2 installments · ₹2,100 (fee ₹100)`; checkbox per account (all on by default); a **"+ front next month"** toggle per account showing `₹1,000 from pocket`; running totals: *installments*, *cash*, *UPI*, *from pocket*; cash grouped into **≤₹20k lots** (Lot 1 ₹19,500 · Lot 2 ₹7,100) — display only now, the lot/C-number feature later attaches to the same grouping.
- One date (default today), one button **Deposit N installments · ₹X**, one `batch_id`, toast with **Undo visit**.
- This is exactly what the agent keys into the portal, in the same order.

### B5 · Sheets
- Titles carry identity: "Collect from Ramesh · 12" / "Deposit at PO · Ramesh · 12".
- Payment-mode segments get short labels (UPI/Cash/Cheque/Bank), not icon-only.
- Error states get a Retry; create-mode sheet with a typed amount confirms before dismiss.

## Tier C — polish
- Vocabulary pass: action **Front from pocket**, status **Fronted**, number **Receivable**; "In hand ₹T · cash ₹C · UPI ₹D"; "Collected · to deposit" instead of "Collected (Pending PO)"; "Before onboarding" instead of "Opening Baseline"; "Default fee (customer)" / "Default fee (charged at PO)"; "Fee you bore (late deposit)" instead of "agent delay"; one PO verb "Deposit N".
- Accessibility: all row buttons ≥44dp (drop `compact`/`shrinkWrap` on primary actions), `Semantics` on rows ("Ramesh, serial 12, owes ₹1,050, 3 days overdue"), labelled checkboxes, `dueToday` visibly distinct from `upcoming`.
- Inspector hides zero rows; passbook trailing column respects the 56dp rule (move amounts into the title row).
- Hub empty state distinguishes "all settled for Mar" from "nothing due".
- Prune dead i18n keys (`kpis.toCollect/readyForPo/settled/overdue`, `filters.*`, `card.account/serial/fronted`, `ledger.logPayment`, `ledger.quickAmounts`, `fields.yearAbbreviation`, `fields.maturityAmount`, `saveDeposit`).
- Move the remaining widget-side derivations (`collectAmount`, fee folds, month grouping, `canFront/canAbsorb/canUndo`) into projection/item getters or providers.

## Deliberately not doing (per interview)
Household lump-sum split · one-tap collect without a sheet · serial-first row labels · Today dashboard · default window filter · arrears chase screen · receipt/confirmation screen · large-type mode · lots with C-number (planner only *groups*; lot entity comes later) · rebate · discontinuation.

## Suggested order
1. Tier A (half a day; all are money-visible bugs).
2. B1 + B3 (row + header) — biggest daily win, mostly rework of existing widgets.
3. B4 planner + A6 batch undo together (new screen; the ₹20k grouping is the thing agents asked for).
4. B5 + Tier C.
(B2 household split deferred.)
