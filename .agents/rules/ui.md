# UI & Presentation Layer Conventions

## 1. Core Principles
- **Dumb Widgets**: Widgets are strictly for displaying data and capturing user input. No API calls or complex logic inside widgets.
- **Design language**: Material 3 Expressive, across the whole app. A screen must not mix Expressive and plain Material 3 components.
- **Official widgets first**: Use the official `material_ui` widget when it has the Expressive variant, or when the Expressive spec leaves the component unchanged. Today that is `IconButton` and `ElevatedButton` (opted in through the theme with `StyleVariant.material3Expressive`), `MaterialShapes` / `MaterialShapeBorder`, `Springs`, and text fields, chips, pickers, `SearchBar`, checkboxes and switches.
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
- **Surfaces by role**: Content is separated by tone, not by outlines or dividers. Use `colorScheme.page` (scaffold, bars), `.raised` (rows and cards on the page) and `.inset` (fields and tiles inside a raised container) from `lib/core/theme/app_surfaces.dart`.
- **Grouped rows**: Lists and sections are `AppGroup` / `AppGroupTile` / `AppGroupListView` (`lib/core/widgets/expressive/app_group.dart`). Plain `Card`, `ListTile`, `ExpansionTile` and a `Divider` between rows are not used.
- **Large text**: `AppDimensions.isLargeText(context)` (text scale above `AppDimensions.largeTextScale`, 1.3) is the one switch for rows that cannot stay side by side. Above it each part takes its own line. Do not define a local threshold.
- **Colour roles**: Red (`error`, `AppFinancialColors.overdue`) marks what is overdue or in error, and destructive actions. It is not the colour of a routine action (Collect is the brand colour) or of the agent's own money (`AppFinancialColors.fronted`).
- **Avatar shapes**: Shapes are decoration, not a code (Material's shape guidance: a shape has no fixed meaning; the Expressive shapes are for avatars and image crops). A customer's avatar is `AppAvatarShape.forPerson(name)`. A deposit's is `schemeType.avatarShape`, with the scheme written inside. An icon that stands for neither is `AppAvatarShape.neutral`. Never let a shape be the only thing that says a status, a payment mode or a scheme.
- **Spacing steps**: 16dp is the page margin, the inset of a card's content, the gap between two blocks of a detail screen or two sections of a form (a section title adds its own 8dp), and the gap between form fields. 12dp separates the blocks above a list (switcher, tiles, search pill, filters). 8dp separates tiles side by side. 2dp separates the rows of a group (`AppShapes.groupGap`).
- **Touch padding is part of the gap**: a 40dp pill sits 4dp inside its 48dp touch target. Two rows of pills with 4dp between their targets are 12dp apart to the eye; with 8dp and then 0dp they look uneven. Count it when spacing buttons, and when something is centred against a button.
- **Edges line up**: a tile's text starts where a row's avatar starts (16dp in). An app bar's last icon ends on the page margin. Whatever ends a row (chevron, copy button) is centred on one axis. A two-line row is `AppDimensions.rowMinHeight` tall whatever it ends with.
- **Strips that scroll sideways**: when every item fits, the items share the width; otherwise size them so that half of the next one shows. Never let an item end on the window's edge.
- **Status stripe**: `EntityListTile.indicatorColor` is a stripe down the row's full height, cut by the row's corners. Do not draw a shorter bar with its own rounded ends against a rounded card.
- **Localization**: No hardcoded strings. Use **Slang** i18n system.
- **Icons**: Use `hugeicons` library exclusively. `HugeIcon` is a widget, not `IconData`, so community APIs that take `IconData` cannot be used.

## 4. UI Implementation Gotchas
- **Ephemeral State**: Use `flutter_hooks` (`useTextEditingController`, `useState`) for purely local UI state.
- **ListTile Trailing Height**: `ListTile` has a `56.0` height limit for `trailing`. If a complex/tall trailing widget is needed, build a custom row using `InkWell`.
- **Adaptive Overlays**: BottomSheets on mobile should become Dialogs or side-panels on Desktop. Open every sheet with `AppAdaptiveSheet.show`; do not call `showModalBottomSheet` directly. It opens the sheet on the root navigator: a sheet pushed from a tab's own screen would otherwise end above the navigation bar and leave the bar bright and tappable.
- **Choosing among a few options**: one of them is an `AppButtonGroup`, any number of them is `AppButtonGroup.multi`. A single on/off choice, or independent ones that wrap, are `AppButton.toggle`.
- **Chips**: suggestions that fill a field, such as the collect sheet's quick amounts, are the official `ChoiceChip` (the community chip has no tap action for a screen reader). The theme gives a chosen chip the colours of a selected segment and no tick: a tick widens the chip, which on a 360dp phone pushes the next chip to a new line and moves everything under the chips. A chip cuts a label that does not fit, so a label that carries an amount goes in a `FittedBox(fit: BoxFit.scaleDown)`. Lines of chips need a `runSpacing` at large text, where a chip fills its touch target.
- **Standalone toggles**: use `AppButton.toggle`, not `M3EButton(isSelected:)`. Outside a group the community toggle is about twice as wide as its label.
- **Skeletonizer**: Use for loading states.
- **Check layouts where they are used**: render a screen at 360x800 and through the router on a 412x915 window with system bars (36dp above, 24dp below) and the navigation bar. A strip, a row of tiles or a hint can be right at one width and wrong at the other.
- **Community widget sizing**: `material_3_expressive` button groups and split buttons are 40dp tall and its navigation bar does not cap text scaling. The `App*` wrappers add the 48dp touch target and the text-scale cap; do not bypass them. `test/core/expressive_widgets_test.dart` holds the wrappers to this.
- **Labels are never cut**: `AppButton`, `AppButtonGroup` and `AppBarTitle` scale a label down when it does not fit. Button labels carry amounts, and an ellipsis there hides the money. Do not put a `Text` with `TextOverflow.ellipsis` on an amount.
- **Tooltips**: Pass `tooltip:` to the `App*` wrapper, or use the official `Tooltip`. The wrappers merge it into the button's semantics node, so an icon-only control is named by its tooltip, as with the official `IconButton`, and `find.byTooltip` finds it. The community package's own tooltip does neither.
- **Icon buttons in an app bar**: `AppBar` wraps its actions in an `IconTheme`, and `IconButton` takes that colour ahead of the filled and tonal variants' defaults. Set `style: IconButton.styleFrom(foregroundColor: …)` on `IconButton.filled` / `.filledTonal` there.
- **Full-width buttons in rows that grow**: In a list row, which is as wide as the window on desktop, cap a full-width button at `AppDimensions.buttonMaxWidth` and align it to the end.
- **Rows say a thing once**: A row shows a figure once (on the action that carries it, when there is one), one inline action beside its menu, and a status badge only when the status is not the usual one.
- **Detail header**: `EntityDetailHeader` is one row (avatar, name, supporting line, badge), with `footer` for a full-width block under it. Do not centre a hero above the content.
- **Pull to refresh**: every screen that shows loaded data can be pulled down to reload it: the lists (`EntityListBody.onRefresh`), the dashboard, the Hub, and the detail screens (`EntityDetailScaffold.onRefresh`, which invalidates what that screen reads). Use `AppRefreshIndicator`.
- **Detail screen actions**: Edit is the app bar's button. Everything else is a labelled entry of the menu (`EntityDetailScaffold.menuActions`), above Delete.
- **Forms**: The body of a create / edit screen is `FormScreenBody`: the fields scroll and one Confirm button stays under them, above the keyboard. `FormAppBar` has no save action. Build a field's label through `AppLabeledField` (as `AppTextField` and `AppDropdownField` do), so it moves above the field above 1.3x text instead of being cut.
- **Search hints**: Give `AppSearchBar` the hint that says what can be searched. It shows it when it fits on one line and "Search..." otherwise.
- **Text buttons under a title**: `AppButton.text(flushStart: true)` starts the label on the title's edge.

## 5. Motion
- **From the packages, not by hand**: motion comes from what `material_ui`, `animations`, `flutter_animate` and the components behind the `App*` wrappers already provide, on the `AppMotion` tokens. Do not write a transition or an animated container of our own without asking the owner; note the gap in `tasks.md` instead.
- **Page transitions**: set once, in `AppTheme`, for every platform: Android the predictive back transition (follows the finger on a back swipe, fades forwards on a tap), iOS the platform's own (it carries the swipe back from the edge), desktop a horizontal shared axis. Do not give a route a transition of its own, and do not give iOS one without a back gesture. On Android both screens are drawn live while the transition runs (`allowSnapshotting: false`): the default animates a picture of each screen taken on its first frame, which hides what fades in on the new screen and keeps in the list what has set out for it. `test/core/page_transitions_test.dart` checks all of this.
- **Dialogs**: ask through `AppDialogs` (confirm a delete, confirm an action, show an error). It opens the community dialog through `AppDialog` (`lib/core/widgets/expressive/app_dialog.dart`), which springs in, opens over the navigation bar and stacks its actions when they do not fit. Do not call `showDialog` with an `AlertDialog`. The dialog a sheet becomes on a wide window is still the official one.
- **Menus**: every menu is an `AppMenu` (`lib/core/widgets/expressive/app_menu.dart`), the community menu, which springs open from its anchor and closes on back. Do not use `MenuAnchor`, `PopupMenuButton` or `M3EMenu` directly: the wrapper sizes the menu to its longest label (the community one is 224dp wide from an icon button and cuts what does not fit). `test/core/app_menu_test.dart` fails on a menu that bypasses it.
