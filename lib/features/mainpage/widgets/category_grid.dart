import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../taste_analysis/pages/taste_analysis_view.dart';
import '../../taste_analysis/bindings/taste_analysis_binding.dart';
import '../../book_storage/pages/book_storage_view.dart';
import '../../book_storage/bindings/book_storage_binding.dart';
import '../../calendar/pages/calendar_view.dart';
import '../../calendar/bindings/calendar_binding.dart';
import '../../recommendation/pages/recommendation_view.dart';
import '../../recommendation/bindings/recommendation_binding.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
      return Row(
        children: [
          Expanded(child: _buildCategoryItem('캘린더', Icons.calendar_today, const Color(0xFF4DB56C), onTap: () => Get.to(() => const CalendarView(), binding: CalendarBinding()))),
          Expanded(child: _buildCategoryItem('취향분석', Icons.bar_chart, const Color(0xFF4DB56C), onTap: () => Get.to(() => const TasteAnalysisView(), binding: TasteAnalysisBinding()),)),
          Expanded(child: _buildCategoryItem('보관함', Icons.inventory_2_outlined, const Color(0xFF4DB56C), onTap: () => Get.to(() => const BookStorageView(), binding: BookStorageBinding()),)),
          Expanded(child: _buildCategoryItem('추천', Icons.auto_awesome, const Color(0xFF4DB56C), onTap: () => Get.to(() => const RecommendationView(), binding: RecommendationBinding()),)),
          
          // 🔔 [NEW] 그룹 버튼을 클릭하면 routes.dart에 연결된 대규모 커뮤니티 첫 화면(GroupMainView)으로 즉시 라우팅됩니다.
          Expanded(child: _buildCategoryItem('그룹', Icons.people_outline, const Color(0xFF4DB56C), onTap: () => Get.toNamed('/group/main'))),
        ],
      );
  }

  Widget _buildCategoryItem(String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => Get.to(() => TempCategoryPage(title: label)),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class TempCategoryPage extends StatelessWidget {
  final String title;
  const TempCategoryPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              '$title 페이지 준비중입니다.',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}