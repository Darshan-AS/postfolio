# Postfolio UI/UX Design Generation Prompts

*This document contains highly detailed, component-level descriptions of the Postfolio app. These prompts are designed to be fed into AI UI generators (like Google Stitch, v0, or Midjourney) to produce high-fidelity mockups.*

**IMPORTANT:** Postfolio is a Flutter application. All generated designs must be practical, feasible, and idiomatically implementable using Flutter's widget catalog (e.g., `SliverAppBar`, `CustomScrollView`, `ListView.builder`, `Card`, `BottomSheet`). Avoid impossible glassmorphism effects or platform-specific paradigms that do not translate well across iOS and Android in a single Flutter codebase.

---

## Global Design System & Theming
**Theme:** Material Design 3 (Material You). Ensure the design language utilizes M3 components (e.g., filled tonal buttons, pill-shaped FABs, prominent surface colors).
**Vibe:** Professional, trustworthy, financial, yet highly accessible and modern.
**Color Palette:** Generate a modern, professional color palette suitable for a financial and banking application. Draw subtle aesthetic inspiration from postal services, but prioritize a clean, high-contrast UI. 
*   **Accessibility Constraint:** The color palette **MUST** be accessible to users with Red-Green color blindness (Deuteranomaly/Protanomaly). 
*   **Semantic Status Colors:** Do not rely purely on standard red/green for financial statuses. Use colorblind-safe palettes (e.g., a strong blue or high-contrast teal for "success/paid", and a distinct high-contrast orange/vermilion or patterned indicators for "due/defaulted"). Always pair color changes with iconography or text labels.
**Typography:** Google Sans or Roboto. Clean, highly legible numbers (tabular lining for financial data).
**Animations:** Fluid Hero transitions when tapping cards, staggered list entrances, and satisfying micro-interactions for logging money (e.g., a subtle confetti or checkmark bounce when a collection is saved).

---

## Screen 1: The Dashboard (Home Screen)
**Purpose:** The daily command center for the agent.
**Visual Layout:**
*   **App Bar:** Top left has a warm greeting ("Good Morning, Anjali!"). Top right has a circular avatar profile picture. Background is the surface color (no heavy app bar shadow).
*   **Hero Card (Daily Cash In Hand):** A large, elevated Material card with a subtle gradient or solid theme color. 
    *   *Content:* Large bold text displaying today's collected amount (e.g., "₹ 14,500"). 
    *   *Subtitle:* "Total cash to deposit today."
    *   *Animation:* The number should count up when the app opens.
*   **Monthly Target Section:**
    *   A horizontal layout containing a linear progress bar with rounded corners.
    *   *Labels:* "Monthly Target: ₹ 50,000" / "Collected: ₹ 32,000".
*   **Quick Actions Row:** A horizontal scrolling row of filled tonal buttons or chips: "Log Collection" (Icon: Plus), "New Customer" (Icon: Person Add), "View Ledger" (Icon: Book).
*   **Section Header:** "Pending Collections Today".
*   **List View:** 3-4 compact list tiles showing customers whose RD (Recurring Deposit) is due today. Each tile has a rounded avatar, name, due amount, and a trailing "Collect" text button.

## Screen 2: Customer Directory (Customers Tab)
**Purpose:** A searchable rolodex of all clients.
**Visual Layout:**
*   **App Bar:** Prominent search bar expanding across the top ("Search by name or account...").
*   **Filter Chips:** A horizontal scrolling row of filter chips below the search bar: "All", "RD Due", "Defaulters", "Matured Soon".
*   **List View (Customers):** 
    *   Staggered fade-in animation on load.
    *   Each list item is a standard Material `ListItem`.
    *   *Leading:* Circular avatar with user initials.
    *   *Body:* Customer Name in bold, Phone number in grey subtext. (Fields to accommodate: `name`, `phone`).
    *   *Trailing:* A status dot (semantic colors for up-to-date or due) and a chevron arrow.
