import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_settings_controller.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationSettingsController());
    const brandColor = AppColors.primary; // 앱 메인 색상

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          '알림 설정',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: brandColor));
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            _buildSectionTitle('앱 알림'),
            SwitchListTile(
              activeColor: brandColor,
              title: const Text('푸시 알림 켜기', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('기기로 오는 모든 푸시 알림을 켭니다.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: controller.pushEnabled.value,
              onChanged: (val) => controller.updateSettings(push: val),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.backgroundGrey),

            _buildSectionTitle('세부 알림 설정'),
            SwitchListTile(
              activeColor: brandColor,
              title: const Text('일반 알림', style: TextStyle(fontSize: 15)),
              value: controller.generalEnabled.value,
              // 전체 푸시가 꺼져있으면 개별 설정도 못 건드리게 비활성화 처리
              onChanged: controller.pushEnabled.value
                  ? (val) => controller.updateSettings(general: val)
                  : null,
            ),
            SwitchListTile(
              activeColor: brandColor,
              title: const Text('그룹 알림', style: TextStyle(fontSize: 15)),
              value: controller.groupEnabled.value,
              onChanged: controller.pushEnabled.value
                  ? (val) => controller.updateSettings(group: val)
                  : null,
            ),
            SwitchListTile(
              activeColor: brandColor,
              title: const Text('마케팅 및 혜택 알림', style: TextStyle(fontSize: 15)),
              value: controller.marketingEnabled.value,
              onChanged: controller.pushEnabled.value
                  ? (val) => controller.updateSettings(marketing: val)
                  : null,
            ),
          ],
        );
      }),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}