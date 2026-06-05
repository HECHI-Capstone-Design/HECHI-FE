import 'package:hechi/app/colors.dart';
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
    const unifiedGreen = AppColors.primary;

    // ✅ 네비게이션바 높이를 build()에서 한 번만 가져옴
    final double safeBottom = MediaQuery.of(context).padding.bottom;

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
          final bool isSet =
              bookTitle.isNotEmpty && bookTitle != "미설정";
          return Text(
            isSet ? "[$bookTitle] 게시판" : "[미션책 제목] 게시판",
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          );
        })
            : const Text(
          "자유 게시판",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16),
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
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final int targetId = isHistory
                        ? historyBookId
                        : controller.currentMissionBookId.value;

                    int finalId = targetId;
                    if (isHistory && finalId == 0) {
                      finalId = controller.currentMissionBookId.value;
                    }

                    if (finalId != 0) {
                      Get.toNamed('/book_detail_page', arguments: finalId);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Obx(() {
                              final cover = isHistory
                                  ? controller.historySelectedBookCover.value
                                  : controller.currentMissionBookCover.value;
                              return cover.isNotEmpty
                                  ? Image.network(cover,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.textDark))
                                  : Container(color: AppColors.textDark);
                            }),
                          ),
                          Positioned.fill(
                            child: BackdropFilter(
                              filter:
                              ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                              child: Container(
                                  color: Colors.black.withOpacity(0.18)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 16.0),
                            child: Row(
                              children: [
                                Obx(() {
                                  final cover = isHistory
                                      ? controller
                                      .historySelectedBookCover.value
                                      : controller
                                      .currentMissionBookCover.value;
                                  return Container(
                                    width: 68,
                                    height: 98,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppColors.border,
                                          width: 0.5),
                                      image: cover.isNotEmpty
                                          ? DecorationImage(
                                          image: NetworkImage(cover),
                                          fit: BoxFit.cover)
                                          : null,
                                    ),
                                  );
                                }),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Obx(() {
                                    final title = isHistory
                                        ? controller
                                        .historySelectedBookTitle.value
                                        : controller
                                        .currentMissionBookTitle.value;
                                    final author = isHistory
                                        ? controller
                                        .historySelectedBookAuthor.value
                                        : controller
                                        .currentMissionBookAuthor.value;
                                    return Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.white),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          author.isNotEmpty ? author : "저자 미상",
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13),
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
                      : (isHistory
                      ? controller.historyMissionPosts
                      : controller.missionPosts);

                  if (controller.isLoading.value && currentPosts.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                unifiedGreen)));
                  }

                  if (currentPosts.isEmpty) {
                    return Center(
                      child: Text(
                        isMissionBoard
                            ? "아직 등록된 미션 인증 글이 없습니다."
                            : "자유게시판에 첫 글을 작성해보세요!",
                        style:
                        const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: unifiedGreen,
                    onRefresh: () => isHistory
                        ? Future.value()
                        : controller.refreshPostsOnly(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      // ✅ bottom padding도 safeBottom 반영 (리스트 마지막 항목이 버튼에 가리지 않게)
                      padding: EdgeInsets.only(
                          top: 8, bottom: safeBottom + 80),
                      itemCount: currentPosts.length,
                      itemBuilder: (context, index) =>
                          GroupPostCard(post: currentPosts[index]),
                    ),
                  );
                }),
              ),
            ],
          ),

          // ✅ 핵심 수정: bottom: 25 → bottom: safeBottom + 16
          // 네비게이션바 높이만큼 버튼을 위로 올려서 잘림 해결
          if (!isHistory &&
              (controller.currentMissionBookId.value != 0 ||
                  !isMissionBoard))
            Positioned(
              bottom: safeBottom + 16, // ← 이 한 줄이 핵심
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      Get.to(() => GroupPostCreateView(isMission: isMissionBoard)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundGrey,
                    foregroundColor: Colors.black87,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                      side: BorderSide(
                          color: Colors.grey.shade300, width: 1.2),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, color: unifiedGreen, size: 18),
                      SizedBox(width: 8),
                      Text("글쓰기",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}