import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:postfolio/core/models/nominee.dart';
import 'package:postfolio/core/theme/app_dimensions.dart';
import 'package:postfolio/core/widgets/detail_components.dart';
import 'package:postfolio/i18n/strings.g.dart';

class NomineesDetailSection extends StatelessWidget {
  final List<Nominee> nominees;

  const NomineesDetailSection({super.key, required this.nominees});

  @override
  Widget build(BuildContext context) {
    if (nominees.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        DetailSection(
          title: t.nominees.title,
          children: [
            for (int i = 0; i < nominees.length; i++) ...[
              DetailItem(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  size: AppDimensions.iconMd,
                ),
                label: nominees[i].relationship,
                value: '${nominees[i].name} (${nominees[i].percentage}%)',
              ),
              if (i < nominees.length - 1) const Divider(height: 1),
            ],
          ],
        ),
        AppSpacings.gapLg,
      ],
    );
  }
}
