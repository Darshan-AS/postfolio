# UI & Presentation Layer Conventions

## 1. Core Principles
- **Dumb Widgets**: Widgets are strictly for displaying data and capturing user input. No API calls or complex logic inside widgets.
- **Design language**: Material 3 Expressive, across the whole app. A screen must not mix Expressive and plain Material 3 components.
- **Official widgets first**: Use the official `material_ui` widget when it has the Expressive variant, or when the Expressive spec leaves the component unchanged. Today that is `IconButton` and `ElevatedButton` (opted in through the theme with `StyleVariant.material3Expressive`), `MaterialShapes` / `MaterialShapeBorder`, `Springs`, and text fields, chips, menus, dialogs, pickers, `SearchBar`, checkboxes and switches.
- **Community package only behind wrappers**: For Expressive components `material_ui` does not ship yet, use the `App*` widgets in `lib/core/widgets/expressive/`. They are built on `package:material_3_expressive`.
  - Only files under `lib/core/widgets/expressive/` may import `package:material_3_expressive`. Screens and feature widgets never name an `M3E*` class. `test/core/expressive_import_boundary_test.dart` enforces this.
  - When `material_ui` ships a component's Expressive variant, move that wrapper onto the official widget.
  - `MaterialApp` and `ThemeData` stay the single source of theme. Do not use `M3EMaterialApp`; the community widgets derive their colours from `Theme.of(context)`.
- **Responsive Architecture**: Use `flutter_adaptive_scaffold` for structural layouts. Avoid `flutter_screenutil` (prohibited).

## 2. Standardized Formatting
Use centralized Dart extensions in `lib/core/extensions/`:
- **DateTime**: `.toAppFormat()`, `.toCompactFormat()`.
- **Currency**: `.toRupeeFormat()`.
- **Strings**: `.toPhoneFormat()`, `.toAadhaarFormat()`, `.toPanFormat()`.

## 3. Styling & Theming
- **No Magic Numbers**: Do not hardcode breakpoints, paddings, or colors. Use `Theme.of(context)` or `AppDimensions`.
- **Shape and motion tokens**: Corner radii come from `AppShapes`, springs and durations from `AppMotion` (`lib/core/theme/`).
- **Localization**: No hardcoded strings. Use **Slang** i18n system.
- **Icons**: Use `hugeicons` library exclusively. `HugeIcon` is a widget, not `IconData`, so community APIs that take `IconData` cannot be used.

## 4. UI Implementation Gotchas
- **Ephemeral State**: Use `flutter_hooks` (`useTextEditingController`, `useState`) for purely local UI state.
- **ListTile Trailing Height**: `ListTile` has a `56.0` height limit for `trailing`. If a complex/tall trailing widget is needed, build a custom row using `InkWell`.
- **Adaptive Overlays**: BottomSheets on mobile should become Dialogs or side-panels on Desktop.
- **Skeletonizer**: Use for loading states.
- **Community widget sizing**: `material_3_expressive` button groups and split buttons are 40dp tall and its navigation bar does not cap text scaling. The `App*` wrappers add the 48dp touch target and the text-scale cap; do not bypass them.
