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
    const unifiedGreen = Color(0xFF4EB56D); 

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0,
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
          Column(
            children: [
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Obx(() {
                  final currentPosts = isMissionBoard ? controller.missionPosts : controller.freePosts;

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

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 90), 
                    itemCount: currentPosts.length, 
                    itemBuilder: (context, index) => GroupPostCard(post: currentPosts[index]),
                  );
                }),
              ),
            ],
          ),
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