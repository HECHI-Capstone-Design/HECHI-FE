import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/core/utils/time_ago.dart';
import 'package:hechi/app/controllers/app_controller.dart';
import 'package:hechi/core/widgets/user_avatar.dart';

/// 알림 딥링크 전용 게시글 상세 페이지.
/// bottomSheet가 아닌 독립 라우트로 열려 back 시 GroupMainView로 복귀한다.
class GroupPostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final String? initialCommentId;

  const GroupPostDetailPage({
    Key? key,
    required this.post,
    this.initialCommentId,
  }) : super(key: key);

  @override
  State<GroupPostDetailPage> createState() => _GroupPostDetailPageState();
}

class _GroupPostDetailPageState extends State<GroupPostDetailPage> {
  final GroupController controller = Get.find<GroupController>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 댓글 ID → GlobalKey 매핑 (정확한 스크롤 위치)
  final Map<String, GlobalKey> _commentKeys = {};

  Map<String, dynamic>? _replyingTo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final String postId = (widget.post['id'] ?? '0').toString();
      final livePost = controller.missionPosts.firstWhere(
        (p) => p['id'].toString() == postId,
        orElse: () => controller.freePosts.firstWhere(
          (p) => p['id'].toString() == postId,
          orElse: () => widget.post,
        ),
      );
      await controller.loadCommentsForPost(livePost);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.initialCommentId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToComment(widget.initialCommentId!);
          });
        }
      }
    }
  }

  void _scrollToComment(String commentId) {
    final key = _commentKeys[commentId];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      alignment: 0.2,
    );
  }

  List<dynamic> _getComments() {
    final String postId = (widget.post['id'] ?? '0').toString();
    final livePost = controller.missionPosts.firstWhere(
      (p) => p['id'].toString() == postId,
      orElse: () => controller.freePosts.firstWhere(
        (p) => p['id'].toString() == postId,
        orElse: () => widget.post,
      ),
    );
    final raw = livePost['comments'];
    return raw is RxList ? raw : (raw ?? []);
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primaryLight;
    final String postContent = widget.post['content']?.toString() ?? '';
    final String postAuthor = widget.post['author']?.toString() ?? '';
    final String postTime = timeAgo(
      widget.post['createdAt']?.toString() ?? widget.post['created_at']?.toString() ?? '',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text('게시글', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(height: 1),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 게시글 헤더
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                buildUserAvatar(widget.post['profileImageUrl']?.toString(), 20),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(postAuthor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(postTime, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 게시글 본문
                          if (postContent.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(postContent, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                            ),

                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('댓글', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),

                          // 댓글 목록
                          Obx(() {
                            final comments = _getComments();
                            if (comments.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(child: Text('첫 댓글을 남겨보세요!', style: TextStyle(color: Colors.grey))),
                              );
                            }
                            return Column(
                              children: List.generate(comments.length, (idx) {
                                final comment = comments[idx];
                                final String cId = comment['id']?.toString() ?? '';
                                _commentKeys.putIfAbsent(cId, () => GlobalKey());
                                final bool isTarget = cId == widget.initialCommentId;
                                final List<dynamic> replies = comment['replies'] is RxList
                                    ? comment['replies']
                                    : (comment['replies'] ?? []);

                                return _CommentItem(
                                  key: _commentKeys[cId],
                                  comment: comment,
                                  replies: replies,
                                  isHighlighted: isTarget,
                                  onReply: (c) => setState(() => _replyingTo = c),
                                  controller: controller,
                                );
                              }),
                            );
                          }),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ),

            // 댓글 입력창
            _CommentInput(
              textController: _textController,
              replyingTo: _replyingTo,
              onCancelReply: () => setState(() => _replyingTo = null),
              onSend: () async {
                final text = _textController.text.trim();
                if (text.isEmpty) return;
                bool ok;
                if (_replyingTo != null) {
                  ok = await controller.addReplyToComment(
                    (widget.post['id'] ?? '0').toString(),
                    _replyingTo,
                    text,
                  );
                } else {
                  ok = await controller.addCommentToPost(widget.post, text);
                }
                if (ok) {
                  _textController.clear();
                  setState(() => _replyingTo = null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 댓글 아이템 위젯 (하이라이트 지원)
// ─────────────────────────────────────────
class _CommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;
  final List<dynamic> replies;
  final bool isHighlighted;
  final void Function(Map<String, dynamic>) onReply;
  final GroupController controller;

  const _CommentItem({
    Key? key,
    required this.comment,
    required this.replies,
    required this.isHighlighted,
    required this.onReply,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primaryLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.primarySurface.withOpacity(0.6) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildUserAvatar(comment['profileImageUrl']?.toString(), 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(comment['author'] ?? '익명',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(
                          timeAgo(comment['createdAt']?.toString() ?? comment['created_at']?.toString() ?? ''),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment['content'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => onReply(comment),
                      child: const Text('답글 달기',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => controller.toggleCommentLike(comment),
                child: Obx(() {
                  final bool liked = comment['isCommentLiked']?.value ?? false;
                  final int count = comment['likes']?.value ?? 0;
                  return Column(
                    children: [
                      Icon(liked ? Icons.favorite : Icons.favorite_border_rounded,
                          size: 18, color: liked ? Colors.red : Colors.grey.shade400),
                      Text('$count', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  );
                }),
              ),
            ],
          ),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: Column(
                children: replies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildUserAvatar(reply['profileImageUrl']?.toString(), 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(reply['author'] ?? '익명',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  timeAgo(reply['createdAt']?.toString() ?? reply['created_at']?.toString() ?? ''),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ]),
                              const SizedBox(height: 2),
                              Text(reply['content'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                            ],
                          ),
                        ),
                        Obx(() {
                          final bool liked = reply['isCommentLiked']?.value ?? false;
                          final int count = reply['likes']?.value ?? 0;
                          return GestureDetector(
                            onTap: () => controller.toggleCommentLike(reply),
                            child: Column(children: [
                              Icon(liked ? Icons.favorite : Icons.favorite_border_rounded,
                                  size: 14, color: liked ? Colors.red : Colors.grey.shade400),
                              Text('$count', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                            ]),
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 댓글 입력창
// ─────────────────────────────────────────
class _CommentInput extends StatelessWidget {
  final TextEditingController textController;
  final Map<String, dynamic>? replyingTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;

  const _CommentInput({
    required this.textController,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primaryLight;
    final appController = Get.find<AppController>();
    final double safeBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, safeBottom > 0 ? safeBottom + 4 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyingTo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${replyingTo!["author"]}님에게 답글 작성 중...',
                      style: const TextStyle(fontSize: 12, color: brandColor, fontWeight: FontWeight.w500)),
                  GestureDetector(
                    onTap: onCancelReply,
                    child: const Icon(Icons.cancel, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Obx(() => buildUserAvatar(appController.userProfile['profileImageUrl']?.toString(), 18)),
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
                            hintText: replyingTo == null ? '회원님의 생각을 남겨보세요.' : '답글을 입력하세요.',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: brandColor, size: 20),
                        onPressed: onSend,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
