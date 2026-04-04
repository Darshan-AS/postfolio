import 'package:flutter/material.dart';
import 'package:postfolio/i18n/strings.g.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t.nav.dashboard),
      ),
      body: Center(
        child: Text(t.dashboard.charts),
      ),
    );
  }
}
