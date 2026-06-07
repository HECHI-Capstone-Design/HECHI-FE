import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../controllers/review_list_controller.dart';
import '../../book_detail_page/controllers/book_detail_controller.dart';
import '../../review_detail/widgets/option_bottom_sheet.dart';
import '../../../app/controllers/app_controller.dart';

enum ReviewCardType { simple, detail, }

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final bool isMyReview;
  final Function(int)? onLikeToggle;
  final Function(int)? onEdit;
  final Function(int)? onDelete;

  final RxBool isExpanded = false.obs;
  final RxBool isSpoilerVisible = false.obs;

  static const int maxInitialLines = 5;
  static const int maxExpandedLines = 20;

  final ReviewCardType type;
  final EdgeInsetsGeometry? contentPadding;

  ReviewCard({
    super.key,
    required this.review,
    this.isMyReview = false,
    this.onLikeToggle,
    this.onEdit,
    this.onDelete,
    this.type = ReviewCardType.detail,
    this.contentPadding,
  });

  // ==========================
  // 좋아요 토글
  // ==========================
  void _toggleLike() {
    if (onLikeToggle != null) {
      onLikeToggle!(review['id']);
    }
  }

  // ==========================
  // 텍스트 줄수 계산
  // ==========================
  bool _isTextClipped(
      String text,
      BoxConstraints constraints,
      TextStyle style,
      int maxLines,
      ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      locale: const Locale('ko'),
    )..layout(maxWidth: constraints.maxWidth);

    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final String content = (review['content'] ?? '').toString();
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // ===== 서버 상태 =====
    final double rating = (review["rating"] as num?)?.toDouble() ?? 0.0;
    final bool isLiked = review["is_liked"] ?? false;
    final int likeCount = review["like_count"] ?? 0;
    final int commentCount = review["comment_count"] ?? 0;

    final Color activeColor = AppColors.primary;
    final Color inactiveColor = AppColors.textHint;

    final Color likeColor = isLiked ? activeColor : inactiveColor;
    final IconData likeIcon =
    isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          final result = await Get.toNamed(
            '/review_detail',
            arguments: review['id'],
          );

          if (result != null) {
            if (Get.isRegistered<BookDetailController>()) {
              Get.find<BookDetailController>().syncReviewChange(result);
            }
            if (Get.isRegistered<ReviewListController>()) {
              Get.find<ReviewListController>().syncReviewChange(result);
            }
          }
        },
        child: Container(
          width: double.infinity,
          padding: contentPadding ??
              EdgeInsets.symmetric(
                horizontal: 17,
                vertical: type == ReviewCardType.simple ? 15 : 20,
              ),
          decoration: BoxDecoration(
            border: type == ReviewCardType.simple
                ? null
                : const Border(
              bottom: BorderSide(color: AppColors.divider),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================
              // 1. 헤더
              // ==========================
              if (type == ReviewCardType.simple) ...[
                _buildSimpleHeader(rating),
                const SizedBox(height: 5),
              ]
              else ...[
                _buildDetailHeader(rating),
                const SizedBox(height: 12),
              ],

              // ==========================
              // 2. 내용
              // ==========================
              Obx(() {
                final expanded = isExpanded.value;
                final spoilerVisible = isSpoilerVisible.value;

                if ((review["is_spoiler"] ?? false) && !spoilerVisible) {
                  return Row(
                    children: [
                      const Text(
                        "스포일러가 포함되어 있습니다.",
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => isSpoilerVisible.value = true,
                        child: const Text(
                          "보기",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final clipped5 = _isTextClipped(
                      content,
                      constraints,
                      const TextStyle(fontSize: 14, height: 1.5),
                      maxInitialLines,
                    );
                    final clipped20 = _isTextClipped(
                      content,
                      constraints,
                      const TextStyle(fontSize: 14, height: 1.5),
                      maxExpandedLines,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content,
                          maxLines:
                          expanded ? maxExpandedLines : maxInitialLines,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        if (clipped5 && !expanded)
                          GestureDetector(
                            onTap: () => isExpanded.value = true,
                            child: const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                "더보기",
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          )
                        else if (expanded && clipped20)
                          GestureDetector(
                            onTap: () async {
                              final result = await Get.toNamed(
                                '/review_detail',
                                arguments: review['id'],
                              );
                              if (result != null) {
                                if (Get.isRegistered<BookDetailController>()) {
                                  Get.find<BookDetailController>().syncReviewChange(result);
                                }
                                if (Get.isRegistered<ReviewListController>()) {
                                  Get.find<ReviewListController>().syncReviewChange(result);
                                }
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                "전체보기",
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              }),
              const SizedBox(height: 16),

              // ==========================
              // 3. 하단 액션바
              // ==========================
              Row(
                children: [
                  // 좋아요
                  type == ReviewCardType.simple
                      ? _buildSimpleBottom(likeIcon, likeColor, likeCount, commentCount)
                      : _buildDetailBottom(likeIcon, likeColor, likeCount, commentCount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================
  // 헤더들
  // ==========================
  Widget _buildAvatar(double radius) {
    final appController = Get.find<AppController>();
    final isMe = review['is_my_review'] == true;
    return Obx(() {
      final url = isMe
          ? (appController.userProfile['profileImageUrl']?.toString() ?? '')
          : (review['profileImageUrl']?.toString() ?? '');
      if (url.isNotEmpty) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: NetworkImage(url),
          onBackgroundImageError: (_, __) {},
        );
      }
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        child: Icon(Icons.person, color: Colors.white, size: radius * 1.2),
      );
    });
  }

  Widget _buildSimpleHeader(double rating){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (rating > 0)
          RatingBarIndicator(
            rating: rating,
            itemBuilder: (context, index) => const Icon(Icons.star_rounded, color: AppColors.star),
            itemCount: 5,
            itemSize: 14.0,
            direction: Axis.horizontal,
          )
        else
          const SizedBox(),
        Row(
          children: [
            Text(
                review['nickname'] ?? "User ${review['user_id']}",
                style: const TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 13,
                    fontWeight: FontWeight.w500
                )
            ),
            const SizedBox(width: 8),
            _buildAvatar(14),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailHeader(double rating){
    final String date = (review['created_at'] ?? '').toString().split('T')[0];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(18),
        const SizedBox(width: 10),

        // 정보 영역
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 닉네임, 날짜
              Row(
                children: [
                  Text(
                    review['nickname'] ?? "User ${review['user_id']}",
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),

              if (rating > 0)
                RatingBarIndicator(
                  rating: rating,
                  itemBuilder: (context, index) => const Icon(Icons.star_rounded, color: AppColors.star),
                  itemCount: 5,
                  itemSize: 14.0,
                  direction: Axis.horizontal,
                ),
            ],
          ),
        ),

        // option_overlay
        if (isMyReview)
          GestureDetector(
            onTap: () {
              Get.bottomSheet(
                OptionBottomSheet(
                  reviewId: review['id'],
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
                backgroundColor: Colors.transparent,
              );
            },
            child: const Icon(Icons.more_horiz, size: 20, color: AppColors.border),
          ),
      ],
    );
  }

  Widget _buildSimpleBottom(
      IconData likeIcon,
      Color likeColor,
      int likeCount,
      int commentCount,
      ) {
    return Row(
      children: [
        GestureDetector(
          onTap: _toggleLike,
          child: Row(
            children: [
              Icon(likeIcon, size: 16, color: likeColor),
              const SizedBox(width: 4),
              Text(
                "$likeCount",
                style: TextStyle(color: likeColor, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 16, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(
              "$commentCount",
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailBottom(
      IconData likeIcon,
      Color likeColor,
      int likeCount,
      int commentCount,
      ) {
    return Row(
      children: [
        GestureDetector(
          onTap: _toggleLike,
          child: Row(
            children: [
              Icon(likeIcon, size: 16, color: likeColor),
              const SizedBox(width: 4),
              Text(
                "좋아요 $likeCount",
                style: TextStyle(
                  color: likeColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          "댓글 $commentCount",
          style: const TextStyle(
            color: AppColors.textMedium,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
