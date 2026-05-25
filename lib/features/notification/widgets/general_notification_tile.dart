import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/notification_item.dart';
import '../controllers/notification_controller.dart';

class GeneralNotificationTile extends StatelessWidget {
  final NotificationItem item;

  const GeneralNotificationTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.find<NotificationController>().markAsRead(item.notificationId);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : kNotifGreenLight.withOpacity(0.5),
          border: const Border(bottom: BorderSide(width: 0.5, color: kNotifBorder)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BookThumbnail(imageUrl: item.imageUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: kNotifTextDark, fontSize: 14,
                            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold, height: 1.3,
                          ),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(item.timeAgo, style: const TextStyle(color: kNotifTextGrey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(color: kNotifTextMid, fontSize: 12, height: 1.45),
                    maxLines: 3, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookThumbnail extends StatelessWidget {
  final String? imageUrl;
  const _BookThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 60, height: 80, color: const Color(0xFFF3F3F3),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.book, color: kNotifBorder, size: 28))
            : const Icon(Icons.book, color: kNotifBorder, size: 28),
      ),
    );
  }
}