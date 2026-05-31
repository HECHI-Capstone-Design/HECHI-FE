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
        await requestGenerate();
      }
    } catch (e) {
      print("❌ Load Summary Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// ===================== 수동 생성 요청 (POST) =====================
  Future<void> requestGenerate() async {
    isGenerating.value = true;
    try {
      await api.post("/books/$bookId/reading-summary/generate", {});
      await _pollUntilReady();
    } catch (e) {
      print("❌ Generate Summary Error: $e");
    } finally {
      isGenerating.value = false;
    }
  }

  /// ===================== 폴링 =====================
  Future<void> _pollUntilReady({int maxRetries = 20}) async {
    for (int i = 0; i < maxRetries; i++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final data = await api.get("/books/$bookId/reading-summary");
        final currentStatus = data['status'] ?? '';
        print("📊 폴링 $i: status = $currentStatus");
        if (currentStatus == 'READY') {
          _applyContent(data);
          return;
        }
      } catch (e) {
        print("❌ Poll Error: $e");
      }
    }
    print("❌ 폴링 타임아웃");
    _showTimeoutDialog();
  }

  void _showTimeoutDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: 200,
          height: 107,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const Expanded(
                child: Center(
                  child: Text(
                    '요약 생성이 지연되고 있습니다.\n잠시 후 다시 시도해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF3F3F3F),
                      fontSize: 14,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                      height: 1.75,
                    ),
                  ),
                ),
              ),
              Container(height: 1, color: const Color(0xFFF3F3F3)),
              SizedBox(
                height: 36,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    onTap: () => Get.back(),
                    child: const Center(
                      child: Text(
                        '닫기',
                        style: TextStyle(
                          color: Color(0xFF4DB56C),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    status.value = '';
    await requestGenerate();
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