*   **Floating Action Button (FAB):** Large, prominent FAB in the bottom right with a "+" icon for adding a new customer.

### 2A. Customer Creation Form
**Visual Layout:**
*   **App Bar:** "Add New Customer".
*   **Form Fields:** Ensure standard Material 3 text fields with proper input types.
    *   Full Name (Required)
    *   Phone Number (Numeric)
    *   Email Address
    *   Physical Address (Multiline)
    *   CIF Number (Customer Information File Number)
    *   Date of Birth (Date Picker)
    *   Aadhaar Number (12 digits)
    *   PAN Number (Alphanumeric)
    *   **Post Office Savings Account Section (Optional):**
        *   Savings Account Number
        *   Nominee Name
        *   Nominee Relationship

## Screen 3: Customer Profile & Accounts
**Purpose:** Detailed view of a single customer's portfolio.
**Visual Layout:**
*   **Header Profile:** 
    *   Large avatar centered. Name directly below it.
    *   Row of 3 icon buttons: Call (Phone icon), WhatsApp (Chat icon), Edit (Pencil icon).
    *   *Expandable Details Card:* Should show `CIF Number`, `Phone`, `Email`, `Address`, `DOB`, `Aadhaar`, `PAN`, and `Savings Account Info`.
*   **Tabs (Sticky):** "Active Accounts" | "History".
*   **Active Accounts List (Cards):**
    *   Each account (e.g., "Recurring Deposit - 5 Years") is a distinct, elevated card.
    *   *Card Header:* Scheme Name & Account Number (e.g., `RD • xxxx4592`).
    *   *Card Body:* A grid showing "Monthly Installment: ₹ 1,000", "Balance: ₹ 12,000".
    *   *Visual element:* A circular progress indicator showing how close the account is to maturity (e.g., "12/60 Months").
    *   *Action Area:* A bottom bar on the card with a primary tonal button: "Log Payment".

## Screen 4: "Log Collection" Bottom Sheet
**Purpose:** The critical flow where the agent records receiving cash.
**Visual Layout:**
*   **Container:** A modal bottom sheet with rounded top corners, sliding smoothly up from the bottom of the screen.
*   **Header:** "Log Collection for [Customer Name]", with a close 'X' on the top right.
*   **Amount Input:** 
    *   A massive, centered text field. The currency symbol (₹) is fixed.
    *   The text field should look like a prominent calculator display.
*   **Helper Chips:** Below the input, quick-select chips for standard amounts: "+ ₹1000 (1 Month)", "+ ₹2000 (2 Months)".
*   **Date Picker Row:** A row showing "Collection Date" defaulting to "Today", with a calendar icon to change it.
*   **Dynamic Alert Box:** If the agent enters an amount covering 3+ months, a small animated banner slides down saying "Advance Rebate Applicable: -₹50".
*   **Submit Button:** A full-width, pill-shaped primary button anchored to the bottom. "Confirm Collection".
*   **Animation:** On tap, the button text fades to a loading spinner, then transforms into a green checkmark before the bottom sheet elegantly slides away.

## Screen 5: Commission Projections (Analytics)
**Purpose:** Shows the agent how much money they are making.
**Visual Layout:**
*   **App Bar:** "My Earnings", centered text.
*   **Main Graphic:** A beautiful, smooth curved line chart or a modern bar chart showing earnings over the last 6 months. Use a glowing gradient fill under the line.
*   **Summary Cards (Grid):**
    *   Two side-by-side square cards.
    *   *Card 1:* "Projected This Month" (₹ 4,500) - Font colored in a prominent, accent color.
    *   *Card 2:* "TDS Deducted (2%)" (₹ 90) - Font colored in subtle grey.
*   **Breakdown List:**
    *   A list breaking down commissions by scheme type.
    *   "Recurring Deposits (4%) ............ ₹ 4,000"
    *   "Time Deposits (0.5%) ................ ₹ 500"

---

