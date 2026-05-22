import 'package:get/get.dart';
import 'book_note_controller.dart';

class AiSummaryController extends GetxController {
  final isLoading = false.obs;
  final summaryText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSummary();
  }

  Future<void> fetchSummary() async {
    isLoading.value = true;
    try {
      await Future.delayed(const Duration(seconds: 1));
      summaryText.value =
      '이 책에서 총 3개의 북마크, 5개의 하이라이트, 2개의 메모를 남기셨습니다.\n\n'
          '📌 주요 내용\n'
          '저자는 습관 형성의 핵심 원리로 "작은 변화의 누적"을 강조합니다. '
          '매일 1%씩 나아지는 것이 1년 후 37배의 성장으로 이어진다는 복리 효과를 설명하며, '
          '결과보다 시스템에 집중할 것을 권장합니다.\n\n'
          '✏️ 내가 남긴 메모\n'
          '"목표는 방향을 알려주지만, 시스템이 실제로 나를 앞으로 나아가게 한다."\n'
          '"환경 설계가 의지력보다 강하다 — 좋은 습관이 쉬운 환경을 만들어라."';

      if (Get.isRegistered<BookNoteController>()) {
        Get.find<BookNoteController>().hasSummary.value = true;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteSummary() async {
    try {
      // TODO: 삭제 API 호출
      summaryText.value = '';
      if (Get.isRegistered<BookNoteController>()) {
        Get.find<BookNoteController>().hasSummary.value = false;
      }
    } catch (e) {
      print("❌ Delete Summary Error: $e");
    }
  }
}