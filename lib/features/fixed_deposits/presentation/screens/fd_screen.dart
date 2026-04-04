import 'package:flutter/material.dart';
import 'package:postfolio/i18n/strings.g.dart';

class FixedDepositsScreen extends StatelessWidget {
  const FixedDepositsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.nav.deposits)),
      body: Center(child: Text(t.deposits.list)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
