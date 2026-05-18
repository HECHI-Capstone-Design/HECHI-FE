import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/my_group_controller.dart';
import '../widgets/recommended_group_item_widget.dart';

class GroupRecommendationPage extends GetView<MyGroupController> {
  const GroupRecommendationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          '그룹 추천',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        // 그룹 추천 리스트 (20개 제한, 이미지 2처럼 설명이 없는 형태로 재사용 가능하도록 설정)
        child: Obx(() => ListView.builder(
          itemCount: controller.recommendedGroupsDetail.length,
          itemBuilder: (context, index) {
            return RecommendedGroupItemWidget(
              group: controller.recommendedGroupsDetail[index],
              showDescription: false, // 두 번째 이미지에서는 설명이 안 보이므로 false 처리
            );
          },
        )),
      ),
    );
  }
}