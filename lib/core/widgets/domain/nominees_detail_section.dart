import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/common/app_icon.dart';
import 'package:postfolio/core/widgets/layout/detail_components.dart';
import 'package:postfolio/i18n/strings.g.dart';

class NomineesDetailSection extends StatelessWidget {
  final List<Nominee> nominees;

  const NomineesDetailSection({super.key, required this.nominees});

  @override
  Widget build(BuildContext context) {
    if (nominees.isEmpty) return const SizedBox.shrink();

    return DetailSection(
      title: t.nominees.title,
      children: [
        for (final nominee in nominees)
          DetailItem(
            icon: const AppIcon(
              HugeIcons.strokeRoundedUser,
              size: AppDimensions.iconMd,
            ),
            label: nominee.displayRelationship,
            value: '${nominee.name} (${nominee.percentage}%)',
          ),
      ],
    );
  }
}
