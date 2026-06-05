import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';

class StarRatingChart extends StatelessWidget {
  final List<Map<String, dynamic>> ratingData;
  final String mostGivenRating; // Section에서 넘겨주는 값을 받기는 함 (에러 방지)

  const StarRatingChart({
    super.key,
    required this.ratingData,
    required this.mostGivenRating,
  });

  @override
  Widget build(BuildContext context) {
    if (ratingData.isEmpty) {
      return const SizedBox(
        height: 105,
        child: Center(child: Text("데이터가 부족합니다.", style: TextStyle(color: Colors.grey))),
      );
    }

    // 1. 점수 순으로 정렬 (0.5 -> 5.0)
    var sortedData = List<Map<String, dynamic>>.from(ratingData);
    sortedData.sort((a, b) => (a['score'] as num).compareTo(b['score'] as num));

    // 2. 가장 높은 비율(Max Ratio) 찾기 (이게 핵심!)
    double maxRatio = 0.0;
    for (var d in sortedData) {
      double r = (d['ratio'] as num).toDouble();
      if (r > maxRatio) maxRatio = r;
    }

    // ✅ 색상 정의
    final Color activeColor = AppColors.primary; // 가장 높은 바 (진한 초록)
    final Color inactiveColor = AppColors.primaryLight; // 나머지 바 (연한 초록)
    final Color emptyColor = AppColors.backgroundGrey;    // 데이터 0

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        SizedBox(
          height: 105,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sortedData.asMap().entries.map((entry) {
                int idx = entry.key;
                Map<String, dynamic> d = entry.value;

                double ratio = (d['ratio'] as num).toDouble();
                double score = (d['score'] as num).toDouble();

                // ✅ [수정완료] 외부 값(mostGivenRating) 무시하고, 실제 데이터에서 1등을 찾아 칠함
                bool isMax = (ratio == maxRatio && ratio > 0);

                Color barColor = isMax ? activeColor : inactiveColor;
                if (ratio == 0) barColor = emptyColor;

                const double maxHeight = 60.0;
                double barHeight = 2.0;

                if (maxRatio > 0 && ratio > 0) {
                  barHeight = (ratio / maxRatio) * maxHeight;
                }

                // 라벨 표시 조건: 1등이거나, 맨 처음(0.5)이거나, 맨 끝(5.0)일 때
                bool showLabel = isMax || idx == 0 || idx == sortedData.length - 1;

                String scoreText = score % 1 == 0 ? score.toInt().toString() : score.toStringAsFixed(1);

                return Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (showLabel) ...[
                          Text(
                            scoreText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMedium,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ] else
                          const SizedBox(height: 20), // 텍스트 공간 확보

                        SizedBox(
                          width: 24,
                          height: barHeight,
                          child: Container(
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}