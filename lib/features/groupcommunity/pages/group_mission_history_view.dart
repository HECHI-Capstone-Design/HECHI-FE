// lib/features/groupcommunity/pages/group_mission_history_view.dart 전체 교체

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/features/groupcommunity/pages/group_post_list_view.dart';
import 'package:hechi/features/groupcommunity/widgets/group_post_card.dart';

class GroupMissionHistoryView extends GetView<GroupController> {
  const GroupMissionHistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text("미션 책 보관함", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.missionHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.collections_bookmark_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text("보관된 과거 미션책 기록이 없습니다.", style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${controller.missionHistory.length} 개",
                    style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.sort, color: Colors.black54, size: 20),
                      SizedBox(width: 4),
                      Text("최신 순", style: TextStyle(color: Colors.black87, fontSize: 14)),
                    ],
                  )
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.52,
                ),
                itemCount: controller.missionHistory.length,
                itemBuilder: (context, index) {
                  final book = controller.missionHistory[index];
                  final String coverUrl = book["thumbnail"]?.toString() ?? book["cover"]?.toString() ?? "";
                  final String title = book["title"] ?? "제목 없음";

                  return InkWell(
                    onTap: () async {
                      // 🔔 1. 방금 수정한 정품 컨트롤러 조인 함수를 호출하여 완벽하게 대기(await)합니다.
                      await controller.loadHistoryBookWithDetail(book);

                      // 🔔 2. 과거방용 옵션 스위치를 켜서 대통합 뷰로 안전하게 진입시킵니다.
                      Get.to(() => const GroupPostListView(isMissionBoard: true, isHistory: true));
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 0.68,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade200, width: 0.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: coverUrl.isNotEmpty
                                  ? Image.network(coverUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey))
                                  : const Icon(Icons.menu_book, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87, height: 1.2),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "게시판",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}