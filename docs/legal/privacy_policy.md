# Privacy Policy for Postfolio

*Last Updated: 2026-11-20*

Postfolio ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and share information when you use our mobile and web applications.

> **Disclaimer:** Postfolio is an independent portfolio and record-keeping tool built for Post Office agents. It is **not** affiliated with, endorsed by, or connected to India Post or the Government of India.

## 1. Information We Collect
- **Authentication Data**: We use Supabase Auth with Google Sign-In to manage user accounts (storing your name and email address).
- **Financial & Customer Records**: Data you enter about customers, deposits, and recurring-deposit ledger records is stored in PostgreSQL (hosted on Supabase) and isolated strictly to your authenticated account using Row-Level Security (RLS).
- **Crash & Error Diagnostics**: On native mobile and desktop platforms, we collect crash reports via Firebase Crashlytics. On the web, sanitized client error diagnostics (rate-limited and truncated) are logged to help diagnose failures. We do not collect advertising identifiers or sell your data.

## 2. Data Storage & Security
Your data is stored on Supabase's managed PostgreSQL infrastructure with TLS encryption in transit and row-level isolation per user account. We do not sell or share your customer or financial data with third parties.

## 3. Demo Mode
When you use Demo Mode, the app runs entirely on synthetic in-memory sample data; nothing entered in Demo Mode is sent to or saved in the cloud.

## 4. Account & Data Deletion
You may request deletion of your Postfolio account and all associated customer, deposit, and ledger data at any time by emailing **itisdarshan@gmail.com** from the Google account email you use to sign in, with the subject line **"Postfolio Account Deletion Request"**. We will permanently delete your account and associated records from our database within 7 days and confirm via email.

## 5. Contact Us
If you have any questions about this Privacy Policy or your data, contact us at: [itisdarshan@gmail.com](mailto:itisdarshan@gmail.com)
