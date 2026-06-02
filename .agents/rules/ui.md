# UI & Presentation Layer Conventions

## 1. Core Principles
- **Dumb Widgets**: Widgets are strictly for displaying data and capturing user input. No API calls or complex logic inside widgets.
- **Official Widget Priority**: Always prefer official Material 3 widgets (e.g., `SearchBar`, `SegmentedButton`, `FilterChip`).
- **Responsive Architecture**: Use `flutter_adaptive_scaffold` for structural layouts. Avoid `flutter_screenutil` (prohibited).

## 2. Standardized Formatting
Use centralized Dart extensions in `lib/core/extensions/`:
- **DateTime**: `.toAppFormat()`, `.toCompactFormat()`.
- **Currency**: `.toRupeeFormat()`.
- **Strings**: `.toPhoneFormat()`, `.toAadhaarFormat()`, `.toPanFormat()`.

## 3. Styling & Theming
- **No Magic Numbers**: Do not hardcode breakpoints, paddings, or colors. Use `Theme.of(context)` or `AppDimensions`.
- **Localization**: No hardcoded strings. Use **Slang** i18n system.
- **Icons**: Use `hugeicons` library exclusively.

## 4. UI Implementation Gotchas
- **Ephemeral State**: Use `flutter_hooks` (`useTextEditingController`, `useState`) for purely local UI state.
- **ListTile Trailing Height**: `ListTile` has a `56.0` height limit for `trailing`. If a complex/tall trailing widget is needed, build a custom row using `InkWell`.
- **Adaptive Overlays**: BottomSheets on mobile should become Dialogs or side-panels on Desktop.
- **Skeletonizer**: Use for loading states.
