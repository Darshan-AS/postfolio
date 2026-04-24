import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'intent_service.g.dart';

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

  Future<void> launchWhatsApp(String phone) async {
    // Clean phone number (remove spaces, dashes, etc. if needed, but we'll assume it's clean enough or handled by wa.me)
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    await _launchUrl('https://wa.me/$cleanPhone');
  }

  Future<void> launchMapSearch(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    await _launchUrl('https://maps.google.com/?q=$encodedQuery');
  }
}

@riverpod
IntentService intentService(Ref ref) {
  return IntentService();
}
