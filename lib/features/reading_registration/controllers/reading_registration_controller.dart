import 'package:hechi/app/colors.dart';
// lib/features/reading_registration/controllers/reading_registration_controller.dart 최종 완결판

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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

  var libraryReadingItems = <ReadingLibraryItem>[].obs;
  var isLoading = false.obs;

  var currentActiveBook = Rxn<ReadingLibraryItem>();

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

  bool _isProcessingClick = false;

  final _storage = GetStorage();
  String _getTimeKey(dynamic bookId) => 'reading_time_${bookId.toString()}';
  String _getPageKey(dynamic bookId) => 'reading_page_${bookId.toString()}';

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

  // ------------------------------------------------------------------
  // 🌐 데이터 통합 패치 파이프라인 (세션 목록 역추적 복원 엔진 탑재)
  // ------------------------------------------------------------------
  Future<void> refreshData({bool showLoading = true}) async {
    try {
      if (showLoading && libraryReadingItems.isEmpty) isLoading(true);

      // 1. 백엔드 기본 리스트 긁어오기 (시간 정보 0초, 페이지 누락 가능성 있음)
      final items = await repository.getLibraryReadingItems();

      ReadingLibraryItem? targetItem;
      if (currentActiveBook.value != null) {
        targetItem = items.firstWhereOrNull(
                (item) => item.book.id.toString() == currentActiveBook.value!.book.id.toString()
        );
      }
      targetItem ??= (items.isNotEmpty ? items.first : null);

      if (targetItem != null) {
        final String bId = targetItem.book.id.toString();

        // [GetStorage 영구 쉴드]: 디바이스에 저장된 진짜 수치들 1차 복원
        int localSavedSeconds = _storage.read<int>(_getTimeKey(bId)) ?? 0;
        int localSavedPage = _storage.read<int>(_getPageKey(bId)) ?? targetItem.currentPage;

        // 🎯 백엔드가 줄 수 있는 정품 책 총 페이지 수 백업 (기본값은 백엔드 원본 유지)
        int officialTotalPages = targetItem.book.totalPages > 0 ? targetItem.book.totalPages : 0;

        // 세션 목록 API 역추적 가드 (서랍장이 비어있을 때만 연산)
        if (localSavedSeconds == 0) {
          try {
            final List<ReadingRegistrationSession> sessions = await repository.getReadingSessions(targetItem.book.id);
            if (sessions.isNotEmpty) {
              localSavedSeconds = sessions.fold<int>(0, (sum, element) => sum + element.totalSeconds);
              localSavedPage = sessions.last.endPage > 0 ? sessions.last.endPage : localSavedPage;

              _storage.write(_getTimeKey(bId), localSavedSeconds);
              _storage.write(_getPageKey(bId), localSavedPage);
            }
          } catch (sessionError) {
            print("⚠️ 세션 목록 역추적 실패 가드 작동: $sessionError");
          }
        }

        // 라이브 메모리 스냅샷 방어 (메모리에 더 큰 최신 수치가 있다면 강제 고정 및 서랍장 굳히기)
        if (currentActiveBook.value != null && currentActiveBook.value!.book.id.toString() == bId) {
          if (currentActiveBook.value!.totalSessionSeconds > localSavedSeconds) {
            localSavedSeconds = currentActiveBook.value!.totalSessionSeconds;
            _storage.write(_getTimeKey(bId), localSavedSeconds);
          }
          if (currentActiveBook.value!.currentPage > localSavedPage) {
            localSavedPage = currentActiveBook.value!.currentPage;
            _storage.write(_getPageKey(bId), localSavedPage);
          }
        }

        try {
          // 2. 백엔드 요약 API 호출 시도
          final summary = await repository.getBookSummary(targetItem.book.id);
          if (summary != null) {
            if (summary.totalPages > 0) officialTotalPages = summary.totalPages;

            _storage.write(_getTimeKey(bId), summary.totalSessionSeconds);
            _storage.write(_getPageKey(bId), summary.maxEndPage);

            // 요약 API가 준 최신 페이지 상태 갱신
            localSavedPage = summary.maxEndPage;

            final updatedBook = ReadingBook(
              id: targetItem.book.id,
              title: targetItem.book.title,
              thumbnail: targetItem.book.thumbnail,
              authors: targetItem.book.authors,
              totalPages: officialTotalPages > 0 ? officialTotalPages : targetItem.book.totalPages,
            );

            targetItem = ReadingLibraryItem(
              book: updatedBook,
              status: targetItem.status,
              currentPage: localSavedPage,
              progressPercent: summary.progressPercent,
              myRating: targetItem.myRating,
              totalSessionSeconds: summary.totalSessionSeconds,
            );
          }
        } catch (e) {
          print("⚠️ 요약 정보 조회 실패 (GetStorage 성벽 작동): $e");

          final int finalTotal = officialTotalPages > 0 ? officialTotalPages : (targetItem!.book.totalPages > 0 ? targetItem!.book.totalPages : 1);
          final safeProgress = ((localSavedPage / finalTotal) * 100).toInt();

          final updatedBook = ReadingBook(
            id: targetItem!.book.id,
            title: targetItem!.book.title,
            thumbnail: targetItem!.book.thumbnail,
            authors: targetItem!.book.authors,
            totalPages: finalTotal,
          );

          targetItem = ReadingLibraryItem(
            book: updatedBook,
            status: targetItem!.status,
            currentPage: localSavedPage,
            progressPercent: safeProgress > 100 ? 100 : safeProgress,
            myRating: targetItem!.myRating,
            totalSessionSeconds: localSavedSeconds,
          );
        }
      }

      // 3. 하단 보관함 리스트 매핑 파이프라인 (페이지 고정 에러 완전 해결 구역)
      libraryReadingItems.assignAll(items);
      for (int i = 0; i < libraryReadingItems.length; i++) {
        final String currentId = libraryReadingItems[i].book.id.toString();

        // 영구 서랍장에 박힌 최신 정품 페이지와 시간 추적
        int cachedTime = _storage.read<int>(_getTimeKey(currentId)) ?? libraryReadingItems[i].totalSessionSeconds;
        int cachedPage = _storage.read<int>(_getPageKey(currentId)) ?? libraryReadingItems[i].currentPage;

        // 라이브 타깃 매핑 일치 시 데이터 스와핑 보장
        if (targetItem != null && targetItem.book.id.toString() == currentId) {
          if (targetItem.totalSessionSeconds > cachedTime) cachedTime = targetItem.totalSessionSeconds;
          if (targetItem.currentPage > cachedPage) cachedPage = targetItem.currentPage;
        }

        // 🎯 [완치 핵심]: 하드코딩 370 고정을 버리고 백엔드가 내려준 진짜 책의 총 페이지수를 1순위로 동적 추출!
        // 만약 백엔드가 0이나 null을 주면 그때만 위젯이 안 터지게 기본 가드(1) 처리합니다.
        int itemTotalPages = libraryReadingItems[i].book.totalPages > 0 ? libraryReadingItems[i].book.totalPages : 1;
        if (targetItem != null && targetItem.book.id.toString() == currentId && targetItem.book.totalPages > 0) {
          itemTotalPages = targetItem.book.totalPages;
        }

        final safeProgress = ((cachedPage / itemTotalPages) * 100).toInt();

        final guardedBook = ReadingBook(
          id: libraryReadingItems[i].book.id,
          title: libraryReadingItems[i].book.title,
          thumbnail: libraryReadingItems[i].book.thumbnail,
          authors: libraryReadingItems[i].book.authors,
          totalPages: itemTotalPages,
        );

        libraryReadingItems[i] = ReadingLibraryItem(
          book: guardedBook,
          status: libraryReadingItems[i].status,
          currentPage: cachedPage,
          progressPercent: safeProgress > 100 ? 100 : safeProgress,
          myRating: libraryReadingItems[i].myRating,
          totalSessionSeconds: cachedTime,
        );
      }

      if (currentSession.value == null && targetItem != null) {
        final doubleGuardedItem = libraryReadingItems.firstWhereOrNull((element) => element.book.id.toString() == targetItem!.book.id.toString());
        currentActiveBook.value = doubleGuardedItem ?? targetItem;
      }

      libraryReadingItems.refresh();

      print("📢 현재 책 누적 시간: ${currentActiveBook.value?.totalSessionSeconds}초 | 현재 페이지: ${currentActiveBook.value?.currentPage}p");
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      if (showLoading) isLoading(false);
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

  Future<void> loadBookDetail(int bookId) async {
    try {
      final summary = await repository.getBookSummary(bookId);

      if (summary != null && currentActiveBook.value?.book.id == bookId) {
        final String bId = bookId.toString();
        _storage.write(_getTimeKey(bId), summary.totalSessionSeconds);
        _storage.write(_getPageKey(bId), summary.maxEndPage);

        final updatedBook = ReadingBook(
          id: currentActiveBook.value!.book.id,
          title: currentActiveBook.value!.book.title,
          thumbnail: currentActiveBook.value!.book.thumbnail,
          authors: currentActiveBook.value!.book.authors,
          totalPages: summary.totalPages,
        );

        currentActiveBook.value = ReadingLibraryItem(
          book: updatedBook,
          status: currentActiveBook.value!.status,
          currentPage: summary.maxEndPage,
          progressPercent: summary.progressPercent,
          myRating: currentActiveBook.value!.myRating,
          totalSessionSeconds: summary.totalSessionSeconds,
        );

        final index = libraryReadingItems.indexWhere((item) => item.book.id == bookId);
        if (index != -1) {
          libraryReadingItems[index] = currentActiveBook.value!;
          libraryReadingItems.refresh();
        }
      }
    } catch (e) {
      print("책 상세정보 로드 실패: $e");
    }
  }

  void onBookTap(int bookId) async {
    if (_isProcessingClick) return;
    if (Get.isDialogOpen == true) return;
    final newItem = getBookItem(bookId);
    if (newItem == null) return;

    if (currentSession.value != null) {
      Get.snackbar("알림", "현재 진행 중인 독서를 종료한 후 변경해주세요.",
          snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
      return;
    }

    _isProcessingClick = true;

    if (currentActiveBook.value == null || currentActiveBook.value!.book.id != bookId) {
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
                child: Text('도서 변경', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('\'${newItem.book.title}\'(으)로\n변경하시겠습니까?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textHint, height: 1.4)),
              ),
              const SizedBox(height: 30),
              const Divider(height: 1, color: AppColors.divider),
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _isProcessingClick = false;
                          Get.back();
                        },
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                        child: const Center(child: Text('취소', style: TextStyle(fontSize: 16, color: AppColors.textHint, fontWeight: FontWeight.w500))),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: AppColors.divider),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          Get.back();
                          currentActiveBook.value = newItem;
                          await loadBookDetail(bookId);
                          _isProcessingClick = false;
                        },
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                        child: const Center(child: Text('변경', style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w500))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false, // 꼬임 방지를 위해 외부 터치 차단
      ).then((_) {
        // 사용자가 뒤로가기 버튼 등으로 다이얼로그를 벗어났을 때를 대비한 안전 장치
        Future.delayed(const Duration(milliseconds: 200), () {
          _isProcessingClick = false;
        });
      });
    } else {
      _isProcessingClick = false;
      showStartDialog(newItem);
    }
  }

  void showStartDialog(ReadingLibraryItem item) {
    if (Get.isDialogOpen == true) return;
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
              child: Text('독서 시작', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('${item.book.title}\n독서를 시작하시겠습니까?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textHint, height: 1.4)),
            ),
            const SizedBox(height: 30),
            const Divider(height: 1, color: AppColors.divider),
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Get.back(),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                      child: const Center(child: Text('취소', style: TextStyle(fontSize: 16, color: AppColors.textHint, fontWeight: FontWeight.w500))),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.divider),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Get.back();
                        int safetyCount = 0;
                        while (Get.isDialogOpen == true) {
                          await Future.delayed(const Duration(milliseconds: 50));
                          safetyCount++;
                          if (safetyCount > 20) {
                            Get.back();
                            break;
                          }
                        }
                        startReadingSession(item.book.id, startPage);
                      },
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                      child: const Center(child: Text('시작', style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w500))),
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
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
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
      if (Get.isDialogOpen == true) Get.back();
      await Future.delayed(const Duration(milliseconds: 100));
      Get.snackbar("오류", "독서를 시작할 수 없습니다.");
    } finally {
      if (Get.isDialogOpen == true) Get.back();
      isSessionStarting.value = false;
    }
  }

  void showStopDialog() {
    // 🎯 [완치 핵심 1]: 그만 읽기 팝업이 뜨는 순간, 즉시 백그라운드 타이머를 일시정지 시킵니다!
    _timer?.cancel();

    final currentSimulatedPage = currentActiveBook.value?.currentPage ?? 0;
    final totalBookPages = currentActiveBook.value?.book.totalPages ?? 0;
    final pageCtrl = TextEditingController(text: currentSimulatedPage.toString());

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
              child: Text('독서 종료', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text("마지막 페이지", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: pageCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      cursorColor: AppColors.primary,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        hintText: '0',
                        hintStyle: const TextStyle(color: AppColors.border),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border, width: 1.2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border, width: 1.2)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                totalBookPages > 0 ? '읽은 페이지를 저장하시겠습니까? (최대 $totalBookPages p)' : '읽은 페이지를 저장하시겠습니까?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(height: 1, color: AppColors.divider),
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // 🎯 [완치 핵심 2]: 취소 버튼을 누르면 멈췄던 그 시간부터 타이머를 다시 재개(Resume)합니다!
                        _startTimer();
                        Get.back();
                      },
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                      child: const Center(child: Text('취소', style: TextStyle(fontSize: 16, color: AppColors.textHint, fontWeight: FontWeight.w500))),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.divider),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        final endPage = int.tryParse(pageCtrl.text);
                        if (endPage != null && endPage > 0 && (totalBookPages == 0 || endPage <= totalBookPages)) {
                          Get.back();
                          endReading(endPage); // 저장 프로세스 진입
                        } else {
                          Get.snackbar(
                              "경고",
                              endPage != null && totalBookPages > 0 && endPage > totalBookPages ? "도서의 총 페이지 수($totalBookPages p)를 초과할 수 없습니다." : "올바른 페이지 번호를 입력해주세요.",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.black87,
                              colorText: Colors.white,
                              margin: const EdgeInsets.all(20)
                          );
                        }
                      },
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                      child: const Center(child: Text('저장', style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w500))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    ).then((_) {
      // 🎯 [완치 핵심 3]: 사용자가 팝업 바깥 어두운 배경(Barrier)을 눌러서 창을 닫았을 때도 타이머가 다시 흐르도록 구출 처리!
      if (currentSession.value != null && (_timer == null || !_timer!.isActive)) {
        _startTimer();
      }
    });
  }

  Future<void> endReading(int endPage) async {
    if (currentSession.value == null) return;
    if (isSessionEnding.value || isSessionStarting.value) {
      print("ℹ️ [독서] 세션 전환 중이라 종료 요청을 무시합니다.");
      return;
    }

    final int targetBookId = currentSession.value!.bookId;
    final int sessionId = currentSession.value!.id;
    final int finalSeconds = elapsedSeconds.value;
    final int reviewPage = endPage > 0
        ? endPage
        : (currentActiveBook.value?.currentPage ?? 1);
    bool didSave = false;

    final currentItem = currentActiveBook.value;

    _timer?.cancel();
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    isSessionEnding.value = true;

    try {
      final sessionResult = await repository.endSession(sessionId, endPage, finalSeconds);
      print("=== 세션 종료 성공: ${sessionResult.totalSeconds}초, ${sessionResult.endPage}p ===");
      didSave = true;

      if (currentItem != null) {
        final totalPages = currentItem.book.totalPages;
        final newProgress = (totalPages > 0) ? ((sessionResult.endPage / totalPages) * 100).toInt() : 0;

        final int updatedTotalSeconds = currentItem.totalSessionSeconds + finalSeconds;
        final String bId = targetBookId.toString();

        _storage.write(_getTimeKey(bId), updatedTotalSeconds);
        _storage.write(_getPageKey(bId), sessionResult.endPage);

        final forcedUpdatedBook = ReadingBook(
          id: currentItem.book.id,
          title: currentItem.book.title,
          thumbnail: currentItem.book.thumbnail,
          authors: currentItem.book.authors,
          totalPages: totalPages,
        );

        final forcedItem = ReadingLibraryItem(
          book: forcedUpdatedBook,
          status: currentItem.status,
          currentPage: sessionResult.endPage,
          progressPercent: newProgress > 100 ? 100 : newProgress,
          myRating: currentItem.myRating,
          totalSessionSeconds: updatedTotalSeconds,
        );

        currentActiveBook.value = forcedItem;

        final index = libraryReadingItems.indexWhere((item) => item.book.id == targetBookId);
        if (index != -1) {
          libraryReadingItems[index] = forcedItem;
          libraryReadingItems.refresh();
        }
      }

      await refreshData(showLoading: false);

    } catch (e) {
      _isProcessingClick = false;

      // 🎯 [완치 핵심 4]: 서버 저장 전송 실패 시, 강제로 꺼졌던 타이머를 복구시켜 독서를 계속 이어갈 수 있게 만듭니다.
      _startTimer();

      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("오류", "저장에 실패했습니다: ${e.toString()}");
      return;
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
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

    Get.showSnackbar(
      GetSnackBar(
        message: "독서가 기록되었습니다.",
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        margin: const EdgeInsets.all(20),
        borderRadius: 8,
      ),
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

      final validatedPage = (totalPages > 0 && newPage > totalPages) ? totalPages : newPage;
      final newProgress = (totalPages > 0) ? ((validatedPage / totalPages) * 100).toInt() : 0;

      currentActiveBook.value = ReadingLibraryItem(
        book: currentItem.book,
        status: currentItem.status,
        currentPage: validatedPage,
        progressPercent: newProgress,
        myRating: currentItem.myRating,
        totalSessionSeconds: currentItem.totalSessionSeconds,
      );

      if (Get.isRegistered<HardwareCameraController>() &&
          currentSession.value != null) {
        unawaited(
          Get.find<HardwareCameraController>().syncCaptureContext(
            bookId: currentItem.book.id,
            page: validatedPage > 0 ? validatedPage : 1,
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

    currentActiveBook.value = ReadingLibraryItem(
      book: item.book,
      status: item.status,
      currentPage: resolvedPage,
      progressPercent: progressPercent,
      myRating: item.myRating,
      totalSessionSeconds: item.totalSessionSeconds,
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
