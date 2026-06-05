import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/preference_controller.dart';
import 'preference_title.dart';
import 'preference_top_bar.dart';

class PreferenceUnifiedStep extends StatelessWidget {
  final PreferenceController controller;

  const PreferenceUnifiedStep({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // ✅ 완료 버튼 누를 때 검증 (선택 안 하면 경고창 띄움)
            PreferenceTopBar(
                text: '완료',
                onTap: () {
                  if (controller.selectedOptions.isEmpty) {
                    Get.snackbar(
                      "알림",
                      "장르를 최소 1개 이상 선택해주세요.",
                      backgroundColor: AppColors.primary, // ✅ 까만색에서 앱 메인 컬러(초록색)로 변경!
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  } else {
                    controller.nextStep();
                  }
                }
            ),
            const SizedBox(height: 40),

            const PreferenceTitle(
                highlight: '장르',
                subText: '선호하는 세부 장르를 골라주세요.'
            ),
            const SizedBox(height: 40),

            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: controller.allOptions.length,
                itemBuilder: (context, index) {
                  final item = controller.allOptions[index];
                  return _buildItem(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 3번째 사진처럼 가운데 정렬된 귀여운 캡슐 모양 위젯
  Widget _buildItem(String item) {
    // 🔥 해결 포인트: ListView 전체가 아니라 각 아이템마다 Obx를 감싸줍니다.
    return Obx(() {
      // GetX의 RxList는 단순 .contains()만 쓰면 변경을 감지하지 못하는 경우가 있어서
      // .toList()를 붙여 데이터를 확실히 감지하게 만들어 줍니다! (클릭 안 되던 버그 해결)
      final isSelected = controller.selectedOptions.toList().contains(item);

      return Center( // 👈 사진처럼 항목들을 중앙 정렬
        child: GestureDetector(
          onTap: () {
            // 터치 시 즉각적으로 선택/해제 토글 반영
            if (isSelected) {
              controller.selectedOptions.remove(item);
            } else {
              controller.selectedOptions.add(item);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), // 알약 모양 패딩
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.divider,
              borderRadius: BorderRadius.circular(30), // 둥근 모양
            ),
            child: Text(
                item,
                style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500
                )
            ),
          ),
        ),
      );
    });
  }
}