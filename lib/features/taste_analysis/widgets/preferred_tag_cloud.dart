import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/taste_analysis_controller.dart';

class PreferredTagCloud extends GetView<TasteAnalysisController> {
  const PreferredTagCloud({super.key});

  // ✅ [수정됨] 개수를 10개 -> 6개로 줄여서 더 깔끔하게 배치
  final List<Map<String, dynamic>> _dummyTags = const [
    // 1. 메인 키워드 (중앙 배치, 크고 진함)
    {'text': '로맨틱한', 'size': 19.0, 'color': 0xFF4DB56C, 'position': Offset(0.32, 0.40)},
    {'text': '인상 깊은', 'size': 18.0, 'color': 0xFF4DB56C, 'position': Offset(0.60, 0.45)},

    // 2. 서브 키워드 (주변 배치, 작고 연함)
    {'text': '따뜻한', 'size': 14.0, 'color': 0xFF8FBC8F, 'position': Offset(0.15, 0.25)},
    {'text': '몰입감 있는', 'size': 13.0, 'color': 0xFF8FBC8F, 'position': Offset(0.55, 0.20)},
    {'text': '여운이 남는', 'size': 13.0, 'color': 0xFF8FBC8F, 'position': Offset(0.20, 0.65)},
    {'text': '유쾌한', 'size': 12.0, 'color': 0xFF8FBC8F, 'position': Offset(0.75, 0.70)},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "독서 선호 태그",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark
            ),
          ),
          const SizedBox(height: 20),
          Obx(() {
            // 실제 데이터가 없으면 위의 '깔끔한 6개 더미' 사용
            final displayTags = controller.tags.isNotEmpty
                ? controller.tags
                : _dummyTags;

            const double stackHeight = 180;

            return SizedBox(
              height: stackHeight,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: displayTags.map((tag) {
                      double size = (tag['size'] as num).toDouble();
                      Color color = Color(tag['color'] as int);
                      Offset position = tag['position'] as Offset;

                      final fontSize = size * 1.2;

                      return Positioned(
                        // 화면 중앙으로 살짝 모아주는 배치 (* 0.85)
                        left: position.dx * constraints.maxWidth * 0.85,
                        top: position.dy * stackHeight * 0.85,
                        child: Text(
                          tag['text'] as String,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: color,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.white.withOpacity(0.8),
                              )
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}