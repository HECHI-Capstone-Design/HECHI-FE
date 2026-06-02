// lib/features/groupcommunity/pages/group_post_list_view.dart 전체 교체

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/features/groupcommunity/pages/group_post_create_view.dart';
import 'package:hechi/features/groupcommunity/widgets/group_post_card.dart';

class GroupPostListView extends GetView<GroupController> {
  final bool isMissionBoard;
  final bool isHistory;

  const GroupPostListView({
    Key? key,
    required this.isMissionBoard,
    this.isHistory = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const unifiedGreen = Color(0xFF4EB56D);

    // 스웨거 명세서의 bookId와 boardBookId를 모두 추적하여 유실 없이 인양합니다.
    final dynamic args = Get.arguments;
    int historyBookId = 0;

    if (isHistory && args != null && args is Map) {
      final rawId = args["boardBookId"] ?? args["bookId"];
      historyBookId = int.tryParse(rawId?.toString() ?? "") ?? 0;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: isMissionBoard
            ? Obx(() {
          final String bookTitle = isHistory
              ? controller.historySelectedBookTitle.value
              : controller.currentMissionBookTitle.value;
          final bool isSet = bookTitle.isNotEmpty && bookTitle != "미설정";
          return Text(
            isSet ? "[$bookTitle] 게시판" : "[미션책 제목] 게시판",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
          );
        })
            : const Text(
          "자유 게시판",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (isMissionBoard)
                GestureDetector(
                  // 🎯 [완치 포인트 1]: behavior 속성은 GestureDetector 바로 아래에 위치해야 정상 작동합니다!
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final int targetId = isHistory ? historyBookId : controller.currentMissionBookId.value;

                    int finalId = targetId;
                    if (isHistory && finalId == 0) {
                      finalId = controller.currentMissionBookId.value;
                    }

                    if (finalId != 0) {
                      print("🚀 책 상세 페이지 이동 트리거! Book ID: $finalId");
                      Get.toNamed('/book_detail_page', arguments: finalId);
                    } else {
                      print("⚠️ 이동 실패: 책 ID를 가져오지 못했습니다.");
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    // 🎯 [완치 포인트 2]: Container 내부의 잘못 들어갔던 behavior 구문은 깔끔하게 삭제했습니다.
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Obx(() {
                              final cover = isHistory ? controller.historySelectedBookCover.value : controller.currentMissionBookCover.value;
                              return cover.isNotEmpty
                                  ? Image.network(cover, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: const Color(0xFF3A3A3C)))
                                  : Container(color: const Color(0xFF3A3A3C));
                            }),
                          ),
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                              child: Container(color: Colors.black.withOpacity(0.18)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                            child: Row(
                              children: [
                                Obx(() {
                                  final cover = isHistory ? controller.historySelectedBookCover.value : controller.currentMissionBookCover.value;
                                  return Container(
                                    width: 68,
                                    height: 98,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFEAEAEA), width: 0.5),
                                      image: cover.isNotEmpty
                                          ? DecorationImage(image: NetworkImage(cover), fit: BoxFit.cover)
                                          : null,
                                    ),
                                  );
                                }),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Obx(() {
                                    final title = isHistory ? controller.historySelectedBookTitle.value : controller.currentMissionBookTitle.value;
                                    final author = isHistory ? controller.historySelectedBookAuthor.value : controller.currentMissionBookAuthor.value;
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          author.isNotEmpty ? author : "저자 미상",
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Obx(() {
                  final currentPosts = !isMissionBoard
                      ? controller.freePosts
                      : (isHistory ? controller.historyMissionPosts : controller.missionPosts);

                  if (controller.isLoading.value && currentPosts.isEmpty) {
                    return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(unifiedGreen)));
                  }

                  if (currentPosts.isEmpty) {
                    return Center(
                      child: Text(
                        isMissionBoard ? "아직 등록된 미션 인증 글이 없습니다." : "자유게시판에 첫 글을 작성해보세요!",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: unifiedGreen,
                    onRefresh: () => isHistory ? Future.value() : controller.refreshPostsOnly(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 90),
                      itemCount: currentPosts.length,
                      itemBuilder: (context, index) => GroupPostCard(post: currentPosts[index]),
                    ),
                  );
                }),
              ),
            ],
          ),
          if (!isHistory && (controller.currentMissionBookId.value != 0 || !isMissionBoard))
            Positioned(
              bottom: 25, left: 0, right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () => Get.to(() => GroupPostCreateView(isMission: isMissionBoard)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                    foregroundColor: Colors.black87,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                      side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit, color: unifiedGreen, size: 18),
                      const SizedBox(width: 8),
                      const Text("글쓰기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}