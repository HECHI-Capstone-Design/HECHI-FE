import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/taste_analysis_controller.dart';

class PreferredTagCloud extends GetView<TasteAnalysisController> {
  const PreferredTagCloud({super.key});

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
            final tags = controller.tags;

            if (tags.isEmpty) {
              return SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    '독서 기록이 쌓이면 취향 태그가 나타나요',
                    style: TextStyle(color: AppColors.textHint, fontSize: 14),
                  ),
                ),
              );
            }

            const double stackHeight = 180;

            return SizedBox(
              height: stackHeight,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: tags.map((tag) {
                      double size = (tag['size'] as num).toDouble();
                      Color color = Color(tag['color'] as int);
                      Offset position = tag['position'] as Offset;

                      return Positioned(
                        left: position.dx * constraints.maxWidth * 0.85,
                        top: position.dy * stackHeight * 0.85,
                        child: Text(
                          tag['text'] as String,
                          style: TextStyle(
                            fontSize: size * 1.2,
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