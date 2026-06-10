import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/mainpage_controller.dart';
import '../../notification/pages/notification_page.dart';

class MainAppBar extends GetView<MainpageController> implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 20,
      title: Obx(() => Text(
        controller.headerLogo.value,
        style: const TextStyle(
          color: Color(0xFF4DB56C),
          fontSize: 28,
          fontFamily: 'Sedgwick Ave Display',
          fontWeight: FontWeight.bold,
        ),
      )),
      actions: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Color(0xFF4DB56C)),
              onPressed: () => Get.to(() => const NotificationPage()),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.bluetooth, color: Color(0xFF4DB56C)),
            const SizedBox(width: 20),
          ],
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}