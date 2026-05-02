# Project Progress

## Current State
- Set up core architecture with Riverpod, Freezed, and standard thematic elements.
- Implemented robust `HugeIcon` usage throughout the UI, standardizing visual sizes for list tiles, app bars, detail views, and forms.
- Initiated transition to automatic domain mathematical calculations for Small Savings Schemes. 
- Created strictly typed, immutable models (`InvestmentProjection`, `PayoutFrequency`) and functional pure utilities (`ProjectionCalculator`) to handle complex interest and compounding math dynamically.

## Next Steps
- **Refactor Deposit Models**: Update `BaseDeposit`, `OneTimeDeposit` and `RecurringDeposit` to replace stored `maturityDate` and `maturityAmount` fields with dynamic getters referencing `ProjectionCalculator`.
- **Live Preview UI**: Build an `InvestmentProjectionCard` and use Riverpod Form Notifiers to drive dynamic preview recalculations before saving deposits.
- **Implement Commission Logic**: Add the next set of domain math features to automatically deduce gross/net commissions and TDS.
