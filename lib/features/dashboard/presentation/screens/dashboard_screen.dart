import 'package:flutter/material.dart';
import 'package:postfolio/l10n/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
      ),
      body: Center(
        child: Text(l10n.dashboardCharts),
      ),
    );
  }
}
