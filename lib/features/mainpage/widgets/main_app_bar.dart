import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../reading_registration/controllers/book_stopper_controller.dart';
import '../../reading_registration/controllers/hardware_camera_controller.dart';
import '../controllers/mainpage_controller.dart';
import '../../notification/pages/notification_page.dart';
import 'book_stopper_connection_sheet.dart';
import 'hardware_camera_connection_sheet.dart';

class MainAppBar extends GetView<MainpageController>
    implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final stopperController = Get.find<BookStopperController>();
    final cameraController = Get.find<HardwareCameraController>();

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 20,
      title: Obx(
        () => Text(
          controller.headerLogo.value,
          style: const TextStyle(
            color: Color(0xFF4DB56C),
            fontSize: 28,
            fontFamily: 'Sedgwick Ave Display',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Color(0xFF4DB56C)),
              onPressed: () => Get.to(() => const NotificationPage()),
            ),
            const SizedBox(width: 5),
            Obx(
              () => IconButton(
                icon: Icon(
                  cameraController.isConnected
                      ? Icons.photo_camera
                      : Icons.photo_camera_outlined,
                  color: cameraController.isConnected
                      ? const Color(0xFF4DB56C)
                      : const Color(0xFF9E9E9E),
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
                      ? const Color(0xFF4DB56C)
                      : const Color(0xFF9E9E9E),
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
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
