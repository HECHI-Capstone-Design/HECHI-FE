import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';

class GroupCommentBottomSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  const GroupCommentBottomSheet({Key? key, required this.post}) : super(key: key);

  @override
  State<GroupCommentBottomSheet> createState() => _GroupCommentBottomSheetState();
}

class _GroupCommentBottomSheetState extends State<GroupCommentBottomSheet> {
  final GroupController controller = Get.find<GroupController>();
  final TextEditingController textController = TextEditingController();
  
  Map<String, dynamic>? replyingTargetComment; 
  bool _isInitLoading = true; // 👈 최초 진입 시 로딩 상태 제어 플래그

  @override
  void initState() {
    super.initState();
    _loadCurrentComments();
  }

  // 🚀 [핵심 추가]: 바텀시트가 열리자마자 백엔드에서 원본 댓글을 강제로 갱신해오는 흐름 설계
  Future<void> _loadCurrentComments() async {
    try {
      final String postId = (widget.post["id"] ?? "0").toString();
      
      // 컨트롤러 내에서 최신 포스트 맵 객체 탐색
      final livePost = controller.missionPosts.firstWhere(
        (p) => p["id"].toString() == postId,
        orElse: () => controller.freePosts.firstWhere(
          (p) => p["id"].toString() == postId,
          orElse: () => widget.post, 
        ),
      );

      // 컨트롤러에 주입된 public 메서드를 호출하여 최신 댓글 바인딩 완료
      await controller.loadCommentsForPost(livePost);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isInitLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF8DC695); 
    final String postId = (widget.post["id"] ?? "0").toString();

    return AnimatedPadding(
      padding: MediaQuery.of(context).viewInsets,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Text(
              replyingTargetComment == null ? "댓글" : "${replyingTargetComment!["author"]}님에게 답글 남기는 중", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
            ),
            const Divider(height: 20),
            
            Expanded(
              child: _isInitLoading
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(brandColor)))
                  : Obx(() {
                      final livePost = controller.missionPosts.firstWhere(
                        (p) => p["id"].toString() == postId,
                        orElse: () => controller.freePosts.firstWhere(
                          (p) => p["id"].toString() == postId,
                          orElse: () => widget.post, 
                        ),
                      );

                      final List<dynamic> commentsList = livePost["comments"] is RxList 
                          ? livePost["comments"] 
                          : (livePost["comments"] ?? []);

                      if (commentsList.isEmpty) {
                        return const Center(child: Text("첫 댓글을 남겨보세요!", style: TextStyle(color: Colors.grey, fontSize: 13)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: commentsList.length,
                        itemBuilder: (context, idx) {
                          final comment = commentsList[idx];
                          final List<dynamic> repliesList = comment["replies"] is RxList ? comment["replies"] : [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
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
                                          const SizedBox(height: 6),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                replyingTargetComment = comment;
                                              });
                                            },
                                            child: const Text("답글 달기", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => controller.toggleCommentLike(comment),
                                      child: Obx(() {
                                        final bool isLiked = comment["isCommentLiked"]?.value ?? false;
                                        final int likesCount = comment["likes"]?.value ?? 0;
                                        return Column(
                                          children: [
                                            Icon(
                                              isLiked ? Icons.favorite : Icons.favorite_border_rounded, 
                                              size: 18, 
                                              color: isLiked ? Colors.red : Colors.grey.shade400
                                            ),
                                            const SizedBox(height: 2),
                                            Text("$likesCount", style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                          ],
                                        );
                                      }),
                                    )
                                  ],
                                ),
                              ),
                              
                              if (repliesList.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 44.0, bottom: 6),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: repliesList.length,
                                    itemBuilder: (context, rIdx) {
                                      final reply = repliesList[rIdx];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const CircleAvatar(radius: 14, backgroundColor: brandColor, child: Icon(Icons.person, color: Colors.white, size: 14)),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(reply["author"] ?? "익명", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                                                  const SizedBox(height: 2),
                                                  Text(reply["content"] ?? "", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => controller.toggleCommentLike(reply),
                                              child: Obx(() {
                                                final bool isReplyLiked = reply["isCommentLiked"]?.value ?? false;
                                                final int replyLikes = reply["likes"]?.value ?? 0;
                                                return Column(
                                                  children: [
                                                    Icon(
                                                      isReplyLiked ? Icons.favorite : Icons.favorite_border_rounded, 
                                                      size: 14, 
                                                      color: isReplyLiked ? Colors.red : Colors.grey.shade400
                                                    ),
                                                    Text("$replyLikes", style: const TextStyle(fontSize: 10, color: Colors.black54)),
                                                  ],
                                                );
                                              }),
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    }),
            ),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (replyingTargetComment != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${replyingTargetComment!["author"]}님에게 답글 작성 중...", 
                              style: const TextStyle(fontSize: 12, color: brandColor, fontWeight: FontWeight.w500)
                            ),
                            GestureDetector(
                              onTap: () => setState(() => replyingTargetComment = null),
                              child: const Icon(Icons.cancel, size: 16, color: Colors.grey),
                            )
                          ],
                        ),
                      ),
                    Row(
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
                                    decoration: InputDecoration(
                                      hintText: replyingTargetComment == null ? "회원님의 생각을 남겨보세요." : "답글을 입력하세요.",
                                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send_rounded, color: brandColor, size: 20),
                                  onPressed: () async {
                                    final text = textController.text.trim();
                                    if (text.isEmpty) return;

                                    bool success = false;
                                    if (replyingTargetComment == null) {
                                      success = await controller.addCommentToPost(postId, text);
                                    } else {
                                      success = await controller.addReplyToComment(postId, replyingTargetComment!, text);
                                    }

                                    if (success) {
                                      textController.clear();
                                      setState(() {
                                        replyingTargetComment = null;
                                      });
                                      // 댓글 등록 즉시 데이터 재로드 유도
                                      _loadCurrentComments();
                                    }
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
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