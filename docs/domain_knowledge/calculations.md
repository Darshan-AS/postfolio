# Post Office Calculation Formulas & Domain Knowledge

This document contains the exact mathematical formulas and business rules used by the Indian Post Office (Ministry of Finance) for calculating derived attributes for their Small Savings Schemes.

*Disclaimer: These formulas must be translated purely into Dart functions or extension methods in the domain layer. Do not store calculated fields in the database.*

## 1. Maturity Amount Formula (Compounding & Interest)

### Recurring Deposit (RD)
* **Compounding Frequency:** Quarterly.
* **Calculation:** Because deposits are made monthly, compound interest is calculated for each individual deposit based on the quarters it remains in the account.
* **Formula:** 
  $$M = \sum_{i=1}^{n} P \left(1 + \frac{r}{400}\right)^{t_i}$$
  *(Where $P$ is the monthly installment, $r$ is the annual interest rate, $n$ is total months, and $t_i$ is the time in quarters the $i$-th deposit stays in the account).*

### Time Deposit (TD)
* **Compounding Frequency:** Quarterly, but payable **annually** to the savings account.
* **Annual Interest Payout:** 
  $$P \times \left[ \left(1 + \frac{r}{400}\right)^4 - 1 \right]$$
* **Maturity:** At maturity (1, 2, 3, or 5 years), the principal $P$ is returned.

### Monthly Income Scheme (MIS)
* **Interest Type:** Simple interest, distributed monthly.
* **Monthly Payout:** 
  $$P \times \left(\frac{r}{1200}\right)$$
* **Maturity:** At maturity (5 years), the principal $P$ is returned.

### Kisan Vikas Patra (KVP)
* **Compounding Frequency:** Annually. 
* **Maturity:** The principal strictly doubles ($M = P \times 2$). The maturity period (in months) adjusts dynamically based on the prevailing interest rate using $2 = (1 + r/100)^{t_{years}}$.

### National Savings Certificate (NSC)
* **Compounding Frequency:** Annually and paid at maturity (5 years).
* **Maturity Amount:** 
  $$P \times \left(1 + \frac{r}{100}\right)^5$$

---

## 2. Maturity Date Calculation Rules

* **General Rule:** Accounts mature exactly $X$ years from the date of opening (e.g., 5 years for RD, MIS, NSC).
* **RD Exceptions:** If an RD account has defaults (missed installments), the maturity date is **extended by the exact number of defaulted months**.
  * *Constraint:* A maximum of 4 defaults is allowed; if an account hits 5 defaults, it is discontinued and must be revived before maturity.

---

## 3. Agent Commission Formula & TDS Rules

Commissions are calculated based on the scheme type and are subject to TDS deductions under Section 194H/194G.

### Commission Rates
* **MPKBY Agents (RD):** Receive **4%** commission on total RD deposits.
  $$\text{Commission} = \text{Deposit Amount} \times 0.04$$
* **SAS Agents (TD, MIS, KVP, NSC):** Receive **0.5%** commission on total one-time deposits.
  $$\text{Commission} = \text{Deposit Amount} \times 0.005$$

### Tax Deduction at Source (TDS)
* **Threshold:** TDS is deducted if the total commission earned in a financial year exceeds ₹15,000.
* **Rate:** Effective **October 1, 2024**, the TDS rate on agent commissions is **2%**.
  $$\text{TDS Deducted} = \text{Gross Commission} \times 0.02$$
  $$\text{Net Payout} = \text{Gross Commission} - \text{TDS Deducted}$$

---

## 4. Late Fee Formula (RD Defaults)

If an RD installment is missed, a default fee is levied.
* **Due Dates:** By the 15th (for accounts opened between the 1st-15th) or the last day (for accounts opened from the 16th onward).
* **Rule:** ₹1 for every ₹100 of the denomination per month.
* **Formula:** This equates to exactly **1% of the defaulted installment amount per month**.
  $$\text{Late Fee} = \text{Defaulted Installment} \times 0.01 \times \text{Months Defaulted}$$

---

