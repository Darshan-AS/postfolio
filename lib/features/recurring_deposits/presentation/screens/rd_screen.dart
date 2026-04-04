import 'package:flutter/material.dart';
import 'package:postfolio/l10n/app_localizations.dart';

class RdScreen extends StatelessWidget {
  const RdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringDeposits),
      ),
      body: Center(
        child: Text(l10n.rdList),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
