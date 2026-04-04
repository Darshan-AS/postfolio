import 'package:flutter/material.dart';
import 'package:postfolio/i18n/strings.g.dart';

class RdScreen extends StatelessWidget {
  const RdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.nav.recurringDeposits)),
      body: Center(child: Text(t.rd.list)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
