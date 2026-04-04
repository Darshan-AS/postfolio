import 'package:flutter/material.dart';
import 'package:postfolio/i18n/strings.g.dart';

class DepositsScreen extends StatelessWidget {
  const DepositsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      appBar: AppBar(
        title: Text(t.deposits),
      ),
      body: Center(
        child: Text(t.depositsList),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
