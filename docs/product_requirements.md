# Postfolio Product Requirements

*Note: For detailed business rules, mathematical formulas, and the agent workflow, please refer to the `docs/domain_knowledge/` folder.*

## 1. App Overview & Core Objectives
**Postfolio** is a CRM and financial portfolio tracker built exclusively for Post Office Agents to replace physical diaries and ledgers.
1. Prevent missed collections for Recurring Deposits.
2. Provide a daily "Cash in Hand" vs "Cash Deposited" reconciliation.
3. Automatically project agent commissions.
4. Work flawlessly without an active internet connection (Offline-first).

---

## 2. Feature Specifications

### 2.1 Customer Management (`lib/features/customers/`)
* **Create/Edit/Delete Customers:** Name, Contact Info, Address.
* **Customer Profile:** A view showing a specific customer's active and matured accounts (both Recurring and One-Time).
* **Document Tracking:** (Optional V2) Tracking PAN/Aadhar or KYC expiry for customers.

### 2.2 Recurring Deposits Tracking (`lib/features/recurring_deposits/`)
* **Account Creation:** Link to a customer, define the fixed monthly amount, start date, and account number.
* **Collection Logging:** Agents can log when they receive money.
  * Must support partial payments, exact payments, and advance payments.
  * Must handle Post Office logic: *Late fees* (defaults) and *Rebates* (advance payments).
* **Status Flags:** Highlight accounts that are "Due", "Pending", or "Defaulted" for the current month.
* **List Views:** Filter and search capabilities.

### 2.3 One-Time Deposits Tracking (`lib/features/one_time_deposits/`)
* **Account Creation:** Select scheme type (TD, MIS, KVP, NSC), principal amount, date of deposit.
* **Maturity Tracking:** Show agents which fixed deposits are maturing soon so they can approach the customer for reinvestment.
* **List Views:** Filter and search capabilities.

### 2.4 Dashboard & Analytics (`lib/features/dashboard/`)
* **Daily Ledger:** "Total collected today" so the agent knows exactly how much cash should be in their bag.
* **Monthly Targets:** Progress bar showing total collections this month vs previous months.
* **Commission Projections:** Estimated earnings for the current month based on collected amounts and scheme commission rates.

### 2.5 Reports & Schedules (Future Scope)
* Generate PDF/Excel "Lot" schedules that the agent can print and hand over to the Post Office teller.

---

## 3. Technical Requirements

### 3.1 Architecture
* **Framework:** Flutter (Mobile/Web/Desktop).
* **State Management:** Riverpod (`Notifier` / `AsyncNotifier`).
* **Models:** `freezed` for strict immutability.
* **Routing:** `go_router`.

### 3.2 Offline-First Database Strategy
* **Backend:** Firebase Firestore.
* **Requirement:** The app must work perfectly deep in a rural village with zero internet. Firestore's offline persistence will be heavily relied upon.
* All data writes update the local cache immediately and sync to the cloud when the network is restored.

### 3.3 Math & Calculation Principles
* Never store calculated fields (e.g., "Current Balance" or "Total Commission") in the database if they can be derived.
* Store the source of truth: *The Transaction* (Amount, Timestamp, Account ID).
* Calculate maturity, interest, and commissions purely in the presentation/domain layer using Dart extension methods or Notifiers.
* **Extensibility:** Treat "Schemes" as a configuration or data model. Interest and commission rates change over time, so calculations must be pure Dart functions with strict unit tests.

## 4. Out of Scope (Non-Goals)
To prevent feature creep, the following features are explicitly out of scope for the application:
* **Direct Server Integration:** The app will not integrate directly with actual Government Post Office servers (as APIs do not exist).
* **Payment Processing:** The app will not process actual digital payments (UPI/Card). It is strictly a tracking and CRM ledger.

## 5. Security & Authentication
* **Authentication:** The app will support authentication via Email and Phone (OTP).
* **Local Security:** An App Lock feature (Biometrics/PIN) to prevent unauthorized access to the agent's ledger locally might be supported in a later phase.

