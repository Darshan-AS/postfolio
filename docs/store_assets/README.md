# Play Store Assets Checklist

All Google Play Store assets are tracked here and generated deterministically from the real M3 Expressive UI.

## 🖼️ Store Graphics
- [x] **App Icon**: `docs/store_assets/icon_512.png` (512 × 512 px PNG).
- [x] **Feature Graphic**: `docs/store_assets/feature_graphic_1024x500.png` (1024 × 500 px opaque 24-bit RGB PNG).
- [x] **Phone Screenshots (`docs/store_assets/phone_screenshots/`)**: 7 framed marketing slides (`1080 × 1920` px, opaque 24-bit RGB PNG, no alpha):
  1. `01_monthly_hub.png` — RD Monthly Hub (Light, Royal Blue backdrop)
  2. `02_dashboard.png` — Portfolio Dashboard & Deposits Over Time chart (Light, Soft Ice backdrop)
  3. `03_po_visit_planner.png` — Batch Post Office Visit Planner & ₹20k cash lot split (Light, Royal Blue backdrop)
  4. `04_rd_passbook.png` — RD Passbook & Monthly Installment Schedule (Light, Soft Ice backdrop)
  5. `05_one_time_deposits.png` — TD, MIS, NSC & KVP One-Time Deposits (Light, Royal Blue backdrop)
  6. `06_customer_profile.png` — Customer Savings Account, Nominees & Linked Deposits (Light, Soft Ice backdrop)
  7. `07_dark_mode.png` — RD Monthly Hub in Dark Theme (Dark, Midnight backdrop)
- [x] **Landscape Hero Screenshot (`docs/store_assets/landscape_screenshots/`)**: 1 dual-phone showcase (`1920 × 1080` px, opaque 24-bit RGB PNG, no alpha) for Play Store featuring criteria:
  1. `01_overview_landscape.png` — Light Monthly Hub + Dark Dashboard side-by-side
- [ ] **7-inch / 10-inch Tablet Screenshots**: Optional (not required for initial launch).

## 🔄 Regenerating After UI Changes
Whenever screens or copy change, regenerate every store slide directly from `FakeDataSource.forDate` (no Demo Mode banner, no emulator required):

```bash
flutter test tool/store_screenshots/generate_store_screenshots_test.dart --update-goldens
```

Or run the VS Code task **`Store: regenerate Play Store screenshots`**.

Source files:
- [`tool/store_screenshots/generate_store_screenshots_test.dart`](../../tool/store_screenshots/generate_store_screenshots_test.dart) — slide definitions & deterministic fixture overrides
- [`tool/store_screenshots/marketing_frame.dart`](../../tool/store_screenshots/marketing_frame.dart) — royal-blue wave backdrop, headlines, and Pixel hardware bezel
- [`tool/store_screenshots/screenshot_fonts.dart`](../../tool/store_screenshots/screenshot_fonts.dart) — SDK `Roboto` + `MaterialIcons` + `₹` fallback loader
- [`tool/store_screenshots/opaque_png.dart`](../../tool/store_screenshots/opaque_png.dart) — 24-bit opaque RGB PNG writer (Play Console compliant)

## 📝 Metadata & Play Store Sync
- [x] **Copy & URLs**: See [`docs/store_assets/listing_metadata.md`](listing_metadata.md) (App Name, Short Description, Full Description, Category `Finance`, Website `https://postfolio.darshanas.dev`).
- [x] **Fastlane `supply` Copy**: Canonical Play Store text files live in [`android/fastlane/metadata/android/en-US/`](../../android/fastlane/metadata/android/en-US/).
- [x] **CI Sync Workflow**: Run **Actions → Sync Google Play Store Listing** ([`.github/workflows/sync-store-listing.yml`](../../.github/workflows/sync-store-listing.yml)) — defaults to `validate_only: true` dry run before pushing changes to Play Console.

## ⚖️ Legal
- [x] **Privacy Policy**: [`docs/legal/privacy_policy.md`](../legal/privacy_policy.md) and hosted static page [`web/privacy-policy.html`](../../web/privacy-policy.html) (`https://postfolio.darshanas.dev/privacy-policy.html`).
