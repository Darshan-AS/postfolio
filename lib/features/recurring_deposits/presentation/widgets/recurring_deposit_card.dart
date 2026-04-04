import 'package:flutter/material.dart';
import 'package:postfolio/core/theme/app_theme.dart';

class RecurringDepositCard extends StatelessWidget {
  final String accountNo;
  final double installmentAmount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RecurringDepositCard({
    super.key,
    required this.accountNo,
    required this.installmentAmount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.surface,
        child: Icon(Icons.loop_outlined),
      ),
      title: Text(
        accountNo,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('₹${installmentAmount.toStringAsFixed(2)} / month'),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            onEdit();
          } else if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 20),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: AppTheme.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
