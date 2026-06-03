import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../../book_detail_page/widgets/overlays/comment_overlay.dart';

class ReviewDetailController extends GetxController {
  final String baseUrl = "https://api.43-202-101-63.sslip.io";
  final box = GetStorage();

  final int reviewId = (Get.arguments is int) ? Get.arguments as int : int.tryParse(Get.arguments.toString()) ?? 0;

  final RxBool isLoadingReview = true.obs;
  final RxBool isLoadingBook = true.obs;
  final RxBool isLoadingComments = true.obs;

  final RxMap<String, dynamic> review = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> book = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> comments = <Map<String, dynamic>>[].obs;

  final TextEditingController commentInputController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchReviewDetail();
    fetchComments();
  }

  Map<String, String> get authHeader {
    final token = box.read('access_token');
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // ==========================
  // 리뷰 상세 조회
  // ==========================
  Future<void> fetchReviewDetail() async {
    try {
      isLoadingReview.value = true;

      final res = await http.get(
        Uri.parse("$baseUrl/reviews/$reviewId"),
        headers: authHeader,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        review.value = data;

        if (data['book_id'] != null) {
          fetchBookDetail(data['book_id']);
        }
      }
    } finally {
      isLoadingReview.value = false;
    }
  }

  // ==========================
  // 책 상세 정보 조회 (제목, 표지, 저자 등)
  // ==========================
  Future<void> fetchBookDetail(int? bookId) async {
    if (bookId == null) return;
    try {
      isLoadingBook.value = true;
      final res = await http.get(Uri.parse("$baseUrl/books/$bookId"));

      if (res.statusCode == 200) {
        book.value = jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (e) {
      print("❌ Book Error: $e");
    } finally {
      isLoadingBook.value = false;
    }
  }

  // ==========================
  // 코멘트 삭제
  // ==========================
  Future<void> deleteReview() async {
    final token = box.read("access_token");
    if (token == null) return;

    final rating = (review["rating"] as num?)?.toDouble() ?? 0.0;

    try {
      http.Response res;

      if (rating == 0.0) {
        // 완전 삭제
        res = await http.delete(
          Uri.parse("$baseUrl/reviews/$reviewId"),
          headers: {"Authorization": "Bearer $token"},
        );
      } else {
        // 내용만 삭제
        res = await http.post(
          Uri.parse("$baseUrl/reviews/upsert"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "book_id": review['book_id'],
            "rating": rating,
            "content": null,
            "is_spoiler": false,
          }),
        );
      }

      if (res.statusCode == 200 || res.statusCode == 204) {
        final bool isRatingAlive = rating > 0.0;

        Get.back(result: {
          "review_id": reviewId,
          "status": "deleted",
          "keep_rating": isRatingAlive,
          "is_liked": review['is_liked'],
          "like_count": review['like_count'],
        });
        Get.snackbar("완료", "삭제되었습니다.");
      } else {
        Get.snackbar("오류", "삭제 실패");
      }
    } catch (e) {
      print("❌ Delete Error: $e");
    }
  }

  // ==========================
  // 코멘트 수정
  // ==========================
  Future<void> updateReview(String newContent, bool isSpoiler) async {
    final token = box.read("access_token");
    if (token == null) return;

    final rating = (review["rating"] as num?)?.toDouble() ?? 0.0;

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/reviews/upsert"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "book_id": review['book_id'],
          "rating": rating == 0.0 ? null : rating,
          "content": newContent,
          "is_spoiler": isSpoiler,
        }),
      );

      if (res.statusCode == 200) {
        review['content'] = newContent;
        review['is_spoiler'] = isSpoiler;
        review.refresh();

        Get.back(result: {
          "review_id": reviewId,
          "status": "updated",
          "content": newContent,
          "is_spoiler": isSpoiler,
          "is_liked": review['is_liked'],
          "like_count": review['like_count'],
          "comment_count": review['comment_count'],
        });

        Get.snackbar("성공", "코멘트가 수정되었습니다.");
      }
    } catch (e) {
      print("❌ 수정 에러: $e");
    }
  }

  // ==========================
  // 코멘트 수정 Overlay
  // ==========================
  void showEditOverlay() {
    Get.bottomSheet(
      CommentOverlay(
        isEditMode: true,
        initialText: review['content'],
        initialSpoiler: review['is_spoiler'],
        onSubmit: updateReview,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
    );
  }

  // ==========================
  // 좋아요 토글
  // ==========================
  Future<void> toggleLike() async {
    final bool prevLiked = review['is_liked'] ?? false;

    review['is_liked'] = !prevLiked;
    review['like_count'] =
        (review['like_count'] ?? 0) + (prevLiked ? -1 : 1);
    review.refresh();

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/reviews/$reviewId/like"),
        headers: authHeader,
      );

      if (res.statusCode == 200) {
        print("✅ 리뷰 좋아요 성공 (ID: $reviewId)");
      } else {
        throw Exception();
      }
    } catch (_) {
      review['is_liked'] = prevLiked;
      review['like_count'] =
          (review['like_count'] ?? 0) + (prevLiked ? 1 : -1);
      review.refresh();
      print("❌ 리뷰 좋아요 실패 (ID: $reviewId)");
    }
  }

  // ==========================
  // 댓글 목록
  // ==========================
  Future<void> fetchComments() async {
    try {
      isLoadingComments.value = true;

      final res = await http.get(
        Uri.parse("$baseUrl/reviews/$reviewId/comments"),
        headers: authHeader,
      );

      if (res.statusCode == 200) {
        final List list = jsonDecode(utf8.decode(res.bodyBytes));
        comments.value = list.cast<Map<String, dynamic>>();
      }
    } finally {
      isLoadingComments.value = false;
    }
  }

  // ==========================
  // 댓글 작성
  // ==========================
  Future<void> postComment() async {
    final text = commentInputController.text.trim();
    if (text.isEmpty) return;

    review['comment_count'] = (review['comment_count'] ?? 0) + 1;
    review.refresh();

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/reviews/$reviewId/comments"),
        headers: authHeader,
        body: jsonEncode({ "content": text }),
      );

      if (res.statusCode == 200) {
        commentInputController.clear();
        await fetchComments();
      } else {
        throw Exception();
      }
    } catch (_) {
      // rollback
      review['comment_count']--;
      review.refresh();
    }
  }

  // ==========================
  // 댓글 삭제
  // ==========================
  Future<void> deleteComment(int commentId) async {
    review['comment_count']--;
    review.refresh();

    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/reviews/comments/$commentId"),
        headers: authHeader,
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        await fetchComments();
      } else {
        throw Exception();
      }
    } catch (_) {
      review['comment_count']++;
      review.refresh();
    }
  }
}
