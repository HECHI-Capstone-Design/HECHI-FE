import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../controllers/review_detail_controller.dart';
import '../widgets/option_bottom_sheet.dart';

class ReviewDetailPage extends GetView<ReviewDetailController> {
  const ReviewDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => _goBack(),
          ),
          title: const Text(
            '코멘트',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            Obx(() {
              final isMyReview = controller.review['is_my_review'] ?? false;
              if (!isMyReview) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 17),
                child: IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.black),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Get.bottomSheet(
                      OptionBottomSheet(
                        reviewId: controller.reviewId,
                        onEdit: (_) => controller.showEditOverlay(),
                        onDelete: (_) => controller.deleteReview(),
                      ),
                      backgroundColor: Colors.transparent,
                    );
                  },
                ),
              );
            }),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingReview.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainContent(),
                        _buildActionButtons(),
                        _buildStatsLine(),
                        const Divider(thickness: 1, height: 1, color: Color(0xFFF3F3F3)),
                        _buildCommentList(),
                      ],
                    ),
                  );
                }),
              ),
              _buildBottomInputField(context),
            ],
          ),
        ),
      ),
    );
  }

  void _goBack() {
    Get.back(result: {
      "review_id": controller.reviewId,
      "status": "updated",
      "is_liked": controller.review['is_liked'],
      "like_count": controller.review['like_count'],
      "content": controller.review['content'],
      "is_spoiler": controller.review['is_spoiler'],
      "comment_count": controller.review['comment_count'],
    });
  }

  // ==========================
  // 1. 리뷰 본문 및 책 정보 영역
  // ==========================
  Widget _buildMainContent() {
    final review = controller.review;
    final book = controller.book;

    final double rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
    final String nickname = review['nickname'] ?? "User ${review['user_id']}";

    final String date = (review['created_at'] ?? '').toString().split('T')[0];
    final String content = review['content'] ?? "";
    final String bookTitle = book['title'] ?? "";
    final String bookAuthor = (book['authors'] is List && (book['authors'] as List).isNotEmpty)
        ? book['authors'][0]
        : "저자 미상";
    final String bookImage = book['thumbnail'] ?? "";

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFF4DB56C).withOpacity(0.5),
                          child: const Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$nickname $date",
                          style: const TextStyle(color: Color(0xFF717171), fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // 별점
                    if (rating > 0)
                      RatingBarIndicator(
                        rating: rating,
                        itemBuilder: (context, index) => const Icon(Icons.star_rounded, color: Color(0xFFFFD700)),
                        itemCount: 5,
                        itemSize: 16.0,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(height: 10),

                    Text(
                      bookTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    Text(
                      bookAuthor,
                      style: const TextStyle(color: Color(0xFF717171), fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              if (bookImage.isNotEmpty)
                Container(
                  width: 70,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade200),
                    image: DecorationImage(
                      image: NetworkImage(bookImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // ==========================
  // 2. 좋아요 / 댓글 버튼 영역
  // ==========================
  Widget _buildActionButtons() {
    return Column(
      children: [
        const Divider(thickness: 1, height: 1, color: Color(0xFFF3F3F3)),
        SizedBox(
          height: 48,
          child: Row(
            children: [
              // 좋아요 버튼
              Expanded(
                child: Obx(() {
                  final isLiked = controller.review['is_liked'] ?? false;

                  return InkWell(
                    onTap: controller.toggleLike,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                          size: 18,
                          color: isLiked ? const Color(0xFF4DB56C) : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "좋아요",
                          style: TextStyle(
                              color: isLiked ? const Color(0xFF4DB56C) : Colors.grey,
                              fontWeight: FontWeight.w500
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              Container(width: 1, height: 20, color: const Color(0xFFF3F3F3)),
              // 댓글 버튼
              Expanded(
                child: InkWell(
                  onTap: () {
                    // 댓글 입력창으로 포커스 이동 기능 추가
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.comment_outlined, size: 18, color: Colors.grey),
                      SizedBox(width: 6),
                      Text("댓글", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(thickness: 1, height: 1, color: Color(0xFFF3F3F3)),
      ],
    );
  }

  // ==========================
  // 3. 통계 텍스트 영역
  // ==========================
  Widget _buildStatsLine() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Obx(() => Text(
        "좋아요 ${controller.review['like_count'] ?? 0}   "
            "댓글 ${controller.review['comment_count'] ?? 0}",
        style: const TextStyle(color: Color(0xFF717171), fontSize: 13),
      )),
    );
  }

  // ==========================
  // 4. 댓글 리스트 영역
  // ==========================
  Widget _buildCommentList() {
    return Obx(() {
      if (controller.isLoadingComments.value) {
        return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
      }
      if (controller.comments.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(
            child: Text("아직 댓글이 없습니다.", style: TextStyle(color: Colors.grey)),
          ),
        );
      }

      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: controller.comments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemBuilder: (context, index) {
          final comment = controller.comments[index];
          final myUserId = controller.box.read("user_id") ?? -1;
          final isMyComment = int.tryParse(comment['user_id'].toString()) == myUserId;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF4DB56C).withOpacity(0.5),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              comment['user_nickname'] ?? "User ${comment['user_id']}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              (comment['created_at'] ?? "").toString().split('T')[0],
                              style: const TextStyle(fontSize: 11, color: Color(0xFFABABAB)),
                            ),
                          ],
                        ),
                        if (isMyComment)
                          GestureDetector(
                            onTap: () =>
                                controller.deleteComment(comment['id']),
                            child: const Text(
                              "삭제",
                              style: TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment['content'] ?? "",
                      style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF3F3F3F)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    });
  }

  // ==========================
  // 5. 하단 입력창
  // ==========================
  Widget _buildBottomInputField(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset > 0 ? bottomInset : 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F3F3))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF4DB56C).withOpacity(0.5),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              constraints: const BoxConstraints(
                maxHeight: 120,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: controller.commentInputController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "코멘트에 댓글을 남겨보세요",
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: controller.postComment,
            child: const Text("등록", style: TextStyle(color: Color(0xFF4DB56C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
