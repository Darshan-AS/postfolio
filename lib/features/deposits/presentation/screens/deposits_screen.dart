import 'package:flutter/material.dart';
import 'package:postfolio/l10n/app_localizations.dart';

class DepositsScreen extends StatelessWidget {
  const DepositsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deposits),
      ),
      body: Center(
        child: Text(l10n.depositsList),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
