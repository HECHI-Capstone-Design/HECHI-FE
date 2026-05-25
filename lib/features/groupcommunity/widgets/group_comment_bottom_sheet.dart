import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';

class GroupCommentBottomSheet extends StatelessWidget {
  final Map<String, dynamic> post;
  const GroupCommentBottomSheet({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GroupController controller = Get.find<GroupController>();
    final TextEditingController textController = TextEditingController();
    const brandColor = Color(0xFF8DC695);
    
    final String postId = post["id"] ?? "0";
    final List<dynamic> commentsList = post["comments"] ?? [];

    return AnimatedPadding(
      // 🔔 [키보드 밀어올림 완치]: 가상 키보드 감지 시 해당 공간만큼 바텀 뷰 레이아웃 점프 업
      padding: MediaQuery.of(context).viewInsets,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        width: double.infinity,
        // 🔔 [높이 고정 해제]: 디바이스 세로 총 길이의 65% 비율 스케일로 유연성 전면 고정
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            const Text("댓글", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            const Divider(height: 20),
            
            // 1. 댓글 스크롤 리스트뷰 스코프
            Expanded(
              child: commentsList.isEmpty
                  ? const Center(child: Text("첫 댓글을 남겨보세요!", style: TextStyle(color: Colors.grey, fontSize: 13)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: commentsList.length,
                      itemBuilder: (context, idx) {
                        final comment = commentsList[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(radius: 18, backgroundColor: brandColor, child: Icon(Icons.person, color: Colors.white, size: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(comment["author"] ?? "익명", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                    const SizedBox(height: 4),
                                    Text(comment["content"] ?? "", style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                    const SizedBox(height: 4),
                                    const Text("답글 달기", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Icon(Icons.favorite_border_rounded, size: 18, color: Colors.grey.shade400),
                                  const SizedBox(height: 2),
                                  Text("${comment["likes"] ?? 0}", style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
            
            // 2. 하단 고정 텍스트 필드 폼 (키보드 밀착 바인딩 레이어)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    const CircleAvatar(radius: 18, backgroundColor: brandColor, child: Icon(Icons.person, color: Colors.white, size: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: textController,
                                cursorColor: brandColor,
                                decoration: const InputDecoration(
                                  hintText: "회원님의 생각을 남겨보세요.",
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send_rounded, color: brandColor, size: 20),
                              onPressed: () async {
                                if (textController.text.trim().isNotEmpty) {
                                  final success = await controller.addCommentToPost(postId, textController.text.trim());
                                  if (success) {
                                    textController.clear();
                                    Get.back(); // 작성 성공 즉시 시트 닫기 후 자동 화면 갱신 유도
                                    Get.snackbar("성공", "댓글이 성공적으로 등록되었습니다.");
                                  }
                                }
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}