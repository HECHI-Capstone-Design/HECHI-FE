import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../../my_read/controllers/my_read_controller.dart';
import '../widgets/overlays/comment_overlay.dart';
import '../widgets/overlays/more_menu_overlay.dart';

class BookDetailController extends GetxController {
  final String baseUrl = "https://api.43-202-101-63.sslip.io";
  final box = GetStorage();

  final int bookId = Get.arguments ?? 1;

  final RxBool isLoading = true.obs;
  final RxMap<String, dynamic> book = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> reviews = <Map<String, dynamic>>[].obs;

  final RxMap<String, int> ratingHistogram = <String, int>{}.obs;
  final RxInt maxRatingCount = 1.obs;

  final RxInt userBookId = (-1).obs;
  final RxString readingStatus = "PENDING".obs;
  final RxBool isWishlisted = false.obs;
  final RxBool isCommented = false.obs;

  final RxDouble myRating = 0.0.obs;
  final RxDouble averageRating = 0.0.obs;
  final RxInt totalReviewCount = 0.obs;

  bool get isReadingOrCompleted =>
      ["READING", "COMPLETED"].contains(readingStatus.value);

  int myReviewId = -1;
  final RxString myContent = "".obs;
  final RxBool isSpoiler = false.obs;

  List<Map<String, dynamic>> get bestReviews {
    if (reviews.isEmpty) return [];

    final textReviews = reviews.where((element) {
      final content = (element["content"] ?? "").toString();
      return content.trim().isNotEmpty;
    }).toList();

    textReviews.sort((a, b) => (b["like_count"] ?? 0).compareTo(a["like_count"] ?? 0));

    return textReviews.take(3).toList();
  }

  /*
  @override
  void onInit() {
    super.onInit();
    Future.wait([
      fetchReadingStatus(),
      fetchBookDetail(),
      fetchReviews(),
      fetchRatingSummary(),
      fetchWishlistStatus(),
    ]);
  }
   */

  @override
  void onInit() {
    super.onInit();
    fetchReadingStatus();
    fetchWishlistStatus();
  }

  @override
  void onReady() {
    super.onReady();
    fetchBookDetail();
    fetchReviews();
    fetchRatingSummary();
  }

