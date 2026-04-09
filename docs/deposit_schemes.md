# Post Office Deposit Schemes

This document outlines the standard Post Office savings schemes, highlighting which ones are supported by the **Postfolio** app and how their math/rules work.

---

## 1. Schemes Supported by Postfolio

Based on the app's architecture, we divide schemes into two primary categories: **Recurring Deposits** and **One-Time Deposits**.

### A. Recurring Deposits (RD)
The backbone of the agency business (specifically MPKBY agents).
* **How it works:** A customer commits to depositing a fixed amount every month for a fixed tenure (usually 5 years / 60 months).
* **Agent Commission:** **4%** of every monthly deposit. (This has been consistently 4% for MPKBY agents since Jan 2000).
* **Tracking Needs:**
  * Monthly/Daily tracking.
  * Late fee calculations if a customer misses a month.
  * Advance deposit tracking (customers paying for 3 months at once).
  * Rebate calculations (discounts given by the PO for advance deposits).
* **Maturity:** Earns compound interest quarterly, paid out at the end of 5 years.

### B. One-Time Deposits
These are lump-sum investments managed by SAS agents. The agent collects the money once, deposits it, and earns a one-time commission.

* **Time Deposit (TD):** 
  * Fixed deposits for 1, 2, 3, or 5-year tenures.
  * Interest is calculated quarterly but paid annually.
  * Commission: **0.5%** of the principal.
* **Monthly Income Scheme (MIS):**
  * A lump sum is invested for 5 years.
  * Interest is paid out to the customer every single month.
  * Commission: **0.5%** of the principal.
* **Kisan Vikas Patra (KVP):**
  * A certificate that roughly doubles the invested amount in a specific timeframe (e.g., 115 months). 
  * Commission: **0.5%** of the principal.
* **National Savings Certificate (NSC):**
  * A 5-year fixed-rate investment with tax benefits. Interest compounds annually but is paid at maturity.
  * Commission: **0.5%** of the principal.

---

## 2. Commission Rate History & TDS Rules

**Agent Commission History:**
| Scheme Type | Current Rate | Pre-Dec 2011 Rate | Notes |
| :--- | :--- | :--- | :--- |
| **Recurring Deposit (RD)** | **4.0%** | 4.0% | Handled exclusively via MPKBY. |
| **Time Deposit (TD)** | **0.5%** | 1.0% | Reduced in 2011. |
| **Monthly Income Scheme (MIS)** | **0.5%** | 1.0% | Reduced in 2011. |
| **NSC / KVP** | **0.5%** | 1.0% | Reduced in 2011. |
| **PPF / SCSS** | **0.0%** | 1.0% | Commission completely discontinued in Dec 2011. |

**Tax Deduction at Source (TDS):**
* Effective **October 1, 2024**, the TDS rate on an Agent's Commission was reduced from **5% to 2%** under Section 194H of the Income Tax Act.
* The app should calculate the *Gross Commission* based on the table above, but must also account for a 2% TDS deduction when calculating the *Net Payout* received by the agent in their PO Savings Account.

---

## 3. Schemes Not Currently Supported (Out of Scope for V1)

While the Post Office supports the following, they are generally not the primary focus for field collection agents or have strict limits:

* **Savings Account (SB):** Standard 4% interest account. Agents don't get commissions on this.
* **Public Provident Fund (PPF):** 15-year long-term retirement savings. (Commission is 0%).
* **Senior Citizen Savings Scheme (SCSS):** Specifically for >60 years of age. (Commission is 0%).
* **Sukanya Samriddhi Yojana (SSA):** Girl child savings scheme.

---

## 4. Technical Considerations for Schemes
* **Extensibility:** The app must treat "Schemes" as a configuration or a data model, not hardcoded logic. Interest rates change every quarter, and commission rates change every few years based on government budgets.
* **Math Purity:** All maturity, penalty, rebate, and commission calculations must be written as pure Dart functions with strict unit tests (`docs/PRODUCT_REQUIREMENTS.md` details the architectural approach).
