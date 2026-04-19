# Postfolio Product Requirements & Domain Knowledge

## 1. Domain Knowledge: Post Office Agency Business

### Background Context
In many developing nations, specifically modeled after the **Indian Post Office Small Savings Schemes**, postal networks operate as the primary banking institution for rural and middle-class populations. 
To mobilize these savings, the government issues **Agency Licenses** to individuals who act as intermediaries between the depositors and the Post Office. A prominent example is the **Mahila Pradhan Kshetriya Bachat Yojana (MPKBY)**, which grants licenses exclusively to women to empower them financially while encouraging household savings. The **Standardised Agency System (SAS)** is another license type for selling specific certificates and time deposits.

### The Agent's Workflow
An agent's primary job is to canvas for deposits, collect money from the customer's doorstep, and deposit it.
1. **Acquisition:** The agent convinces a customer to open a savings account (e.g., a Recurring Deposit).
2. **Collection:** The agent visits the customer regularly to collect cash or cheques.
3. **Record Keeping:** The agent updates their personal ledger and takes the customer's physical passbook.
4. **Deposit:** The agent visits the Post Office, fills out deposit slips ("schedules"), deposits the cash, and gets the passbooks stamped.
5. **Return:** The agent returns the updated passbook to the customer.

### Core Pain Points (Why this app exists)
1. **Manual Ledgers:** Agents track hundreds of customers and thousands of micro-transactions in physical diaries.
2. **Collection Defaults:** Forgetting who has paid for the current month leads to missed deposits and penalty fees for the customer (damaging the agent's reputation).
3. **Commission Tracking:** Agents struggle to project monthly earnings and reconcile correct commission payouts.
4. **Physical Burden:** Generating reports, adding up daily cash to match the wallet, and filling out PO deposit schedules is highly prone to human error.

---

## 2. Financial Schemes & Business Model

Agents do not charge the customers; they are compensated by the government via a commission percentage on the mobilized deposits.

### A. Recurring Deposits (RD)
The backbone of the agency business (specifically MPKBY agents).
* **How it works:** A customer commits to depositing a fixed amount every month for a fixed tenure (usually 5 years / 60 months).
* **Agent Commission:** **4%** of every monthly deposit.
* **Tracking Needs:** Monthly/Daily tracking, late fee calculations (missed months), advance deposit tracking, and rebate calculations (discounts for advance deposits).
* **Maturity:** Earns compound interest quarterly, paid out at the end of 5 years.

### B. One-Time Deposits
Lump-sum investments managed by SAS agents. The agent collects the money once and earns a one-time commission.
* **Time Deposit (TD):** 1, 2, 3, or 5-year tenures. Commission: **0.5%**.
* **Monthly Income Scheme (MIS):** 5-year investment. Interest paid monthly to customer. Commission: **0.5%**.
* **Kisan Vikas Patra (KVP):** Doubles the invested amount in a specific timeframe. Commission: **0.5%**.
* **National Savings Certificate (NSC):** 5-year fixed-rate investment with tax benefits. Commission: **0.5%**.

*(Note: PPF and SCSS are generally out of scope for commission tracking as their commission rate is 0%).*

### Tax Deduction at Source (TDS)
* Effective **October 1, 2024**, the TDS rate on an Agent's Commission was reduced to **2%** under Section 194H of the Income Tax Act.
* The app calculates *Gross Commission* based on the rates above, and accounts for a 2% TDS deduction when calculating the *Net Payout*.

---

## 3. App Overview & Core Objectives
**Postfolio** is a CRM and financial portfolio tracker built exclusively for Post Office Agents to replace physical diaries and ledgers.
1. Prevent missed collections for Recurring Deposits.
2. Provide a daily "Cash in Hand" vs "Cash Deposited" reconciliation.
3. Automatically project agent commissions.
4. Work flawlessly without an active internet connection (Offline-first).

---

## 4. Feature Specifications

### 4.1 Customer Management (`lib/features/customers/`)
* **Create/Edit/Delete Customers:** Name, Contact Info, Address.
* **Customer Profile:** A view showing a specific customer's active and matured accounts (both Recurring and One-Time).
* **Document Tracking:** (Optional V2) Tracking PAN/Aadhar or KYC expiry for customers.

### 4.2 Recurring Deposits Tracking (`lib/features/recurring_deposits/`)
* **Account Creation:** Link to a customer, define the fixed monthly amount, start date, and account number.
* **Collection Logging:** Agents can log when they receive money.
  * Must support partial payments, exact payments, and advance payments.
  * Must handle Post Office logic: *Late fees* (defaults) and *Rebates* (advance payments).
* **Status Flags:** Highlight accounts that are "Due", "Pending", or "Defaulted" for the current month.

### 4.3 One-Time Deposits Tracking (`lib/features/one_time_deposits/`)
* **Account Creation:** Select scheme type (TD, MIS, KVP, NSC), principal amount, date of deposit.
* **Maturity Tracking:** Show agents which fixed deposits are maturing soon so they can approach the customer for reinvestment.

### 4.4 Dashboard & Analytics (`lib/features/dashboard/`)
* **Daily Ledger:** "Total collected today" so the agent knows exactly how much cash should be in their bag.
* **Monthly Targets:** Progress bar showing total collections this month vs previous months.
* **Commission Projections:** Estimated earnings for the current month based on collected amounts and scheme commission rates.

### 4.5 Reports & Schedules (Future Scope)
* Generate PDF/Excel "Lot" schedules that the agent can print and hand over to the Post Office teller.

---

## 5. Technical Requirements

### 5.1 Architecture
* **Framework:** Flutter (Mobile/Web/Desktop).
* **State Management:** Riverpod (`Notifier` / `AsyncNotifier`).
* **Models:** `freezed` for strict immutability.
* **Routing:** `go_router`.

### 5.2 Offline-First Database Strategy
* **Backend:** Firebase Firestore.
* **Requirement:** The app must work perfectly deep in a rural village with zero internet. Firestore's offline persistence will be heavily relied upon.
* All data writes update the local cache immediately and sync to the cloud when the network is restored.

### 5.3 Math & Calculation Principles
* Never store calculated fields (e.g., "Current Balance" or "Total Commission") in the database if they can be derived.
* Store the source of truth: *The Transaction* (Amount, Timestamp, Account ID).
* Calculate maturity, interest, and commissions purely in the presentation/domain layer using Dart extension methods or Notifiers.
* **Extensibility:** Treat "Schemes" as a configuration or data model. Interest and commission rates change over time, so calculations must be pure Dart functions with strict unit tests.
