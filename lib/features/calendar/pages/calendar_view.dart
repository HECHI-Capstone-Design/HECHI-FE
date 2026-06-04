import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/calendar_controller.dart';
import '../../../../core/widgets/bottom_bar.dart';
import '../widgets/common_calendar_widget.dart';
import '../widgets/calendar_app_bar.dart';
import '../widgets/monthly_summary_section.dart';

class CalendarView extends GetView<CalendarController> {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 1. 앱바
      appBar: CalendarAppBar(controller: controller),

      bottomNavigationBar: const BottomBar(),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // 2. 월간 요약 섹션
                MonthlySummarySection(controller: controller),

                const SizedBox(height: 30),

                CommonCalendarWidget(
                  currentYear: controller.currentYear.value,
                  currentMonth: controller.currentMonth.value,
                  bookCovers: controller.calendarBooks,
                  dailyBooks: controller.dailyBooks,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }
}