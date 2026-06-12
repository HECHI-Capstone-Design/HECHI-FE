import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/mainpage_controller.dart';
import '../../reading_registration/controllers/book_stopper_controller.dart';
import '../../reading_registration/controllers/hardware_camera_controller.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../notification/pages/notification_page.dart';
import 'book_stopper_connection_sheet.dart';
import 'hardware_camera_connection_sheet.dart';

class MainAppBar extends GetView<MainpageController> implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final notifController = Get.find<NotificationController>();
    final stopperController = Get.find<BookStopperController>();
    final cameraController = Get.find<HardwareCameraController>();

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
            Obx(
              () => IconButton(
                icon: Icon(
                  cameraController.isConnected
                      ? Icons.photo_camera
                      : Icons.photo_camera_outlined,
                  color: cameraController.isConnected
                      ? AppColors.primary
                      : AppColors.textHint,
                ),
                tooltip: cameraController.isConnected
                    ? "하이라이트 카메라 연결됨"
                    : "하이라이트 카메라 연결",
                onPressed: () {
                  Get.bottomSheet(
                    const HardwareCameraConnectionSheet(),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                  );
                },
              ),
            ),
            const SizedBox(width: 2),
            Obx(
              () => IconButton(
                icon: Icon(
                  stopperController.isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth,
                  color: stopperController.isConnected
                      ? AppColors.primary
                      : AppColors.textHint,
                ),
                tooltip: stopperController.isConnected ? "북스토퍼 연결됨" : "북스토퍼 연결",
                onPressed: () {
                  Get.bottomSheet(
                    const BookStopperConnectionSheet(),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
          ],
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
