import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/features/groupcommunity/widgets/group_comment_bottom_sheet.dart';

class GroupPostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const GroupPostCard({Key? key, required this.post}) : super(key: key);

  @override
  State<GroupPostCard> createState() => _GroupPostCardState();
}

class _GroupPostCardState extends State<GroupPostCard> {
  final GroupController controller = Get.find<GroupController>();
  final Rxn<Map<String, dynamic>> rxDiscussion = Rxn<Map<String, dynamic>>();
  final RxBool hasPoll = false.obs;

  @override
  void initState() {
    super.initState();
    _fetchDiscussionDetailsFromServer();
  }

  Future<void> _fetchDiscussionDetailsFromServer() async {
    final String pId = (widget.post["id"] ?? "0").toString();
    final String token = GetStorage().read('access_token') ?? "";
    try {
      final response = await http.get(
        Uri.parse('${controller.baseUrl}/groups/posts/$pId'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> detailData = jsonDecode(utf8.decode(response.bodyBytes));
        final dynamic discussionObj = detailData["discussion"];
        
        if (discussionObj is Map && discussionObj.isNotEmpty) {
          rxDiscussion.value = Map<String, dynamic>.from(discussionObj);
          hasPoll.value = true;
          
          // 🚨 [긴급 수리]: 상세 조회 응답 객체에 comments가 누락되어 기존 댓글 데이터를 초기화하는 현상 원천 차단
          final dynamic existingComments = widget.post["comments"];
          
          widget.post["discussion"] = discussionObj;
          widget.post["hasPoll"] = true;
          widget.post["isDiscussion"] = true;
          
          // 기존 댓글 자원이 이미 들어와 있는 상태라면 오버라이딩되지 않도록 안전하게 락인(Lock) 마감
          if (existingComments != null) {
            widget.post["comments"] = existingComments;
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final String currentPostId = (widget.post["id"] ?? "0").toString();
    final int targetBookId = int.tryParse(widget.post["bookId"]?.toString() ?? "0") ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF8DC695),
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.post["author"] ?? "여름", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(widget.post["date"] ?? "방금 전", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                onPressed: () => _showActionSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            widget.post["content"] ?? "",
            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
          ),
          
          Obx(() {
            if (!hasPoll.value || rxDiscussion.value == null) return const SizedBox.shrink();
            return _buildPollSection(rxDiscussion.value!);
          }),

          if (targetBookId != 0) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Get.toNamed('/book/detail', arguments: targetBookId);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: (widget.post["bookCover"] != null && widget.post["bookCover"].toString().startsWith('http'))
                          ? Image.network(
                              widget.post["bookCover"],
                              width: 46,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(width: 46, height: 64, color: Colors.grey, child: const Icon(Icons.book, color: Colors.white24)),
                            )
                          : Container(width: 46, height: 64, color: Colors.grey, child: const Icon(Icons.book, color: Colors.white24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post["bookTitle"] ?? "첨부된 도서",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.post["bookAuthor"] ?? "저자 미상",
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          Row(
            children: [
              Obx(() => GestureDetector(
                onTap: () => controller.togglePostLike(widget.post),
                child: Row(
                  children: [
                    Icon(
                      widget.post["isLiked"]?.value == true ? Icons.favorite : Icons.favorite_border,
                      color: widget.post["isLiked"]?.value == true ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text("${widget.post["likes"]?.value ?? 0}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              )),
              const SizedBox(width: 16),
              
              Obx(() {
                final livePost = controller.missionPosts.firstWhere(
                  (p) => p["id"].toString() == currentPostId,
                  orElse: () => controller.freePosts.firstWhere(
                    (p) => p["id"].toString() == currentPostId,
                    orElse: () => widget.post,
                  ),
                );
                
                final List<dynamic> currentCommentsList = livePost["comments"] is RxList 
                    ? livePost["comments"] 
                    : (livePost["comments"] ?? []);

                return GestureDetector(
                  onTap: () {
                    Get.bottomSheet(
                      GroupCommentBottomSheet(post: livePost),
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black.withOpacity(0.4),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        "${currentCommentsList.length}",
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollSection(Map<String, dynamic> discussion) {
    final String pollQuestion = discussion["question"] ?? "투표에 참여해주세요";
    final List<dynamic> options = discussion["options"] ?? [];
    final int totalVotes = discussion["totalVotes"] ?? 0;
    final int? myVoteOptionId = discussion["myVoteOptionId"]; 
    final bool isVoted = myVoteOptionId != null;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote, size: 18, color: Color(0xFF4EB56D)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pollQuestion,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(options.length, (idx) {
            final Map<String, dynamic> option = options[idx];
            final int optionId = option["optionId"] ?? (idx + 1);
            final String label = option["label"] ?? "";
            final int voteCount = option["voteCount"] ?? 0;

            final double percent = totalVotes == 0 ? 0 : (voteCount / totalVotes);
            final bool isMyVote = myVoteOptionId == optionId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: isVoted ? null : () async {
                  await controller.castVote(widget.post, idx);
                  await _fetchDiscussionDetailsFromServer();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(
                        height: 40,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isMyVote ? const Color(0xFF4EB56D) : const Color(0xFFDEE2E6),
                            width: isMyVote ? 1.5 : 1,
                          ),
                        ),
                      ),
                      if (isVoted && percent > 0)
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: percent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isMyVote 
                                      ? const Color(0xFF4EB56D).withOpacity(0.18) 
                                      : const Color(0xFFE9ECEF),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isMyVote ? FontWeight.bold : FontWeight.normal,
                                color: isMyVote ? const Color(0xFF4EB56D) : Colors.black87,
                              ),
                            ),
                            if (isVoted)
                              Text(
                                "${(percent * 100).toInt()}% ($voteCount명)",
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold, 
                                  color: isMyVote ? const Color(0xFF4EB56D) : Colors.black54
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (totalVotes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2),
              child: Text("총 $totalVotes명 참여 완료", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_problem_outlined, color: Colors.red),
              title: const Text("게시글 신고하기", style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                _showReportReasonSelector(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text("내용 복사"),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportReasonSelector(BuildContext context) {
    final List<String> reasons = ["부적절한 홍보 게시글", "음란성 또는 청소년에게 부적합한 내용", "명예훼손/사생활 침해", "욕설 및 비하 발언"];
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("신고 사유 선택", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ...List.generate(reasons.length, (idx) => ListTile(
              title: Text(reasons[idx]),
              onTap: () {
                Get.find<GroupController>().addReport(reasons[idx], widget.post);
                Get.back();
                _showReportSuccessDialog();
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showReportSuccessDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    "신고",
                    style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 24),
              const Text(
                "신고가 완료 되었습니다.",
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      if (Get.isDialogOpen!) Get.back();
    });
  }
}