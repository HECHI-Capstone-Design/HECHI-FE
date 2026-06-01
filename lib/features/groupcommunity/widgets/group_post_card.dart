import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/features/book_note/widgets/bookmark_item.dart';
import 'package:hechi/features/book_note/widgets/highlight_item.dart';
import 'package:hechi/features/book_note/widgets/memo_item.dart';

class GroupPostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const GroupPostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GroupController>();

    // 🚨 [수정 핵심]: 게시글의 고유 bookId를 안전하게 격리 추출하여 엉뚱한 책 이동 버퍼 차단
    final int targetBookId = int.tryParse(post["bookId"]?.toString() ?? "0") ?? 0;

    final bool hasPollData = post["hasPoll"] == true || 
                             post["isDiscussion"] == true || 
                             (post["pollQuestion"] != null && post["pollQuestion"].toString().trim().isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        // 🚨 [완치 구역]: 문법적 중복 결함이었던 Cross 단어를 삭제하여 정품 규격으로 복구했습니다.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 (작성자 정보 및 더보기 메뉴)
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFF5F5F5),
                child: Icon(Icons.person, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post["author"] ?? "여름", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(post["date"] ?? "방금 전", style: const TextStyle(color: Colors.grey, fontSize: 11)),
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

          // 2. 게시글 본문 내용
          Text(
            post["content"] ?? "",
            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          // 3. 투표/토론 섹션
          if (hasPollData) _buildPollSection(controller),

          // 4. 연동된 도서 미니 카드 (내부 고유 식별 타깃 바인딩)
          if (targetBookId != 0)
            GestureDetector(
              onTap: () {
                print("🎯 [도서 상세 이동] 게시글에서 선택한 고유 책 ID로 라우팅 시도: $targetBookId");
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
                      child: (post["bookCover"] != null && post["bookCover"].toString().startsWith('http'))
                          ? Image.network(
                              post["bookCover"],
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
                            post["bookTitle"] ?? "첨부된 도서",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            post["bookAuthor"] ?? "저자 미상",
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

          if (post["recordType"] != null)
            _buildSharedNoteCard(post),

          const SizedBox(height: 16),

          // 5. 푸터 (좋아요 / 댓글 개수 영역)
          Row(
            children: [
              Obx(() => GestureDetector(
                onTap: () => controller.togglePostLike(post),
                child: Row(
                  children: [
                    Icon(
                      post["isLiked"]?.value == true ? Icons.favorite : Icons.favorite_border,
                      color: post["isLiked"]?.value == true ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text("${post["likes"]?.value ?? 0}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              )),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 20),
              const SizedBox(width: 4),
              Obx(() => Text("${post["comments"]?.length ?? 0}", style: const TextStyle(fontSize: 13, color: Colors.grey))),
            ],
          ),
        ],
      ),
    );
  }

  // 투표 컴포넌트 뷰 빌더
  Widget _buildPollSection(GroupController controller) {
    return Obx(() {
      List<String> options = [];
      if (post["pollOptions"] is List) {
        options = List<String>.from(post["pollOptions"]);
      } else if (post["options"] is List) {
        options = List<String>.from(post["options"]);
      }

      if (options.isEmpty) return const SizedBox.shrink();

      List<int> votes = [];
      if (post["pollVotes"] is List) {
        votes = List<int>.from(post["pollVotes"]);
      } else if (post["votes"] is List) {
        votes = List<int>.from(post["votes"]);
      }
      
      if (votes.length < options.length) {
        votes = List<int>.filled(options.length, 0);
      }

      int selectedIdx = -1;
      if (post["selectedOption"] is RxInt) {
        selectedIdx = (post["selectedOption"] as RxInt).value;
      } else if (post["selectedOption"] is int) {
        selectedIdx = post["selectedOption"];
      }

      final int totalVotes = votes.fold(0, (sum, item) => sum + item);

      return Container(
        margin: const EdgeInsets.only(bottom: 16, top: 4),
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
                const Icon(Icons.how_to_vote, size: 18, color: Color(0xFF8DC695)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post["pollQuestion"] ?? post["title"] ?? "투표에 참여해주세요",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(options.length, (idx) {
              final double percent = totalVotes == 0 ? 0 : (votes[idx] / totalVotes);
              final bool isVoted = selectedIdx != -1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: isVoted ? null : () => controller.castVote(post, idx),
                  child: Stack(
                    children: [
                      Container(
                        height: 40,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDEE2E6)),
                        ),
                      ),
                      if (isVoted)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 40,
                          width: MediaQuery.of(Get.context!).size.width * percent,
                          decoration: BoxDecoration(
                            color: selectedIdx == idx 
                                ? const Color(0xFF8DC695).withOpacity(0.25) 
                                : const Color(0xFFE9ECEF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              options[idx],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selectedIdx == idx ? FontWeight.bold : FontWeight.normal,
                                color: selectedIdx == idx ? const Color(0xFF4EB56D) : Colors.black87,
                              ),
                            ),
                            if (isVoted)
                              Text(
                                "${(percent * 100).toInt()}%",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                              ),
                          ],
                        ),
                      ),
                    ],
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
    });
  }

  Widget _buildSharedNoteCard(Map<String, dynamic> post) {
    final String recordType = post["recordType"]?.toString() ?? "";
    final Map<String, dynamic> data =
    post["recordData"] is Map
        ? Map<String, dynamic>.from(post["recordData"])
        : {};

    if (data.isEmpty) return const SizedBox.shrink();

    final int bookId = int.tryParse(post["bookId"]?.toString() ?? "0") ?? 0;

    void goToBookNote() {
      if (bookId != 0) {
        Get.toNamed('/book_note', arguments: {
          'bookId': bookId,
          'tabIndex': recordType == "BOOKMARK" ? 0
              : recordType == "HIGHLIGHT" ? 1
              : 2,
        });
      }
    }

    return GestureDetector(
      onTap: goToBookNote,
      child: switch (recordType) {
        "BOOKMARK"  => BookmarkItem(data: data, isReadOnly: true, isPreview: true),
        "HIGHLIGHT" => HighlightItem(data: data, isReadOnly: true, isPreview: true),
        "NOTE"      => MemoItem(data: data, isReadOnly: true, isPreview: true),
        _           => const SizedBox.shrink(),
      },
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
                Get.find<GroupController>().addReport(reasons[idx], post);
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