import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/controllers/app_controller.dart';
import '../controllers/my_read_controller.dart';
import '../pages/profile_edit_view.dart';

class ProfileHeader extends StatelessWidget {
  final MyReadController controller;

  const ProfileHeader({super.key, required this.controller});

  void _showFullImage(BuildContext context, String imageUrl) {
    final transformController = TransformationController();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 핀치줌 가능한 이미지 (ClipOval 바깥 → 줌해도 원 유지)
            Center(
              child: Hero(
                tag: 'profile_image',
                child: ClipOval(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: InteractiveViewer(
                      transformationController: transformController,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Image.network(
                        imageUrl,
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 닫기 버튼
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => transformController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final appController = Get.find<AppController>();

    return Obx(() {
      final profile = controller.userProfile;
      final profileImageUrl = appController.userProfile['profileImageUrl'] as String?;
      final hasImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 프로필 이미지 (이미지 있으면 탭으로 크게 보기)
            GestureDetector(
              onTap: hasImage ? () => _showFullImage(context, profileImageUrl!) : null,
              child: Hero(
                tag: 'profile_image',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: hasImage ? NetworkImage(profileImageUrl!) : null,
                    child: !hasImage
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. 닉네임
            Text(
              profile['nickname'] ?? 'HECHI',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),

            // 3. 소개글
            Text(
              controller.description.value,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 4. 프로필 수정 버튼
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: () => Get.to(() => const ProfileEditView()),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.border, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "프로필 수정",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