## Screen 6: Deposit Scheme Management (RD & One-Time)
**Purpose:** Dedicated tabs or sections to view, filter, and manage all deposit schemes across all customers. 
**Design Priority:** This is one of the most critical and frequently used views in the app. The list, detail, and form views must be highly optimized for fast data entry, clear readability of financial numbers, and flawless UX.

### 6A. Recurring Deposits (RD) Tracker
**Visual Layout:**
*   **App Bar:** "Recurring Deposits", with a filter/sort icon.
*   **Summary Header:** A sticky header showing "Total Active RDs: 42" and "Monthly Target: ₹ 85,000".
*   **List View (RD Accounts):**
    *   Standard `ListItem` or compact `Card`.
    *   *Leading:* Icon representing RD (e.g., repeating arrows).
    *   *Body:* Customer Name, Account Number (e.g., `xxxx4592`).
    *   *Trailing:* Installment Amount (e.g., "₹ 2,000") with status indicator.
*   **FAB:** "+" icon to link a new RD to a customer.

### 6B. One-Time Deposits Tracker
**Visual Layout:**
*   **App Bar:** "One-Time Deposits" (TD, MIS, KVP, NSC).
*   **Filter Chips:** "All", "Maturing Soon", "Matured".
*   **List View (One-Time Accounts):**
    *   *Leading:* Icon representing a certificate or vault.
    *   *Body:* Customer Name, Scheme Type (e.g., "Time Deposit - 5 Yr"). Includes Row ID if applicable.
    *   *Trailing:* Principal Amount (e.g., "₹ 50,000").
    *   *Subtitle:* Maturity Date with a visual progress bar indicating time left until maturity.

### 6C. Deposit Creation Forms
**Purpose:** Forms to register a new RD or One-Time deposit, matching the exact domain models.

**Recurring Deposit (RD) Form Layout:**
*   Customer Selection (Searchable Dropdown).
*   Scheme Type (Fixed to: Recurring Deposit).
*   Account Number (`accountNo` text field).
*   Installment Amount (`installmentAmount` numeric field).
*   Term (`termYears` and `termMonths` numeric fields).
*   Interest Rate (`interestRate` numeric field).
*   Maturity Amount (`maturityAmount` numeric field).
*   Dates (`startDate` and `maturityDate` date pickers).
*   Linked Auto-Debit Account (`linkedAutoDebitAccountNo` text field).
*   Nominees Section (Dynamic list to add Nominee Name, Relationship, and Share %).

**One-Time Deposit Form Layout:**
*   Customer Selection (Searchable Dropdown).
*   Scheme Type (Dropdown/Segmented: Time Deposit, Monthly Income Scheme, National Savings Certificate, Kisan Vikas Patra).
*   Row ID (`rowId` text field, specific to one-time deposits).
*   Account Number (`accountNo` text field).
*   Principal Amount (`principalAmount` numeric field).
*   Term (`termYears` and `termMonths` numeric fields).
*   Interest Rate (`interestRate` numeric field, defaults to 0.0).
*   Maturity Amount (`maturityAmount` numeric field).
*   Dates (`startDate` and `maturityDate` date pickers).
*   Linked Savings Account (`linkedSavingsAccountNo` text field).
*   Nominees Section (Dynamic list to add Nominee Name, Relationship, and Share %).

### 6D. Deposit Detail Views
**Purpose:** The screen shown when a user taps a specific deposit from the list views.
*   **Header:** Prominent display of the Scheme Type and Account Number.
*   **Financial Summary Card:** Large display of Installment/Principal Amount, Interest Rate, and Maturity Amount.
*   **Term & Dates Card:** Visual timeline or progress bar from `startDate` to `maturityDate`, including `termYears`/`termMonths`.
*   **Linked Accounts:** Display `linkedAutoDebitAccountNo` (for RDs) or `linkedSavingsAccountNo` (for One-Time).
*   **Nominees List:** Cards showing each associated nominee.
