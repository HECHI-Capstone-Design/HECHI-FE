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
          Get.back();
          Get.snackbar(
            'AI 요약 생성 중',
            '요약을 생성하고 있습니다. 완료되면 알림을 드릴게요.',
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
          );
          if (Get.isRegistered<BookNoteController>()) {
            Get.find<BookNoteController>().pollUntilReadyInBackground();
          }
        }
      }
    } catch (e) {
      print("❌ Load Summary Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// ===================== 폴링 =====================
  Future<bool> _pollUntilReadyOrTimeout({int maxRetries = 3}) async {
    isGenerating.value = true;
    try {
      for (int i = 0; i < maxRetries; i++) {
        await Future.delayed(const Duration(seconds: 5));
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
        Get.back();
        Get.snackbar(
          'AI 요약 생성 중',
          '요약을 생성하고 있습니다. 완료되면 알림을 드릴게요.',
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
        if (Get.isRegistered<BookNoteController>()) {
          Get.find<BookNoteController>().pollUntilReadyInBackground();
        }
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