import 'package:hechi/app/colors.dart';
//상단 프로필 정보
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/my_read_controller.dart';
import '../pages/profile_edit_view.dart';

class ProfileHeader extends StatelessWidget {
  final MyReadController controller;

  const ProfileHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.userProfile;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 프로필 이미지
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),

            // 2. 닉네임
            Text(
              profile['nickname'] ?? 'HECHI',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600, // 조금 더 강조
                  color: Colors.black
              ),
            ),
            const SizedBox(height: 4),

            // 3. 소개글
            Text(
              controller.description.value,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 4. [수정됨] 프로필 수정 버튼 (단독, 꽉 찬 너비)
            SizedBox(
              width: double.infinity, // 가로로 꽉 채우기
              height: 42, // 터치하기 좋은 적절한 높이 설정
              child: OutlinedButton(
                onPressed: () => Get.to(() => const ProfileEditView()),
                style: OutlinedButton.styleFrom(
                  // 배경색: 투명 혹은 아주 연한 회색 (인스타그램 느낌)
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87, // 글자색
                  elevation: 0,
                  // 테두리: 너무 진하지 않은 은은한 회색
                  side: const BorderSide(color: AppColors.border, width: 1),
                  // 모서리: 요즘 트렌드에 맞춰 살짝 둥글게 (8px)
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "프로필 수정",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}