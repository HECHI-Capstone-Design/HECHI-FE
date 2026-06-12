import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../controllers/ai_summary_controller.dart';
import '../pages/ai_summary_page.dart';

class BookNoteController extends GetxController with GetSingleTickerProviderStateMixin {
  final ApiService api = ApiService();
  late TabController tabController;

  late int bookId;
  late int tabIndex;
  late bool openHighlightCreation;
  late bool autoStartHighlightOcr;
  late String? autoStartHighlightCaptureMode;
  late bool closePageAfterHighlightCreate;
  late bool openHighlightCaptureReview;
  int? initialHighlightPage;

  String? preselectedGroupId;
  String? preselectedBoardId;

  Function(String itemType, Map<String, dynamic> itemData)? onItemSelected;

  /// ===================== Loading States =====================
  RxBool isLoadingBookInfo = true.obs;
  RxBool isLoadingBookmarks = true.obs;
  RxBool isLoadingHighlights = true.obs;
  RxBool isLoadingNotes = true.obs;

  /// ===================== Data Lists =====================
  RxMap<String, dynamic> bookInfo = <String, dynamic>{}.obs;
  RxList<Map<String, dynamic>> bookmarks = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> highlights = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> notes = <Map<String, dynamic>>[].obs;

  /// ===================== Sort States =====================
  // Bookmark
  RxString sortTypeBookmark = "date".obs; // date | page
  RxString sortTextBookmark = "최신 순".obs;

  // Highlight
  RxString sortTypeHighlight = "date".obs; // date | page
  RxString sortTextHighlight = "최신 순".obs;

  // Memo
  RxString sortTypeMemo = "date".obs; // date | oldest
  RxString sortTextMemo = "최신 순".obs;

  /// ===================== Ai Summary =====================
  RxBool hasSummary = false.obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments ?? {};
    bookId = args['bookId'] ?? 0;
    tabIndex = args['tabIndex'] ?? 0;
    openHighlightCreation = args['openHighlightCreation'] == true;
    autoStartHighlightOcr = args['autoStartHighlightOcr'] == true;
    autoStartHighlightCaptureMode =
        args['autoStartHighlightCaptureMode']?.toString();
    closePageAfterHighlightCreate = args['closePageAfterHighlightCreate'] == true;
    openHighlightCaptureReview = args['openHighlightCaptureReview'] == true;
    initialHighlightPage = args['initialHighlightPage'] as int?;

    preselectedGroupId = args['preselectedGroupId'];
    preselectedBoardId = args['preselectedBoardId'];

    tabController = TabController(length: 3, vsync: this, initialIndex: tabIndex);

