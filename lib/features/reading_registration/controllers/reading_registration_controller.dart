import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/app/controllers/app_controller.dart';
import 'package:mobile_ocr_flutter/mobile_ocr_flutter.dart';
import '../../book_note/services/highlight_capture_draft_service.dart';
import '../../book_note/widgets/overlays/highlight_capture_mode_sheet.dart';
import 'hardware_camera_controller.dart';
import '../data/models/reading_library_model.dart';
import '../data/models/reading_registration_session_model.dart';
import '../data/repository/reading_registration_repository.dart';
import '../data/models/reading_book_summary_model.dart';

class ReadingRegistrationController extends GetxController {
  final ReadingRegistrationRepository repository;
  ReadingRegistrationController({required this.repository});

  // State
  var libraryReadingItems = <ReadingLibraryItem>[].obs;
  var isLoading = false.obs;

  // 현재 위젯에 표시되는 책
  var currentActiveBook = Rxn<ReadingLibraryItem>();

  // Active Session (타이머 관련)
  var currentSession = Rxn<ReadingRegistrationSession>();
  var elapsedSeconds = 0.obs;
  var isSessionStarting = false.obs;
  var isSessionEnding = false.obs;

  DateTime? _sessionStartTime;
  Timer? _timer;
  DateTime? _ignoreHardwareStartUntil;
  DateTime? _ignoreHardwareEndUntil;
  bool _isPendingHighlightPromptVisible = false;
  String? _lastPendingHighlightPromptKey;

