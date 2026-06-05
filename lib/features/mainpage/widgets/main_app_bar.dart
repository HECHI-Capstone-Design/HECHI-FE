import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/mainpage_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../notification/pages/notification_page.dart';

class MainAppBar extends GetView<MainpageController> implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final notifController = Get.find<NotificationController>();

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 20,
      title: Obx(() => Text(
        controller.headerLogo.value,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 28,
          fontFamily: 'Sedgwick Ave Display',
          fontWeight: FontWeight.bold,
        ),
      )),
      actions: [
        Row(
          children: [
            // 알림 아이콘 + 뱃지
            Obx(() {
              final hasUnread = notifController.unreadCount.value > 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      hasUnread ? Icons.notifications : Icons.notifications_none,
                      color: AppColors.primary,
                    ),
                    onPressed: () async {
                      await Get.to(() => const NotificationPage());
                      notifController.fetchUnreadCount();
                    },
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(width: 5),
            const Icon(Icons.bluetooth, color: AppColors.primary),
            const SizedBox(width: 20),
          ],
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
