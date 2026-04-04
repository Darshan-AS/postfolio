import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class IntentService {
  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> launchPhone(String phone) async {
    await _launchUrl('tel:$phone');
  }

  Future<void> launchSms(String phone) async {
    await _launchUrl('sms:$phone');
  }

  Future<void> launchMapSearch(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    await _launchUrl('https://maps.google.com/?q=$encodedQuery');
  }
}

final intentServiceProvider = Provider<IntentService>((ref) {
  return IntentService();
});