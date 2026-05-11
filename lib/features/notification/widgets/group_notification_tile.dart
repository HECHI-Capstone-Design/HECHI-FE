import 'package:flutter/material.dart';
import '../models/notification_item.dart';

class GroupNotificationTile extends StatelessWidget {
  final NotificationItem item;

  const GroupNotificationTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(width: 0.5, color: kNotifBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 왼쪽 이미지: 책 or 아바타
          item.imageUrl != null
              ? _BookThumbnail(imageUrl: item.imageUrl!)
              : const _GroupAvatar(),
          const SizedBox(width: 14),
          // 텍스트 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: kNotifGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.timeAgo,
                      style: const TextStyle(
                        color: kNotifTextGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '· ${item.description}',
                  style: const TextStyle(
                    color: kNotifTextMid,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookThumbnail extends StatelessWidget {
  final String imageUrl;

  const _BookThumbnail({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 48,
        height: 48,
        color: const Color(0xFFF3F3F3),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.book, color: kNotifBorder, size: 24),
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: kNotifGreenLight,
        shape: BoxShape.circle,
        border: Border.all(color: kNotifGreen.withOpacity(0.3), width: 1),
      ),
      child: const Icon(Icons.person, color: kNotifGreen, size: 26),
    );
  }
}