import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reading_detail_controller.dart';

class ReadingStatusCard extends GetView<ReadingDetailController> {
  const ReadingStatusCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('독서 상태'),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: ShapeDecoration(
              color: AppColors.primarySurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '읽고 있는 중',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontFamily: 'Roboto',
                  ),
                ),
                Container(
                  width: 24.92,
                  height: 22.02,
                  color: Colors.transparent,
                )
              ],
            ),
          ),

          const SizedBox(height: 35),

          _buildSectionHeader('독서 이력'),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: ShapeDecoration(
              color: AppColors.primarySurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRowText('완독률'),
                    const SizedBox(height: 20),
                    _buildRowText('기간'),
                    const SizedBox(height: 20),
                    _buildRowText('시간'),
                  ],
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => _buildRowText(controller.progressPercent.value)),
                      const SizedBox(height: 20),
                      Obx(() => _buildRowText(controller.readingPeriod.value)),
                      const SizedBox(height: 20),
                      Obx(() => _buildRowText(controller.timeSpent.value)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontFamily: 'Roboto',
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  Widget _buildRowText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 15,
        fontFamily: 'Roboto',
        letterSpacing: 0.25,
      ),
    );
  }
}