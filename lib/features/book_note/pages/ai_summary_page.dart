import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ai_summary_controller.dart';
import '../widgets/dialogs/ai_summary_option_bottom_sheet.dart';

class AiSummaryPage extends GetView<AiSummaryController> {
  const AiSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3F3F3F)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'AI 메모 요약',
          style: TextStyle(
            color: Color(0xFF3F3F3F),
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            height: 1.75,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 17),
            child: IconButton(
              icon: const Icon(Icons.more_horiz, color: Color(0xFF3F3F3F)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Get.bottomSheet(
                  AiSummaryOptionBottomSheet(
                    onDelete: () => controller.deleteSummary(),
                  ),
                  backgroundColor: Colors.transparent,
                );
              },
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4DB56C)),
        );
      }

      if (controller.summaryText.value.isEmpty) {
        return _buildEmptyState();
      }

      return _buildSummaryContent();
    });
  }

  // ── 요약 내용 ─────────────────────────────────────────────────────────────
  Widget _buildSummaryContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, size: 16, color: Color(0xFF4DB56C)),
                    SizedBox(width: 6),
                    Text(
                      'AI 요약',
                      style: TextStyle(
                        color: Color(0xFF4DB56C),
                        fontSize: 13,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() => Text(
                  controller.summaryText.value,
                  style: const TextStyle(
                    color: Color(0xFF3F3F3F),
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 1.75,
                  ),
                )),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
                const SizedBox(height: 12),

                // ── 재생성 버튼
                GestureDetector(
                  onTap: () => controller.fetchSummary(),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: 14, color: Color(0xFFABABAB)),
                      SizedBox(width: 4),
                      Text(
                        '다시 생성',
                        style: TextStyle(
                          color: Color(0xFFABABAB),
                          fontSize: 13,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 빈 상태 ───────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_outlined,
              size: 60, color: Color(0xFFDADADA)),
          const SizedBox(height: 16),
          const Text(
            '요약할 메모가 없습니다.',
            style: TextStyle(
              color: Color(0xFF717171),
              fontSize: 15,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}