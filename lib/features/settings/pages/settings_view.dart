import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

// 분리한 위젯들 임포트
import '../widgets/settings_section_header.dart';
import '../widgets/settings_switch_tile.dart';
import '../widgets/settings_list_tile.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '설정',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // 1. 앱 설정 섹션
          const SettingsSectionHeader(title: "앱 설정"),

          // 알림 스위치 (반응형 상태 관리를 위해 Obx 사용)
          Obx(() => SettingsSwitchTile(
            title: "알림",
            value: controller.isNotificationOn.value,
            onChanged: controller.toggleNotification,
          )),

          const Divider(thickness: 1, height: 30, color: AppColors.divider),

          // 2. 고객 지원 섹션
          const SettingsSectionHeader(title: "지원"),

          SettingsListTile(
            title: "고객 센터",
            onTap: controller.goToCustomerService,
          ),

          const Divider(thickness: 1, height: 30, color: AppColors.divider),

          // 3. 계정 섹션
          const SettingsSectionHeader(title: "계정"),

          SettingsListTile(
            title: "로그아웃",
            onTap: controller.logout,
          ),
        ],
      ),
    );
  }
}