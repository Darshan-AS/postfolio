import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UserCard extends StatelessWidget {
  final String name;
  final String phone;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.name,
    required this.phone,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              phone,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.grey[700],
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[400],
                  onPressed: onDelete,
                ),
                IconButton(
                  icon: const Icon(Icons.phone_outlined),
                  color: Colors.grey[700],
                  onPressed: () => _launchUrl('tel:$phone'),
                ),
                IconButton(
                  icon: const Icon(Icons.message_outlined),
                  color: Colors.grey[700],
                  onPressed: () => _launchUrl('sms:$phone'),
                ),
                IconButton(
                  icon: const Icon(Icons.location_on_outlined),
                  color: Colors.grey[700],
                  // Example map query based on name or address, using a generic geo url
                  onPressed: () => _launchUrl('https://maps.google.com/?q=$name'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
