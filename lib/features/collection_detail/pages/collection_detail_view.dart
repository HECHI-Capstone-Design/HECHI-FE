import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/collection_detail_controller.dart';
import '../widgets/collection_top_images.dart';
import '../widgets/collection_info_section.dart';
import '../widgets/collection_action_buttons.dart';
import '../widgets/collection_book_grid.dart';

// ✅ 올려주신 사진의 경로(lib/core/widgets)에 맞춰 정확한 상대 경로로 수정했습니다!
import '../../../core/widgets/bottom_bar.dart';

// [3] View: 피그마 디자인을 4개의 부품(Widget)으로 쪼개서 차곡차곡 쌓아올린 뼈대입니다.
class CollectionDetailView extends GetView<CollectionDetailController> {
  const CollectionDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚨 임시: 앱 라우팅(Get.toNamed)으로 정상 연결되기 전까지 화면을 보기 위한 강제 주입
    if (!Get.isRegistered<CollectionDetailController>()) {
      Get.put(CollectionDetailController());
    }

    return Scaffold(
      backgroundColor: Colors.white,

      // =======================================================
      // 🛠️ [여기 주목!] 하단 바가 생기는 마법의 한 줄입니다!
      bottomNavigationBar: const BottomBar(),
      // =======================================================

      appBar: AppBar(
        backgroundColor: Colors.transparent, // 앱바 투명하게
        elevation: 0,
        // 뒤로가기 화살표
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      extendBodyBehindAppBar: true, // 앱바 뒤로 배경 이미지가 깔리게 설정
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 맨 위 책 표지 3개 배경 구역 (위로 바짝 붙임)
            CollectionTopImages(controller: controller),

            // 2. 프로필, 컬렉션 제목, 설명, 태그 구역
            CollectionInfoSection(controller: controller),

            // 구분선 (얇은 회색 선)
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // 3. 좋아요 수, 좋아요 버튼, 공유 버튼 구역
            CollectionActionButtons(controller: controller),

            // 구분선 (두꺼운 회색 여백)
            Container(height: 8, color: const Color(0xFFF5F5F5)),

            // 4. 작품들(책 리스트) 격자 구역
            CollectionBookGrid(controller: controller),

            const SizedBox(height: 40), // 바닥 여백
          ],
        ),
      ),
    );
  }
}