import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/controllers/app_controller.dart';
import '../../app/routes.dart';

class BottomBar extends GetView<AppController> {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, '홈', 'assets/icons/icon_home.png', 60.0),
            _buildNavItem(1, '검색', 'assets/icons/icon_search.png', 60.0),
            _buildNavItem(2, '독서 등록', 'assets/icons/icon_register.png', 82.0),
            _buildNavItem(3, '그룹', 'assets/icons/icon_group.png', 56.0),
            _buildNavItem(4, '나의 독서', 'assets/icons/icon_user.png', 62.0),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String iconPath, double textWidth) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.changeIndex(index);
          if (Get.currentRoute != Routes.initial) {
            Get.offAllNamed(Routes.initial);
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 4),
            Obx(() {
              final bool isSelected = controller.currentIndex.value == index;
              final Color color = isSelected ? const Color(0xFF3F3F3F) : const Color(0xFFABABAB);

              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(iconPath),
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Obx(() {
              final bool isSelected = controller.currentIndex.value == index;
              return Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Inter',
                  color: isSelected ? const Color(0xFF3F3F3F) : const Color(0xFFABABAB),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}