## 5. Early Closing (Premature Closure) Penalty Formulas

### Recurring Deposit (RD)
* **Rule:** Allowed after **3 years** from the date of account opening.
* **Penalty:** RD interest rate is forfeited. Interest is recalculated using the **Post Office Savings Account (POSA) rate** (currently 4.0% p.a.) for the completed months. If advance deposits have been made, premature closure is not allowed until the period for which advance deposits were made is over.

### Time Deposit (TD)
* **< 6 months:** Premature closure not allowed.
* **6 to 12 months:** No TD interest is paid; instead, interest is calculated at the POSA rate (4.0%).
* **> 1 year:** Interest is calculated at **2% less than the TD rate applicable for the completed years**. For the fractional (incomplete) year of withdrawal, interest is calculated at the POSA rate.

### Monthly Income Scheme (MIS)
* **< 1 year:** Premature closure not allowed.
* **1 to 3 years:** A penalty of **2%** is deducted from the principal amount.
  $$\text{Refund} = P - (P \times 0.02)$$
* **3 to 5 years:** A penalty of **1%** is deducted from the principal amount.
  $$\text{Refund} = P - (P \times 0.01)$$

### Senior Citizen Savings Scheme (SCSS)
* **< 1 year:** No interest payable. Any interest already paid is recovered (deducted) from the principal.
* **1 to 2 years:** A penalty of **1.5%** of the principal is deducted.
  $$\text{Refund} = P - (P \times 0.015)$$
* **2 to 5 years:** A penalty of **1%** of the principal is deducted.
  $$\text{Refund} = P - (P \times 0.01)$$
* **Extended Account:** If extended after the initial 5-year maturity, it can be closed at any time without penalty after 1 year of extension. 

### Kisan Vikas Patra (KVP)
* **Rule:** Premature closure allowed only after **2 years and 6 months (30 months)** from the date of issue.
* **Penalty:** Payout is governed strictly by a pre-determined surrender value table published by the Ministry of Finance corresponding to the date of closure. It may also be closed earlier under special circumstances (death of holder, court order, or forfeiture to pledgee).

### National Savings Certificate (NSC)
* **Rule:** Premature closure is **not allowed** before the 5-year maturity period except under specific extreme circumstances (e.g., death of a single account holder or all joint account holders, forfeiture by a pledgee, or a court order).

### Mahila Samman Savings Certificate (MSSC)
* **General Rule:** Can be closed without penalty only in case of the death of the account holder.
* **Compassionate Grounds:** Allowed in case of extreme compassionate grounds (life-threatening disease of account holder or death of guardian). No penalty; normal rate applies.
* **Voluntary Premature Closure:** Allowed after **6 months** of account opening without citing a reason.
* **Penalty for Voluntary Closure:** A penalty of **2%** on the interest rate is applied (e.g., interest will be calculated at 5.5% instead of the standard 7.5%).

### Public Provident Fund (PPF)
* **Rule:** Premature closure is allowed only after **5 completed financial years** from the end of the year in which the account was opened.
* **Conditions:** Allowed only under specific grounds (treatment of life-threatening disease, higher education, or change of residency status/NRI).
* **Penalty:** A penal deduction of **1%** from the standard interest rate applies retrospectively from the date of account opening.

---

## 6. Rebate Formula for Advance RD Deposits

The Post Office offers an upfront cash rebate for paying multiple RD installments in advance.
* **Rule:** Minimum **6 advance installments** are required to qualify.
* **Formulas:**
  * **6 to 11 months advance:** Rebate is ₹10 for every ₹100 denomination.
    $$\text{Rebate} = \left(\frac{\text{Denomination}}{100}\right) \times 10$$
  * **12 months advance:** Rebate is ₹40 for every ₹100 denomination.
    $$\text{Rebate} = \left(\frac{\text{Denomination}}{100}\right) \times 40$$
  * *Note: For deposits exceeding 12 months, the rebate applies in multiples of 12. For example, 18 months paid in advance yields a rebate for 12 months + 6 months: ₹40 + ₹10 = ₹50 per ₹100 denomination.*
