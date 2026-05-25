import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/features/groupcommunity/widgets/group_post_card.dart';

// ==========================================
// 1. 미션책 보관함 리스트 뷰 (GroupMissionHistoryView) - 그리드 UI 적용 완료
// ==========================================
class GroupMissionHistoryView extends GetView<GroupController> {
  const GroupMissionHistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF8DC695);

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
        // 🔔 데이터가 없을 때 빈 화면 처리
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

        // 🔔 111번 그룹의 최신 미션책 히스토리 그리드 뷰 (요청하신 디자인 100% 매핑)
        return Column(
          children: [
            // 상단 개수 및 정렬 필터 헤더
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
            
            // 그리드 뷰 바디
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 1행에 3개 배치
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.52, // 책 커버와 텍스트의 비율 설정
                ),
                itemCount: controller.missionHistory.length,
                itemBuilder: (context, index) {
                  final book = controller.missionHistory[index];
                  final String coverUrl = book["cover"]?.toString() ?? "";
                  final String title = book["title"] ?? "제목 없음";

                  return InkWell(
                    onTap: () async {
                      // 🔔 책을 누르면 해당 미션책의 게시판으로 라우팅
                      await controller.fetchHistoryBookBoard(book);
                      Get.to(() => const GroupHistoryPostListView());
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1) 책 표지 (디자인처럼 날카로운 느낌의 라운딩 처리)
                        AspectRatio(
                          aspectRatio: 0.68, // 일반적인 책 표지 비율
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
                        
                        // 2) 책 제목
                        Text(
                          title,
                          maxLines: 2, // 제목이 길면 2줄까지 표시
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87, height: 1.2),
                        ),
                        const SizedBox(height: 4),
                        
                        // 3) 게시판 라벨
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

// ==========================================
// 2. 과거 미션책 전용 게시판 뷰 (GroupHistoryPostListView) - 이전 로직 유지
// ==========================================
class GroupHistoryPostListView extends GetView<GroupController> {
  const GroupHistoryPostListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF8DC695);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Obx(() => Text(
          "[${controller.historySelectedBookTitle.value}] 게시판",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
        )),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 140,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Obx(() => controller.historySelectedBookCover.value.isNotEmpty
                        ? Image.network(controller.historySelectedBookCover.value, fit: BoxFit.cover)
                        : Container(color: Colors.grey.shade800)),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                      child: Container(color: Colors.black.withOpacity(0.4)), 
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Row(
                      children: [
                        Obx(() => Container(
                          width: 68,
                          height: 98,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white30, width: 0.5),
                            image: controller.historySelectedBookCover.value.isNotEmpty
                                ? DecorationImage(image: NetworkImage(controller.historySelectedBookCover.value), fit: BoxFit.cover)
                                : null,
                          ),
                        )),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(() => Text(
                                controller.historySelectedBookTitle.value,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                              const SizedBox(height: 6),
                              Obx(() => Text(
                                controller.historySelectedBookAuthor.value,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: brandColor, borderRadius: BorderRadius.circular(4)),
                                child: const Text("종료된 미션", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(brandColor)));
              }
              if (controller.historyMissionPosts.isEmpty) {
                return const Center(
                  child: Text("이 미션책에 작성된 과거 게시글이 없습니다.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: controller.historyMissionPosts.length,
                itemBuilder: (context, index) => GroupPostCard(post: controller.historyMissionPosts[index]),
              );
            }),
          ),
        ],
      ),
    );
  }
}