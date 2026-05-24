import 'package:flutter/material.dart';
import '../models/notification_item.dart';

class NotificationEmptyState extends StatelessWidget {
  final String message;

  const NotificationEmptyState({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none, size: 52, color: kNotifBorder),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: kNotifTextGrey, fontSize: 14)),
        ],
      ),
    );
  }
}