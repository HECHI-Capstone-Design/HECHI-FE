import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'book_note_controller.dart';

class AiSummaryController extends GetxController {
  final ApiService api = ApiService();

  final isLoading = false.obs;
  final isGenerating = false.obs;
  final summaryText = ''.obs;
  final keyPoints = <String>[].obs;
  final notesDigest = <String>[].obs;
  final status = ''.obs;

  late int bookId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments ?? {};
    bookId = args['bookId'] ?? 0;
    loadSummary();
  }

  /// ===================== 요약 로드  =====================
  Future<void> loadSummary() async {
    isLoading.value = true;
    try {
      final data = await api.get("/books/$bookId/reading-summary");
      final currentStatus = data['status'] ?? '';

      if (currentStatus == 'READY') {
        _applyContent(data);
      } else {
        await api.post("/books/$bookId/reading-summary/generate", {});
        final isReady = await _pollUntilReadyOrTimeout();
        if (!isReady) {
          _showGeneratingDialog();
        }
      }
    } catch (e) {
      print("❌ Load Summary Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// ===================== 폴링 =====================
  Future<bool> _pollUntilReadyOrTimeout({int maxRetries = 1}) async {
    isGenerating.value = true;
    try {
      for (int i = 0; i < maxRetries; i++) {
        await Future.delayed(const Duration(seconds: 3));
        try {
          final data = await api.get("/books/$bookId/reading-summary");
          final currentStatus = data['status'] ?? '';
          if (currentStatus == 'READY') {
            _applyContent(data);
            return true;
          }
        } catch (e) {
          print("❌ Poll Error: $e");
        }
      }
      return false;
    } finally {
      isGenerating.value = false;
    }
  }

  /// ===================== 요약 내용 적용 =====================
  void _applyContent(Map<String, dynamic> data) {
    final content = data['summaryContent'];
    if (content == null) return;

    final keyPointsRaw = content['keyPoints'];
    final notesDigestRaw = content['notesDigest'];

    summaryText.value = content['summary'] ?? '';
    keyPoints.value = keyPointsRaw is List
        ? keyPointsRaw.map((e) => e.toString()).toList()
        : <String>[];
    notesDigest.value = notesDigestRaw is List
        ? notesDigestRaw.map((e) => e.toString()).toList()
        : <String>[];

    status.value = 'READY';

    if (Get.isRegistered<BookNoteController>()) {
      Get.find<BookNoteController>().hasSummary.value = true;
    }
  }

  /// ===================== 생성 중 다이얼로그 =====================
  void _showGeneratingDialog() {
    if (Get.isDialogOpen ?? false) Get.back();

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF4DB56C),
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI 요약 생성 중',
              style: TextStyle(
                color: Color(0xFF3F3F3F),
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '요약을 생성하고 있습니다.\n완료되면 알림을 드릴게요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF717171),
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Get.back();
                  Get.back();
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF4DB56C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    if (Get.isRegistered<BookNoteController>()) {
      Get.find<BookNoteController>().pollUntilReadyInBackground();
    }
  }

  /// ===================== 다시 생성 =====================
  Future<void> fetchSummary() async {
    summaryText.value = '';
    keyPoints.value = [];
    notesDigest.value = [];
    status.value = '';

    try {
      await api.post("/books/$bookId/reading-summary/generate", {});
      final isReady = await _pollUntilReadyOrTimeout();
      if (!isReady) {
        _showGeneratingDialog();
      }
    } catch (e) {
      print("❌ Fetch Summary Error: $e");
    }
  }

  /// ===================== 삭제 =====================
  Future<void> deleteSummary() async {
    try {
      await api.delete("/books/$bookId/reading-summary");
      summaryText.value = '';
      status.value = '';
      if (Get.isRegistered<BookNoteController>()) {
        Get.find<BookNoteController>().hasSummary.value = false;
      }
      Get.back();
    } catch (e) {
      print("❌ Delete Summary Error: $e");
    }
  }
}