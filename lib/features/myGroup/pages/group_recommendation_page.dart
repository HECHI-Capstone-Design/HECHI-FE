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
      body: SafeArea(
        top: false,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Obx(() => ListView.builder(
          itemCount: controller.recommendedGroupsDetail.length,
          itemBuilder: (context, index) {
            return RecommendedGroupItemWidget(
              group: controller.recommendedGroupsDetail[index],
              showDescription: true,
            );
          },
        )),
      ),
        ),
      ),
    );
  }
}