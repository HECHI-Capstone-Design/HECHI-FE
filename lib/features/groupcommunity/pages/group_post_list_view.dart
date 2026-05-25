import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/features/groupcommunity/pages/group_post_create_view.dart';
import 'package:hechi/features/groupcommunity/widgets/group_post_card.dart';

class GroupPostListView extends GetView<GroupController> {
  final bool isMissionBoard;
  const GroupPostListView({Key? key, required this.isMissionBoard}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const unifiedGreen = Color(0xFF8DC695); 
    final posts = isMissionBoard ? controller.missionPosts : controller.freePosts;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0,
        // 🚨 [빨간 에러 원천 봉쇄]: 미션과 자유 분기를 완벽히 격리하여 자유게시판 진입 시 Obx를 타지 않고 즉시 텍스트가 꽂힙니다.
        title: isMissionBoard
            ? Obx(() {
                final String bookTitle = controller.currentMissionBookTitle.value;
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
          // 🚨 [아키텍처 레이아웃 대수리]: 구조적 스택 중첩 결함을 해결하기 위해 Column 내부 바인딩 최적화 마감
          Column(
            children: [
              // 🔔 오직 미션 게시판일 때만 140px 크기의 책 상단 헤더 카드가 생성됩니다. 
              // 자유게시판일 때는 조건문 레이어에서 아예 누락되어 빈 공간 크래시를 원천 차단합니다.
              if (isMissionBoard)
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
                          child: Obx(() => Image.network(
                                controller.currentMissionBookCover.value, 
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF3A3A3C)),
                              )),
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
                              GestureDetector(
                                onTap: () {
                                  Get.toNamed(
                                    '/book/detail', 
                                    arguments: controller.currentMissionBookId.value,
                                  );
                                },
                                child: Obx(() => Container(
                                  width: 68, 
                                  height: 98,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFEAEAEA), width: 0.5), 
                                    image: DecorationImage(
                                      image: NetworkImage(controller.currentMissionBookCover.value), 
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Obx(() => Text(
                                          controller.currentMissionBookTitle.value, 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white), 
                                          maxLines: 1, 
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                    const SizedBox(height: 6),
                                    Obx(() => Text(
                                          controller.currentMissionBookAuthor.value, 
                                          style: const TextStyle(color: Colors.white70, fontSize: 13), 
                                          maxLines: 1, 
                                          overflow: TextOverflow.ellipsis,
                                        )), 
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
              
              // 🔔 피드 게시글 리스트 스크롤 스페이스 영역
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && posts.isEmpty) {
                    return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(unifiedGreen)));
                  }
                  
                  if (posts.isEmpty) {
                    return Center(
                      child: Text(
                        isMissionBoard ? "아직 등록된 미션 인증 글이 없습니다." : "자유게시판에 첫 글을 작성해보세요!",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 90), // 버튼 패딩 확보 완비
                    itemCount: posts.length, 
                    itemBuilder: (context, index) => GroupPostCard(post: posts[index]),
                  );
                }),
              ),
            ],
          ),

          // 하단 중앙 글쓰기 커스텀 엘리베이티드 알약 캡슐 버튼
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