  @override
  void onInit() {
    super.onInit();
    refreshData();

    try {
      if (Get.isRegistered<AppController>()) {
        final appController = Get.find<AppController>();
        ever(appController.currentIndex, (index) {
          if (index == 2) {
            refreshData(showLoading: false);
          }
        });
      }
    } catch (e) {
      print("AppController 탭 감지 실패: $e");
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> refreshData({bool showLoading = true}) async {
    try {
      if (showLoading && libraryReadingItems.isEmpty) isLoading(true);

      final items = await repository.getLibraryReadingItems();
      libraryReadingItems.assignAll(items);

      if (currentActiveBook.value != null) {
        final updatedBook = items.firstWhereOrNull(
          (item) => item.book.id == currentActiveBook.value!.book.id,
        );
        // 독서 중이 아닐 때만 업데이트 (독서 중엔 하드웨어 실시간 데이터가 우선)
        if (currentSession.value == null) {
          currentActiveBook.value =
              updatedBook ?? (items.isNotEmpty ? items.first : null);
        }
      } else {
        currentActiveBook.value = items.isNotEmpty ? items.first : null;
      }
      if (currentActiveBook.value != null) {
        await loadBookDetail(currentActiveBook.value!.book.id);
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      if (showLoading) isLoading(false);
    }
  }

  void _applyReadingItem(ReadingLibraryItem updatedItem) {
    currentActiveBook.value = updatedItem;

    final index = libraryReadingItems.indexWhere(
      (item) => item.book.id == updatedItem.book.id,
    );

    if (index != -1) {
      libraryReadingItems[index] = updatedItem;
      libraryReadingItems.refresh();
    }
  }

  ReadingLibraryItem? getBookItem(int bookId) {
    try {
      return libraryReadingItems.firstWhere((item) => item.book.id == bookId);
    } catch (e) {
      return null;
    }
  }

  ReadingLibraryItem? getBookInfo(int bookId) => getBookItem(bookId);

  // [수정 1] 도서 변경 다이얼로그 디자인 적용
  void onBookTap(int bookId) async {
    final newItem = getBookItem(bookId);
    if (newItem == null) return;

    if (currentSession.value != null) {
      Get.snackbar(
        "알림",
        "현재 진행 중인 독서를 종료한 후 변경해주세요.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (currentActiveBook.value == null ||
        currentActiveBook.value!.book.id != bookId) {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '도서 변경',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F3F3F),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '\'${newItem.book.title}\'(으)로\n변경하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Get.back(),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            '취소',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF888888), // 취소는 회색 처리
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          Get.back();
                          currentActiveBook.value = newItem;
                          await loadBookDetail(bookId);
                        },
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            '변경',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4CAF50), // 강조색
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      showStartDialog(newItem);
    }
  }

  Future<void> loadBookDetail(int bookId) async {
    try {
      final summary = await repository.getBookSummary(bookId);

      if (summary != null && currentActiveBook.value?.book.id == bookId) {
        final currentItem = currentActiveBook.value!;

        _applyReadingItem(
          ReadingLibraryItem(
            book: currentItem.book,
            status: currentItem.status,
            currentPage: summary.maxEndPage,
            progressPercent: summary.progressPercent,
            myRating: currentItem.myRating,
            totalSessionSeconds: summary.totalSessionSeconds,
          ),
        );

        print("책 상세정보 갱신 완료: 총 ${summary.totalSessionSeconds}초 읽음");
      }
    } catch (e) {
      print("책 상세정보 로드 실패: $e");
    }
  }

  void showStartDialog(ReadingLibraryItem item) {
    final startPage = item.currentPage == 0 ? 1 : item.currentPage;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '독서 시작',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3F3F3F),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${item.book.title}\n독서를 시작하시겠습니까?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        if (Get.isDialogOpen == true) {
                          Get.back();
                          await Future<void>.delayed(
                            const Duration(milliseconds: 80),
                          );
                        }
                        await startReadingSession(item.book.id, startPage);
                      },
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          '시작',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> startReadingSession(int bookId, int? startPage) async {
    if (isSessionStarting.value || isSessionEnding.value) {
      print("ℹ️ [독서] 세션 전환 중이라 시작 요청을 무시합니다.");
      return;
    }

    isSessionStarting.value = true;

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      _sessionStartTime = DateTime.now();

      final session = await repository.startSession(bookId, startPage);

      currentSession.value = session;
      elapsedSeconds.value = 0;
      _startTimer();
      _ignoreHardwareEndUntil = DateTime.now().add(
        const Duration(milliseconds: 1200),
      );

      if (Get.isRegistered<HardwareCameraController>()) {
        try {
          final cameraController = Get.find<HardwareCameraController>();
          await cameraController.startCaptureSession();
          final activeBook = currentActiveBook.value;
          if (activeBook != null) {
            await cameraController.syncCaptureContext(
              bookId: activeBook.book.id,
              page: activeBook.currentPage > 0 ? activeBook.currentPage : 1,
            );
          }
        } catch (e) {
          print("⚠️ [하이라이트 카메라] 업로드 서버 시작 실패: $e");
        }
      }
    } catch (e) {
      print("Error: $e");
      if (Get.isDialogOpen == true) Get.back();
      await Future.delayed(const Duration(milliseconds: 100));
      Get.snackbar("오류", "독서를 시작할 수 없습니다.");
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      isSessionStarting.value = false;
    }
  }

  void showStopDialog() {
    final currentSimulatedPage = currentActiveBook.value?.currentPage ?? 0;
    final pageCtrl = TextEditingController(
      text: currentSimulatedPage.toString(),
    );

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '독서 종료',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3F3F3F),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // [수정된 정렬 영역]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center, // Row 수직 중앙 정렬
                children: [
                  // 라벨 텍스트
                  const Padding(
                    padding: EdgeInsets.only(
                      top: 3,
                    ), // [중요] 박스와 시각적 높이를 맞추기 위한 미세 조정
                    child: Text(
                      "마지막 페이지",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F3F3F),
                        // height: 1.0 제거 -> 폰트 기본 높이 사용
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 입력 박스
                  SizedBox(
                    width: 90,
                    // height를 지정하지 않고 contentPadding으로 높이 조절
                    child: TextField(
                      controller: pageCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      cursorColor: const Color(0xFF4CAF50),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        // [중요] 상하 패딩으로 높이를 결정하여 텍스트가 정중앙에 오게 함
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        hintText: '0',
                        hintStyle: const TextStyle(color: Color(0xFFDDDDDD)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '읽은 페이지를 저장하시겠습니까?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        final endPage = int.tryParse(pageCtrl.text);
                        if (endPage != null && endPage > 0) {
                          Get.back();
                          endReading(endPage);
                        } else {
                          Get.snackbar(
                            "확인",
                            "올바른 페이지 번호를 입력해주세요.",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.black87,
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(20),
                          );
                        }
                      },
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> endReading(int endPage) async {
    if (currentSession.value == null) return;
    if (isSessionEnding.value || isSessionStarting.value) {
      print("ℹ️ [독서] 세션 전환 중이라 종료 요청을 무시합니다.");
      return;
    }

    isSessionEnding.value = true;

    final int targetBookId = currentSession.value!.bookId;
    final int sessionId = currentSession.value!.id;
    final int finalSeconds = elapsedSeconds.value;
    final int reviewPage = endPage > 0
        ? endPage
        : (currentActiveBook.value?.currentPage ?? 1);
    bool didSave = false;

    _timer?.cancel();
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final sessionResult = await repository.endSession(
        sessionId,
        endPage,
        finalSeconds,
      );
      print(
        "=== 세션 종료 성공: ${sessionResult.totalSeconds}초, ${sessionResult.endPage}p ===",
      );
      didSave = true;

      try {
        final summary = await repository.getBookSummary(targetBookId);

        if (summary != null && currentActiveBook.value != null) {
          final updatedItem = ReadingLibraryItem(
            book: currentActiveBook.value!.book,
            status: currentActiveBook.value!.status,
            currentPage: summary.maxEndPage,
            progressPercent: summary.progressPercent,
            myRating: currentActiveBook.value!.myRating,
            totalSessionSeconds: summary.totalSessionSeconds,
          );

          _applyReadingItem(updatedItem);
          print("=== 로컬 데이터 동기화 완료: ${summary.progressPercent}% ===");
        }
      } catch (e) {
        print("⚠️ 요약 정보 로드/파싱 실패 (UI 자동 갱신 안됨): $e");
      }
    } catch (e) {
      Get.snackbar("오류", "저장에 실패했습니다: ${e.toString()}");
      print("세션 종료 요청 실패: $e");
    } finally {
      if (Get.isDialogOpen ?? false) Get.back();
      isSessionEnding.value = false;
    }

    if (!didSave) return;

    if (Get.isRegistered<HardwareCameraController>()) {
      final cameraController = Get.find<HardwareCameraController>();
      await cameraController.syncPendingCaptureForReview(
        bookId: targetBookId,
        page: reviewPage,
      );
      await cameraController.stopCaptureSession();
    }

    currentSession.value = null;
    elapsedSeconds.value = 0;
    _ignoreHardwareStartUntil = DateTime.now().add(const Duration(seconds: 2));

    Get.snackbar(
      "완료",
      "독서가 기록되었습니다.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(20),
    );

    await _maybePromptPendingHighlightCaptures(
      targetBookId,
      promptKey: '$sessionId:$targetBookId',
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedSeconds.value++;
    });
  }

  void updateRealTimePage(int newPage) {
    if (currentActiveBook.value != null) {
      final currentItem = currentActiveBook.value!;
      final totalPages = currentItem.book.totalPages;
      final newProgress = (totalPages > 0)
          ? ((newPage / totalPages) * 100).toInt()
          : 0;

      _applyReadingItem(
        ReadingLibraryItem(
          book: currentItem.book,
          status: currentItem.status,
          currentPage: newPage,
          progressPercent: newProgress,
          myRating: currentItem.myRating,
          totalSessionSeconds: currentItem.totalSessionSeconds,
        ),
      );

      if (Get.isRegistered<HardwareCameraController>() &&
          currentSession.value != null) {
        unawaited(
          Get.find<HardwareCameraController>().syncCaptureContext(
            bookId: currentItem.book.id,
            page: newPage > 0 ? newPage : 1,
          ),
        );
      }
    }
  }

  Future<void> syncHardwareSelectedBook(int bookId, {int? page}) async {
    final item = getBookItem(bookId);
    if (item == null) {
      print("⚠️ [북스토퍼] 앱에 없는 책 ID 입니다: $bookId");
      return;
    }

    final resolvedPage = (page != null && page > 0) ? page : item.currentPage;
    final totalPages = item.book.totalPages;
    final progressPercent = totalPages > 0
        ? ((resolvedPage / totalPages) * 100).clamp(0, 100).toInt()
        : item.progressPercent;

    _applyReadingItem(
      ReadingLibraryItem(
        book: item.book,
        status: item.status,
        currentPage: resolvedPage,
        progressPercent: progressPercent,
        myRating: item.myRating,
        totalSessionSeconds: item.totalSessionSeconds,
      ),
    );

    if (Get.isRegistered<HardwareCameraController>() &&
        currentSession.value != null) {
      unawaited(
        Get.find<HardwareCameraController>().syncCaptureContext(
          bookId: item.book.id,
          page: resolvedPage > 0 ? resolvedPage : 1,
        ),
      );
    }
  }

  Future<void> handleHardwareStart(int bookId, int page) async {
    final now = DateTime.now();
    if (_ignoreHardwareStartUntil != null &&
        now.isBefore(_ignoreHardwareStartUntil!)) {
      print("ℹ️ [북스토퍼] 종료 직후 START 바운스를 무시합니다.");
      return;
    }

    await syncHardwareSelectedBook(bookId, page: page);

    if (currentSession.value != null) {
      if (currentSession.value!.bookId == bookId) {
        updateRealTimePage(page);
        return;
      }

      Get.snackbar(
        "알림",
        "이미 다른 독서 세션이 진행 중입니다.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    await startReadingSession(bookId, page > 0 ? page : null);
  }

  Future<void> handleHardwarePageUpdate(int bookId, int page) async {
    if (isSessionStarting.value || isSessionEnding.value) {
      print("ℹ️ [북스토퍼] 세션 전환 중 페이지 이벤트를 무시합니다.");
      return;
    }

    await syncHardwareSelectedBook(bookId, page: page);
    if (page > 0) {
      updateRealTimePage(page);
    }
  }

  Future<void> handleHardwareEnd(int bookId, int page) async {
    if (currentSession.value == null) return;
    if (isSessionStarting.value || isSessionEnding.value) {
      print("ℹ️ [북스토퍼] 세션 전환 중 END 이벤트를 무시합니다.");
      return;
    }

    final now = DateTime.now();
    if (_ignoreHardwareEndUntil != null &&
        now.isBefore(_ignoreHardwareEndUntil!)) {
      print("ℹ️ [북스토퍼] START 직후 END 바운스를 무시합니다.");
      return;
    }

    if (currentSession.value!.bookId != bookId) {
      print(
        "⚠️ [북스토퍼] 종료 이벤트 책 ID가 현재 세션과 다릅니다. current=${currentSession.value!.bookId}, incoming=$bookId",
      );
    }

    if (page > 0) {
      await endReading(page);
    }
  }

  void handleHardwareShortcut(int bookId, int page) {
    syncHardwareSelectedBook(bookId, page: page);
    openHighlightCreationForBook(
      bookId: bookId,
      initialPage: page > 0 ? page : null,
      autoStartOcr: true,
      initialCaptureMode: HighlightCaptureMode.immediateOcr,
      closePageAfterHighlightCreate: true,
    );
  }

  Future<void> showHighlightCaptureActionForCurrentBook() async {
    if (currentSession.value == null) {
      Get.snackbar(
        "알림",
        "독서를 시작한 뒤에만 하이라이트 촬영을 사용할 수 있어요.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final activeBook = currentActiveBook.value;
    if (activeBook == null) {
      Get.snackbar(
        "알림",
        "먼저 독서 중인 책을 선택해주세요.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final mode = await Get.bottomSheet<HighlightCaptureMode>(
      const HighlightCaptureModeSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    if (mode == null) return;

    await Future<void>.delayed(const Duration(milliseconds: 180));

    switch (mode) {
      case HighlightCaptureMode.immediateOcr:
        openHighlightCreationForCurrentBook(
          initialCaptureMode: HighlightCaptureMode.immediateOcr,
        );
        break;
      case HighlightCaptureMode.saveForLater:
        await captureHighlightForLaterForBook(
          bookId: activeBook.book.id,
          page: activeBook.currentPage,
        );
        break;
    }
  }

  Future<void> captureHighlightForLaterForBook({
    required int bookId,
    int? page,
  }) async {
    if (currentSession.value == null) {
      Get.snackbar(
        "알림",
        "독서를 시작한 뒤에만 하이라이트 촬영을 사용할 수 있어요.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final targetBook = getBookItem(bookId) ?? currentActiveBook.value;
    if (targetBook == null) {
      Get.snackbar("알림", "도서를 찾을 수 없습니다.");
      return;
    }

    try {
      final imagePath = await MobileOcr.captureImage();
      if (imagePath == null) {
        return;
      }

      final resolvedPage = (page != null && page > 0)
          ? page
          : (targetBook.currentPage > 0 ? targetBook.currentPage : 1);

      await HighlightCaptureDraftService.instance.saveCapture(
        bookId: targetBook.book.id,
        bookTitle: targetBook.book.title,
        page: resolvedPage,
        sourcePath: imagePath,
      );

      Get.snackbar(
        "저장 완료",
        "${resolvedPage}페이지 촬영본을 저장했어요.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (_) {
      Get.snackbar("오류", "촬영본 저장에 실패했습니다.");
    }
  }

  Future<void> _maybePromptPendingHighlightCaptures(
    int bookId, {
    String? promptKey,
  }) async {
    if (_isPendingHighlightPromptVisible) return;
    if (promptKey != null && _lastPendingHighlightPromptKey == promptKey) {
      return;
    }

    final count = await HighlightCaptureDraftService.instance
        .countDraftsForBook(bookId);
    if (count == 0) return;

    _isPendingHighlightPromptVisible = true;
    if (promptKey != null) {
      _lastPendingHighlightPromptKey = promptKey;
    }

    final action = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '저장된 촬영본 검토',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3F3F3F),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '이번 독서 중 저장한 촬영본이 $count개 있어요.\n지금 검토해서 하이라이트로 남길까요?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Get.back(result: false),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          '나중에',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: InkWell(
                      onTap: () => Get.back(result: true),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          '검토하기',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    _isPendingHighlightPromptVisible = false;

    if (action == true) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      openHighlightCaptureReviewForBook(bookId: bookId);
    }
  }

  void openHighlightCaptureReviewForBook({required int bookId}) {
    final targetBook = getBookItem(bookId) ?? currentActiveBook.value;
    if (targetBook == null) {
      Get.snackbar("알림", "도서를 찾을 수 없습니다.");
      return;
    }

    if (currentActiveBook.value?.book.id != targetBook.book.id) {
      currentActiveBook.value = targetBook;
    }

    Get.toNamed(
      '/book_note',
      arguments: {
        'bookId': targetBook.book.id,
        'tabIndex': 1,
        'openHighlightCaptureReview': true,
      },
    );
  }

  void openHighlightCreationForBook({
    required int bookId,
    int? initialPage,
    bool autoStartOcr = true,
    HighlightCaptureMode? initialCaptureMode,
    bool closePageAfterHighlightCreate = true,
  }) {
    final targetBook = getBookItem(bookId) ?? currentActiveBook.value;

    if (targetBook == null) {
      Get.snackbar(
        "알림",
        "먼저 독서 중인 책을 선택해주세요.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (currentActiveBook.value?.book.id != targetBook.book.id) {
      currentActiveBook.value = targetBook;
    }

    final resolvedPage = (initialPage != null && initialPage > 0)
        ? initialPage
        : (targetBook.currentPage > 0 ? targetBook.currentPage : 1);

    print(
      "✍️ [독서 등록] 하이라이트 OCR 진입 (bookId: ${targetBook.book.id}, page: $resolvedPage)",
    );

    Get.toNamed(
      '/book_note',
      arguments: {
        'bookId': targetBook.book.id,
        'tabIndex': 1,
        'openHighlightCreation': true,
        'initialHighlightPage': resolvedPage,
        'autoStartHighlightOcr': autoStartOcr,
        'autoStartHighlightCaptureMode':
            initialCaptureMode == HighlightCaptureMode.immediateOcr
            ? 'immediate'
            : initialCaptureMode == HighlightCaptureMode.saveForLater
            ? 'save_for_later'
            : null,
        'closePageAfterHighlightCreate': closePageAfterHighlightCreate,
      },
    );
  }

  void openHighlightCreationForCurrentBook({
    HighlightCaptureMode? initialCaptureMode,
  }) {
    final activeBook = currentActiveBook.value;

    if (activeBook == null) {
      Get.snackbar(
        "알림",
        "먼저 독서 중인 책을 선택해주세요.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    openHighlightCreationForBook(
      bookId: activeBook.book.id,
      initialPage: activeBook.currentPage,
      autoStartOcr: true,
      initialCaptureMode: initialCaptureMode,
      closePageAfterHighlightCreate: true,
    );
  }
}
