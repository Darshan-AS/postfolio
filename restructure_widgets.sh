#!/bin/bash

# Create directories
mkdir -p lib/core/widgets/{layout,forms,domain,feedback,common}

# Move files
mv lib/core/widgets/shell_app_bar.dart lib/core/widgets/layout/
mv lib/core/widgets/form_app_bar.dart lib/core/widgets/layout/
mv lib/core/widgets/detail_components.dart lib/core/widgets/layout/
mv lib/core/widgets/entity_detail_scaffold.dart lib/core/widgets/layout/
mv lib/core/widgets/entity_list_tile.dart lib/core/widgets/layout/

mv lib/core/widgets/app_form_fields.dart lib/core/widgets/forms/
mv lib/core/widgets/app_duration_input.dart lib/core/widgets/forms/
mv lib/core/widgets/app_search_bar.dart lib/core/widgets/forms/

mv lib/core/widgets/investment_projection_card.dart lib/core/widgets/domain/
mv lib/core/widgets/income_generation_grid.dart lib/core/widgets/domain/
mv lib/core/widgets/wealth_accumulation_grid.dart lib/core/widgets/domain/
mv lib/core/widgets/nominees_input_section.dart lib/core/widgets/domain/
mv lib/core/widgets/nominees_detail_section.dart lib/core/widgets/domain/
mv lib/core/widgets/nominee_form_hook.dart lib/core/widgets/domain/

mv lib/core/widgets/async_entity_builder.dart lib/core/widgets/feedback/
mv lib/core/widgets/app_dialogs.dart lib/core/widgets/feedback/
mv lib/core/widgets/error_state_view.dart lib/core/widgets/feedback/
mv lib/core/widgets/app_filter_bottom_sheet.dart lib/core/widgets/feedback/
mv lib/core/widgets/app_sort_bottom_sheet.dart lib/core/widgets/feedback/
mv lib/core/widgets/app_filter_section.dart lib/core/widgets/feedback/

mv lib/core/widgets/accessible_theme_toggle.dart lib/core/widgets/common/
mv lib/core/widgets/demo_banner.dart lib/core/widgets/common/

# Replace imports across all dart files
find lib -type f -name "*.dart" -exec perl -pi -e 's|package:postfolio/core/widgets/(shell_app_bar\.dart\|form_app_bar\.dart\|detail_components\.dart\|entity_detail_scaffold\.dart\|entity_list_tile\.dart)|package:postfolio/core/widgets/layout/$1|g' {} +
find lib -type f -name "*.dart" -exec perl -pi -e 's|package:postfolio/core/widgets/(app_form_fields\.dart\|app_duration_input\.dart\|app_search_bar\.dart)|package:postfolio/core/widgets/forms/$1|g' {} +
find lib -type f -name "*.dart" -exec perl -pi -e 's|package:postfolio/core/widgets/(investment_projection_card\.dart\|income_generation_grid\.dart\|wealth_accumulation_grid\.dart\|nominees_input_section\.dart\|nominees_detail_section\.dart\|nominee_form_hook\.dart)|package:postfolio/core/widgets/domain/$1|g' {} +
find lib -type f -name "*.dart" -exec perl -pi -e 's|package:postfolio/core/widgets/(async_entity_builder\.dart\|app_dialogs\.dart\|error_state_view\.dart\|app_filter_bottom_sheet\.dart\|app_sort_bottom_sheet\.dart\|app_filter_section\.dart)|package:postfolio/core/widgets/feedback/$1|g' {} +
find lib -type f -name "*.dart" -exec perl -pi -e 's|package:postfolio/core/widgets/(accessible_theme_toggle\.dart\|demo_banner\.dart)|package:postfolio/core/widgets/common/$1|g' {} +

