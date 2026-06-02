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

      // 생성 요청 후 폴링 중
      if (controller.isGenerating.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF4DB56C)),
              SizedBox(height: 16),
              Text(
                'AI가 요약을 생성 중입니다...',
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
      child: Obx(() {
        final content = controller.summaryText.value;
        final keyPoints = controller.keyPoints;
        final notesDigest = controller.notesDigest;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E5E5), width: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 요약
                  Padding(
                    padding: const EdgeInsets.all(20),
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
                        const SizedBox(height: 10),
                        Text(
                          content,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3F3F3F),
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            height: 1.75,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 주요 내용
                  if (keyPoints.isNotEmpty) ...[
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5E5)),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 3,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Color(0xFF4DB56C),
                                  borderRadius: BorderRadius.all(Radius.circular(2)),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '주요 내용',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3F3F3F),
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...keyPoints.map((point) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(top: 8, right: 8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFBDBDBD),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF3F3F3F),
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w400,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],

                  // ── 내가 남긴 메모
                  if (notesDigest.isNotEmpty) ...[
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5E5)),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 3,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Color(0xFF4DB56C),
                                  borderRadius: BorderRadius.all(Radius.circular(2)),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '내가 남긴 메모',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3F3F3F),
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...notesDigest.map((note) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Color(0xFFBDBDBD), width: 2),
                                ),
                              ),
                              child: Text(
                                note,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF3F3F3F),
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  height: 1.65,
                                ),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],

                  // ── 다시 생성
                  const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5E5)),
                  GestureDetector(
                    onTap: () => controller.fetchSummary(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, size: 14, color: Color(0xFFBDBDBD)),
                          SizedBox(width: 6),
                          Text(
                            '다시 생성',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFBDBDBD),
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
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