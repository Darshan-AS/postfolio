# Project Progress

## Current State
- Set up core architecture with Riverpod, Freezed, and standard thematic elements.
- Implemented robust `HugeIcon` usage throughout the UI, standardizing visual sizes for list tiles, app bars, detail views, and forms.
- Migrated the UI layer entirely to `flutter_hooks` and `hooks_riverpod` to eliminate `StatefulWidget` boilerplate and enforce a strictly functional, React-like paradigm for ephemeral UI state.
- Initiated transition to automatic domain mathematical calculations for Small Savings Schemes. 
- Created strictly typed, immutable models (`InvestmentProjection`, `PayoutFrequency`) and functional pure utilities (`ProjectionCalculator`) to handle complex interest and compounding math dynamically.
- Refactored `BaseDeposit`, `OneTimeDeposit` and `RecurringDeposit` models. Removed stored `maturityDate` and `maturityAmount` fields and replaced them with dynamic getters leveraging the `ProjectionCalculator` to ensure functional purity.

## Next Steps
- **Live Preview UI**: Build an `InvestmentProjectionCard` and use Riverpod Form Notifiers to drive dynamic preview recalculations before saving deposits.
- **Implement Commission Logic**: Add the next set of domain math features to automatically deduce gross/net commissions and TDS.
