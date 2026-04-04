import 'package:flutter/material.dart';
import 'package:postfolio/i18n/strings.g.dart';

class RecurringDepositsScreen extends StatelessWidget {
  const RecurringDepositsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.nav.recurringDeposits)),
      body: Center(child: Text(t.recurringDeposits.list)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
