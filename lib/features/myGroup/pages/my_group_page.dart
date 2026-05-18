import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/my_group_controller.dart';
import '../widgets/my_group_item_widget.dart';
import '../widgets/recommended_group_item_widget.dart';
import '../../../app/routes.dart';

class MyGroupPage extends GetView<MyGroupController> {
  const MyGroupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '그룹',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false, // 왼쪽 정렬로 변경
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black26,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black, size: 28),
            onPressed: () {
              // TODO: Routes.groupCreate 경로로 이동하도록 연결
              Get.toNamed(Routes.groupCreate);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '내 그룹',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: Obx(() => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.myGroups.length,
                  itemBuilder: (context, index) {
                    return MyGroupItemWidget(
                      group: controller.myGroups[index],
                    );
                  },
                )),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '그룹 추천',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed('/groupRecommendation');
                    },
                    child: const Icon(Icons.arrow_forward_ios, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() => ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: controller.recommendedGroupsMain.length,
                itemBuilder: (context, index) {
                  return RecommendedGroupItemWidget(
                    group: controller.recommendedGroupsMain[index],
                    showDescription: true,
                  );
                },
              )),
            ],
          ),
        ),
      ),
    );
  }
}