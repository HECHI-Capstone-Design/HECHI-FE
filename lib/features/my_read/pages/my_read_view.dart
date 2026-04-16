import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/app/routes.dart';

import '../controllers/my_read_controller.dart';
import '../widgets/mini_calendar_section.dart';
import '../widgets/profile_header.dart';
import '../widgets/activity_stats.dart';
import '../widgets/section_title.dart';
import '../widgets/taste_analysis_preview.dart';
import '../widgets/see_all_taste_button.dart';
import '../widgets/book_storage_link.dart';

// ✅ 회원님이 만드신 collection_detail 의 pages 폴더 위치를 정확히 가리키는 import 입니다!
import '../../collection_detail/pages/collection_detail_view.dart';

class MyReadView extends GetView<MyReadController> {
  const MyReadView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            onPressed: () => Get.toNamed(Routes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF4DB56C),
        onRefresh: () async => await controller.fetchMyReadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 프로필
              ProfileHeader(controller: controller),
              const SizedBox(height: 20),

              // 2. 활동 통계
              ActivityStats(controller: controller),
              const SizedBox(height: 20),

              // 얇은 구분선
              const Divider(color: Color(0xFFF5F5F5), thickness: 1, height: 1),

              // 3. 보관함 링크 섹션 (내부 패딩 있음)
              const BookStorageLink(),

              // 두꺼운 구분선 (섹션 분리)
              Container(height: 8, color: const Color(0xFFF5F5F5)),

              // 4. 캘린더 섹션
              MiniCalendarSection(controller: controller),

              // 두꺼운 구분선
              Container(height: 8, color: const Color(0xFFF5F5F5)),

              // 5. 취향 분석
              const SizedBox(height: 20),
              const SectionTitle(title: "취향 분석"),
              TasteAnalysisPreview(controller: controller),

              const SizedBox(height: 10),
              // 6. 취향 분석 전체 보기 버튼
              const SeeAllTasteButton(),

              // =======================================================
              // 🛠️ 컬렉션 상세페이지 테스트용 임시 버튼 (여기에 딱 추가했습니다!)
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const CollectionDetailView()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // 눈에 띄는 까만색 버튼
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text(
                    "🛠️ 컬렉션 상세페이지 테스트",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // =======================================================

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}