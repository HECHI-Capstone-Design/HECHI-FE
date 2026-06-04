import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/group_join_controller.dart';

// 전반적인 팝업의 둥근 모서리 및 초록색 텍스트 테마 반영 (사진 3 구조)
void showPublicJoinDialog(BuildContext context, GroupJoinController controller) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.only(top: 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            controller.groupName.value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '그룹에 가입하시겠습니까?',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => controller.joinGroup(),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('예', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              Container(width: 1, height: 48, color: AppColors.border),
              Expanded(
                child: TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('아니오', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}

void showPrivateJoinDialog(BuildContext context, GroupJoinController controller) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.only(top: 24, left: 20, right: 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '비밀번호를 입력하세요.',
            style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: controller.passwordController,
              obscureText: true,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => controller.joinGroup(),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('예', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              Container(width: 1, height: 48, color: AppColors.border),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    controller.passwordController.clear();
                    Get.back();
                  },
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('아니오', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    ),
  );
}