    fetchBookInfo();
    fetchAll();
    fetchAiSummary();
  }

  Map<String, dynamic>? consumeHighlightCreationRequest() {
    if (!openHighlightCreation) return null;
    openHighlightCreation = false;
    return {
      'page': initialHighlightPage,
      'autoStartOcr': autoStartHighlightOcr,
      'autoStartCaptureMode': autoStartHighlightCaptureMode,
      'closeParentPageOnSave': closePageAfterHighlightCreate,
    };
  }

  bool consumeHighlightCaptureReviewRequest() {
    if (!openHighlightCaptureReview) return false;
    openHighlightCaptureReview = false;
    return true;
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  /// ===================== FETCH ALL =====================
  void fetchAll() {
    fetchBookmarks();
    fetchHighlights();
    fetchNotes();
  }

  /// ===================== FETCH AI SUMMARY =====================
  Future<void> fetchAiSummary() async {
    try {
      final data = await api.get("/books/$bookId/reading-summary");
      final currentStatus = data['status'] ?? '';
      hasSummary.value = currentStatus == 'READY';
    } catch (e) {
      hasSummary.value = false;
      print("❌ Fetch AI Summary Error: $e");
    }
  }

  /// ===================== BOOK INFO =====================
  Future<void> fetchBookInfo() async {
    isLoadingBookInfo.value = true;
    try {
      final data = await api.get("/books/$bookId");
      bookInfo.value = Map<String, dynamic>.from(data);
    } catch (e) {
      print("❌ Fetch Book Info Error: $e");
    }
    isLoadingBookInfo.value = false;
  }

  /// =====================================================
  /// 📌 BOOKMARK API
  /// =====================================================

  Future<void> fetchBookmarks() async {
    isLoadingBookmarks.value = true;
    try {
      final data = await api.get("/bookmarks/books/$bookId");
      bookmarks.value = List<Map<String, dynamic>>.from(data);
      sortBookmarks();
    } catch (e) {
      print("❌ Fetch Bookmarks Error: $e");
    }
    isLoadingBookmarks.value = false;
  }

  Future<void> createBookmark(int page, String memo) async {
    final isDuplicate = bookmarks.any((element) => element['page'] == page);

    if (isDuplicate){
      return;
    }

    try {
      await api.post(
        "/bookmarks/",
        {
          "book_id": bookId,
          "page": page,
          "memo": memo.isEmpty ? null : memo,
        },
      );

      fetchBookmarks();
      Get.back();
    } catch (e) {
      print("❌ Create Bookmark Error: $e");
    }
  }

  Future<void> updateBookmark(int id, int page, String memo) async {
    try {
      await api.put(
        "/bookmarks/$id",
        {
          "page": page,
          "memo": memo,
        },
      );

      fetchBookmarks();
      Get.back();
    } catch (e) {
      print("❌ Update Bookmark Error: $e");
    }
  }

  Future<void> deleteBookmark(int id) async {
    try {
      await api.delete("/bookmarks/$id");
      fetchBookmarks();
    } catch (e) {
      print("❌ Delete Bookmark Error: $e");
    }
  }

  /// ===================== BOOKMARK SORT =====================
  void sortBookmarks() {
    if (sortTypeBookmark.value == "date") {
      bookmarks.sort((a, b) => b["id"].compareTo(a["id"]));
    } else {
      bookmarks.sort((a, b) => a["page"].compareTo(b["page"]));
    }
    bookmarks.refresh();
  }

  /// =====================================================
  /// 📌 HIGHLIGHT API
  /// =====================================================

  Future<void> fetchHighlights() async {
    isLoadingHighlights.value = true;
    try {
      final data = await api.get("/highlights/books/$bookId");
      highlights.value = List<Map<String, dynamic>>.from(data);
      sortHighlights();
    } catch (e) {
      print("❌ Fetch Highlights Error: $e");
    }
    isLoadingHighlights.value = false;
  }

  Future<bool> createHighlight(int page, String sentence, String memo, bool isPublic) async {
    try {
      await api.post(
        "/highlights/",
        {
          "book_id": bookId,
          "page": page,
          "sentence": sentence,
          "memo": memo.isEmpty ? null : memo,
          "is_public": isPublic,
        },
      );

      fetchHighlights();
      Get.back();
      return true;
    } catch (e) {
      print("❌ Create Highlight Error: $e");
      Get.snackbar("오류", "하이라이트 저장에 실패했습니다.");
      return false;
    }
  }

  Future<void> updateHighlight(int id, int page, String sentence, String memo, bool isPublic) async {
    try {
      await api.put(
        "/highlights/$id",
        {
          "page": page,
          "sentence": sentence,
          "memo": memo,
          "is_public": isPublic,
        },
      );

      fetchHighlights();
      Get.back();
    } catch (e) {
      print("❌ Update Highlight Error: $e");
    }
  }

  Future<void> deleteHighlight(int id) async {
    try {
      await api.delete("/highlights/$id");
      fetchHighlights();
    } catch (e) {
      print("❌ Delete Highlight Error: $e");
    }
  }

  /// ===================== HIGHLIGHT SORT =====================
  void sortHighlights() {
    if (sortTypeHighlight.value == "date") {
      highlights.sort((a, b) => b["id"].compareTo(a["id"]));
    } else {
      highlights.sort((a, b) => a["page"].compareTo(b["page"]));
    }
    highlights.refresh();
  }

  /// =====================================================
  /// 📌 NOTES API (MEMO)
  /// =====================================================

  Future<void> fetchNotes() async {
    isLoadingNotes.value = true;
    try {
      final data = await api.get("/notes/books/$bookId");
      notes.value = List<Map<String, dynamic>>.from(data);
      sortMemos();
    } catch (e) {
      print("❌ Fetch Notes Error: $e");
    }
    isLoadingNotes.value = false;
  }

  Future<void> createMemo(String content) async {
    try {
      await api.post(
        "/notes/",
        {
          "book_id": bookId,
          "content": content,
        },
      );
      fetchNotes();
      Get.back();
    } catch (e) {
      print("❌ Create Memo Error: $e");
    }
  }

  Future<void> updateMemo(int id, String content) async {
    try {
      await api.put(
        "/notes/$id",
        {
          "content": content,
        },
      );
      fetchNotes();
      Get.back();
    } catch (e) {
      print("❌ Update Memo Error: $e");
    }
  }

  Future<void> deleteMemo(int id) async {
    try {
      await api.delete("/notes/$id");
      fetchNotes();
    } catch (e) {
      print("❌ Delete Memo Error: $e");
    }
  }

  /// ===================== MEMO SORT =====================
  void sortMemos() {
    if (sortTypeMemo.value == "date") {
      notes.sort((a, b) =>
          DateTime.parse(b["created_date"])
              .compareTo(DateTime.parse(a["created_date"])));
      sortTextMemo.value = "최신 순";
    } else {
      notes.sort((a, b) =>
          DateTime.parse(a["created_date"])
              .compareTo(DateTime.parse(b["created_date"])));
      sortTextMemo.value = "오래된 순";
    }
    notes.refresh();
  }

  /// =====================================================
  /// 📌 AI SUMMARY API
  /// =====================================================
  bool hasAiSummaryContent() {
    final isStillLoading = isLoadingBookmarks.value ||
        isLoadingHighlights.value ||
        isLoadingNotes.value;
    if (isStillLoading) return true;

    return bookmarks.isNotEmpty || highlights.isNotEmpty || notes.isNotEmpty;
  }

  Future<void> pollUntilReadyInBackground({int maxRetries = 60}) async {
    for (int i = 0; i < maxRetries; i++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final data = await api.get("/books/$bookId/reading-summary");
        final currentStatus = data['status'] ?? '';
        if (currentStatus == 'READY') {
          hasSummary.value = true;
          Get.snackbar(
            'AI 메모 요약 완료',
            '요약이 생성되었습니다. 확인해보세요!',
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
            onTap: (_) {
              Get.to(
                    () => const AiSummaryPage(),
                arguments: {'bookId': bookId},
                binding: BindingsBuilder(() {
                  Get.delete<AiSummaryController>(force: true);
                  Get.lazyPut(() => AiSummaryController());
                }),
              );
            },
          );
          return;
        }
      } catch (e) {
        print("❌ Background Poll Error: $e");
      }
    }
    print("❌ 백그라운드 폴링 타임아웃");
  }
}
