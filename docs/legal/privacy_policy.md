# Privacy Policy for Postfolio

*Last Updated: 2026-11-19*

Postfolio ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and share information when you use our mobile and web applications.

## 1. Information We Collect
- **Authentication Data**: We use Supabase Auth with Google Sign-In to manage user accounts.
- **Financial Data**: Data you enter about customers, deposits, and recurring-deposit ledger records is stored in PostgreSQL (hosted on Supabase) and isolated strictly to your authenticated account using Row-Level Security (RLS).
- **Crash & Error Diagnostics**: On native mobile and desktop platforms, we collect crash reports via Firebase Crashlytics. On the web, sanitized client error diagnostics (rate-limited and truncated) are logged to help diagnose failures. We do not collect advertising identifiers or sell your data.

## 2. Data Storage & Security
Your data is stored on Supabase's managed PostgreSQL infrastructure with TLS in transit and row-level isolation per user account. We do not sell or share your customer or financial data with third parties.

## 3. Demo Mode
When you use Demo Mode, the app runs entirely on synthetic in-memory sample data; nothing entered in Demo Mode is sent to or saved in the cloud.

## 4. Contact Us
If you have any questions, contact us at: [Your Email]
