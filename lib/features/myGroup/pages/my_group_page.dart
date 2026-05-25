// lib/features/myGroup/pages/my_group_page.dart

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
        centerTitle: false, // 왼쪽 정렬
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black26,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black, size: 28),
            onPressed: () {
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
              
              // 1. 내 그룹 리스트 영역
              SizedBox(
                height: 140,
                child: Obx(() {
                  if (controller.myGroups.isEmpty) {
                    return const Center(
                      child: Text('가입된 그룹이 없습니다.', style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    // 💡 [추가] 터치 제스처 씹힘 방지를 위한 핵심 가드 스펙 2가지!
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(), 
                    
                    itemCount: controller.myGroups.length,
                    itemBuilder: (context, index) {
                      return MyGroupItemWidget(
                        group: controller.myGroups[index],
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 32),
              
              // 2. 그룹 추천 타이틀 헤더
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
              
              // 3. 💡 고도화된 그룹 추천 리스트 영역 (로딩/예외처리 추가)
              Obx(() {
                // 가) 서버와 통신하며 데이터를 받아오는 로딩 상태일 때
                if (controller.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff4DB56C), // 메인테마 초록색 적용
                      ),
                    ),
                  );
                }

                // 나) 로딩은 끝났는데 서버에서 내려온 추천 데이터가 실제로 하나도 없을 때
                if (controller.recommendedGroupsMain.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text(
                        '추천할 그룹이 없습니다.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  );
                }

                // 다) 정상적으로 데이터가 존재할 때 카드 리스트 렌더링
                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: controller.recommendedGroupsMain.length,
                  itemBuilder: (context, index) {
                    return RecommendedGroupItemWidget(
                      group: controller.recommendedGroupsMain[index],
                      showDescription: true,
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}