  // ==========================
  // 책 상세 조회 (Histogram 파싱 추가)
  // ==========================
  Future<void> fetchBookDetail() async {
    try {
      isLoading.value = true;
      final res = await http.get(Uri.parse("$baseUrl/books/$bookId"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        book.value = data;

        if (data["rating_histogram"] != null) {
          Map<String, dynamic> rawHist = data["rating_histogram"];
          ratingHistogram.value =
              rawHist.map((key, value) => MapEntry(key, value as int));

          if (ratingHistogram.isNotEmpty) {
            int max = 0;
            ratingHistogram.forEach((_, v) {
              if (v > max) max = v;
            });
            maxRatingCount.value = max == 0 ? 1 : max;
          }
        }
      } else {
        Get.snackbar("오류", "책 정보를 불러오지 못했습니다.");
      }
    } catch (e) {
      print("❌ Book API Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ==========================
  // 리뷰 목록 조회
  // ==========================
  Future<void> fetchReviews() async {
    try {
      final token = box.read('access_token');
      final headers = {"Content-Type": "application/json"};
      if (token != null) headers["Authorization"] = "Bearer $token";

      final res = await http.get(
        Uri.parse("$baseUrl/reviews/books/$bookId"),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;

        reviews.value = list.map((e) {
          final map = Map<String, dynamic>.from(e);
          map['comment_count'] = map['comment_count'] ?? 0;
          map['like_count'] = map['like_count'] ?? 0;
          return map;
        }).toList();

        final mine =
          reviews.firstWhereOrNull((r) => r['is_my_review'] == true);

        if (mine != null) {
          myReviewId = mine["id"];
          myRating.value = (mine["rating"] as num?)?.toDouble() ?? 0.0;
          myContent.value = mine["content"] ?? "";

          if (mine["content"] != null) {
            isCommented.value = true;
            isSpoiler.value = mine["is_spoiler"];
          } else {
            isCommented.value = false;
            isSpoiler.value = false;
          }
        } else {
          isCommented.value = false;
          myRating.value = 0.0;
          myContent.value = "";
        }
      } else {
        print("❌ Review fetch failed: ${res.statusCode}");
      }
    } catch (e) {
      print("Review error: $e");
    }
  }

  // ==========================
  // 독서 상태 조회
  // ==========================
  Future<void> fetchReadingStatus() async {
    try {
      final token = box.read("access_token");
      if (token == null) return;

      final res = await http.get(
        Uri.parse("$baseUrl/reading-status/summary/$bookId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode != 200) return;

      final body = res.body.trim();
      if (!body.startsWith("{")) {
        readingStatus.value = body.replaceAll('"', '');
        return;
      }

      final decoded = jsonDecode(body);
      userBookId.value = decoded["user_book_id"] ?? -1;

      if (decoded["status"] != null) {
        readingStatus.value = decoded["status"];
      } else {
        readingStatus.value = "PENDING";
      }

      print("🎯 최종 상태(UI 반영): ${readingStatus.value}");
    } catch (e) {
      print("❌ Reading-Status GET Error: $e");
    }
  }

  // ==========================
  // 위시리스트 반영
  // ==========================
  Future<void> fetchWishlistStatus() async {
    final token = box.read("access_token");
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/wishlist/"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("🔍 Wishlist GET Status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        isWishlisted.value = data.any((e) => e["book_id"] == bookId);
        print("⭐ Wishlist status initialized: ${isWishlisted.value}");
      }
    } catch (e) {
      print("❌ Wishlist Status Error: $e");
    }
  }

  // ==========================
  // 독서 상태 업데이트
  // ==========================
  Future<void> updateReadingStatus(String status) async {
    final token = box.read("access_token");
    if (token == null) {
      Get.snackbar("알림", "로그인이 필요합니다.");
      return;
    }

    try {
      final Map<String, dynamic> bodyData = {"status": status};

      if (userBookId.value != -1) {
        bodyData["user_book_id"] = userBookId.value;
        print("🚀 상태 변경 요청 (기존): $status / userBookId=${userBookId.value}");
      } else {
        bodyData["book_id"] = bookId;
        print("🚀 상태 변경 요청 (신규): $status / bookId=$bookId");
      }

      final res = await http.post(
        Uri.parse("$baseUrl/reading-status/update"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(bodyData),
      );

      print("📡 응답 상태 코드: ${res.statusCode}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        Get.snackbar("완료", "상태가 변경되었습니다.");

        await fetchReadingStatus();

      } else {
        print("❌ 실패 본문: ${res.body}");
        Get.snackbar("오류", "상태 변경 실패: ${res.statusCode}");
      }

    } catch (e) {
      print("❌ Status Update Error: $e");
    }
  }

  // ==========================
  // 읽고싶어요
  // ==========================
  Future<void> onWantToRead() async {
    final token = box.read("access_token");
    if (token == null) {
      Get.snackbar("알림", "로그인이 필요합니다.");
      return;
    }

    final bool before = isWishlisted.value;

    isWishlisted.value = !before;

    try {
      http.Response res;

      if (before) {
        res = await http.delete(
          Uri.parse("$baseUrl/wishlist/$bookId"),
          headers: {"Authorization": "Bearer $token"},
        );
        print("🟥 DELETE status: ${res.statusCode}");
      } else {
        if (readingStatus.value == "ARCHIVED") {
          print("🚀 '읽고싶어요' 클릭 -> '관심없음' 상태 자동 해제");
          await updateReadingStatus("PENDING");
        }

        res = await http.post(
          Uri.parse("$baseUrl/wishlist/?book_id=$bookId"),
          headers: {"Authorization": "Bearer $token"},
        );
        print("🟩 POST status: ${res.statusCode}");
      }

      if (res.statusCode != 200 &&
          res.statusCode != 201 &&
          res.statusCode != 204) {
        isWishlisted.value = before;
        print("🔁 ROLLBACK UI due to status: ${res.statusCode}");
        Get.snackbar("오류", "요청 처리에 실패했습니다. (${res.statusCode})");
      }
      print("🎯 FINAL UI state: ${isWishlisted.value}");

    } catch (e) {
      isWishlisted.value = before;
      print("❌ Wishlist Error: $e");
    }
  }

  // ==========================
  // 코멘트 등록 함수
  // ==========================
  Future<void> submitReview(String content, bool isSpoiler) async {
    final token = box.read("access_token");
    if (token == null) return;

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    final body = jsonEncode({
      "book_id": bookId,
      "rating": (myRating.value == 0.0) ? null : myRating.value,
      "content": content,
      "is_spoiler": isSpoiler,
    });

    print("🚀 코멘트 등록 요청: $body"); // 디버깅용 로그

    final res = await http.post(
      Uri.parse("$baseUrl/reviews/upsert"),
      headers: headers,
      body: body,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      myReviewId = data["id"];
      isCommented.value = true;
      myContent.value = content;
      this.isSpoiler.value = isSpoiler;
      await fetchReviews();

      await Future.delayed(const Duration(milliseconds: 500));
      if (Get.isRegistered<MyReadController>()) {
        await Get.find<MyReadController>().fetchMyReadData();
        print("✅ 나의 독서 통계 갱신 요청 완료");
      }
    }
  }

  // ==========================
  // 리뷰 삭제
  // ==========================
  Future<void> delete() async {
    final token = box.read("access_token");
    final res = await http.delete(
      Uri.parse("$baseUrl/reviews/$myReviewId"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200 || res.statusCode == 204) {
      myRating.value = 0.0;
      isCommented.value = false;
      myReviewId = -1;
      myContent.value = "";
      isSpoiler.value = false;
      await fetchBookDetail();
      await fetchReviews();
      print("🗑️ 리뷰 삭제 완료");

      await Future.delayed(const Duration(milliseconds: 500));
      if (Get.isRegistered<MyReadController>()) {
        await Get.find<MyReadController>().fetchMyReadData();
        print("✅ 나의 독서 통계 갱신 요청 완료");
      }
    }
  }

  // ==========================
  // 코멘트 버튼 클릭 (Overlay 오픈)
  // ==========================
  Future<void> onWriteReview() async {
    if (isCommented.value && myReviewId != -1) {
      final result = await Get.toNamed("/review_detail", arguments: myReviewId);

      print("📨 onWriteReview result: $result");

      if (result != null) {
        syncReviewChange(result);
      }
    }
    else {
      Get.bottomSheet(
        CommentOverlay(onSubmit: submitReview),
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        ),
      );
    }
  }

  // ==========================
  // 별점 저장 (코멘트 없이 가능)
  // ==========================
  Future<void> submitRating(double rating) async {
    final token = box.read("access_token");
    if (token == null) return;

    final bool hasContent = myContent.isNotEmpty;

    if (rating == 0.0 && !hasContent && myReviewId != -1) {
      await delete();
      return;
    }

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    final body = jsonEncode({
      "book_id": bookId,
      "rating": (rating == 0.0) ? null : rating,
      "content": hasContent ? myContent.value : null,
      "is_spoiler": isSpoiler.value,
    });

    print("🚀 별점 등록 요청: $body"); // 디버깅용 로그

    final res = await http.post(
      Uri.parse("$baseUrl/reviews/upsert"),
      headers: headers,
      body: body,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      myRating.value = (data["rating"] as num?)?.toDouble() ?? 0.0;

      final index = reviews.indexWhere((r) => r["id"] == myReviewId);
      if (index != -1) {
        reviews[index]["rating"] = myRating.value;
      } else {
        reviews.insert(0, Map<String, dynamic>.from(data));
      }

      reviews.refresh();

      await fetchBookDetail();

      await Future.delayed(const Duration(milliseconds: 500));
      if (Get.isRegistered<MyReadController>()) {
        await Get.find<MyReadController>().fetchMyReadData();
        print("✅ 나의 독서 통계 갱신 요청 완료");
      }
    }
  }

  // ==========================
  // 더보기 메뉴
  // ==========================
  void openMoreMenu() {
    Get.bottomSheet(
      MoreMenuOverlay(),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
    );
  }

  // ==========================
  // 더보기 메뉴 오버레이 선택 (Overlay에서 호출)
  // ==========================
  void selectedMenu() async {
    Get.back(); // 오버레이 닫기
    // 다른 팝업 연결
  }

  // ==========================
  // 관심없어요 (모든 상태 해제)
  // ==========================
  Future<void> onNotInterested() async {
    if (isWishlisted.value) {
      await onWantToRead();
    }

    await updateReadingStatus("ARCHIVED");
  }

  // ==========================
  // 평점 요약 정보 조회 (GET /reviews/books/{id}/summary)
  // ==========================
  Future<void> fetchRatingSummary() async {
    try {
      final res =
      await http.get(Uri.parse("$baseUrl/reviews/books/$bookId/summary"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        averageRating.value = (data["average_rating"] as num).toDouble();
        totalReviewCount.value = (data["review_count"] as num).toInt();
      }
    } catch (e) {
      print("❌ Rating Summary Error: $e");
    }
  }

  // ==========================
  // 좋아요 토글 (베스트 리뷰용)
  // ==========================
  Future<void> toggleLike(int reviewId) async {
    final token = box.read("access_token");
    if (token == null) {
      Get.snackbar("알림", "로그인이 필요합니다.");
      return;
    }

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/reviews/$reviewId/like"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        print("✅ 베스트 리뷰 좋아요 성공 (ID: $reviewId)");

        final index = reviews.indexWhere((element) => element['id'] == reviewId);
        if (index != -1) {
          final updated = Map<String, dynamic>.from(reviews[index]);
          bool currentLike = updated['is_liked'] ?? false;
          updated['is_liked'] = !currentLike;
          updated['like_count'] = (updated['like_count'] ?? 0) + (!currentLike ? 1 : -1);
          reviews[index] = updated;
          reviews.refresh();
        }
      } else {
        print("❌ 좋아요 실패: ${res.statusCode}");
        Get.snackbar("오류", "요청 처리에 실패했습니다.");
      }
    } catch (e) {
      print("❌ 좋아요 에러: $e");
    }
  }

  // ==========================
  // 리뷰 동기화
  // ==========================
  void syncReviewChange(Map<String, dynamic> result) {
    final int reviewId = result['review_id'];
    final String status = result['status'] ?? 'updated';

    if (status == 'deleted') {
      reviews.removeWhere((r) => r['id'] == reviewId);

      if (myReviewId == reviewId) {
        final bool keepRating = result['keep_rating'] ?? false;

        myContent.value = "";
        isCommented.value = false;
        isSpoiler.value = false;

        if (!keepRating){
          myReviewId = -1;
          myRating.value = 0.0;
        }
      }
      reviews.refresh();
      return;
    }

    final index = reviews.indexWhere((r) => r['id'] == reviewId);

    if (index != -1) {
      final updated = Map<String, dynamic>.from(reviews[index]);

      if (result.containsKey('is_liked')) updated['is_liked'] = result['is_liked'];       // ← updated에 넣기
      if (result.containsKey('like_count')) updated['like_count'] = result['like_count']; // ← updated에 넣기

      if (result.containsKey('content')) {
        updated['content'] = result['content'];
        if (myReviewId == reviewId) {
          myContent.value = result['content'];
          isCommented.value = result['content'].toString().trim().isNotEmpty;
        }
      }
      if (result.containsKey('is_spoiler')) {
        updated['is_spoiler'] = result['is_spoiler'];
        if (myReviewId == reviewId) isSpoiler.value = result['is_spoiler'];
      }
      if (result.containsKey('comment_count')) {
        updated['comment_count'] = result['comment_count'];
      }

      reviews[index] = updated;
      reviews.refresh();
    }
  }
}