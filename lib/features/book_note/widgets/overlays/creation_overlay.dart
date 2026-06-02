import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_ocr_flutter/mobile_ocr_flutter.dart';
import '../../controllers/book_note_controller.dart';
import '../styles/overlay_common.dart';
import 'ocr_line_selection_overlay.dart';

class CreationOverlay extends StatefulWidget {
  final String type;
  final bool isEdit;
  final bool isReadOnly;
  final int? itemId;
  final int? page;
  final String? memo;
  final String? sentence;
  final bool? isPublic;
  final bool autoStartOcr;
  final bool closeParentPageOnCreate;
<<<<<<< HEAD
=======

  // memo
>>>>>>> 17d898f (feat: add camera OCR flow for highlight capture)
  final String? content;

  const CreationOverlay({
    super.key,
    required this.type,
    required this.isEdit,
    this.isReadOnly = false,
    this.itemId,
    this.page,
    this.memo,
    this.sentence,
    this.isPublic,
    this.autoStartOcr = false,
    this.closeParentPageOnCreate = false,
    this.content,
  });

  @override
  State<CreationOverlay> createState() => _CreationOverlayState();
}

class _CreationOverlayState extends State<CreationOverlay> {
  late TextEditingController pageController;
  late TextEditingController memoController;
  late TextEditingController sentenceController;
  late TextEditingController contentController;
  late bool isPublic;
  late bool _isReadOnly;
  bool _isExtractingOcr = false;
<<<<<<< HEAD
=======
  bool _hasTriggeredAutoOcr = false;
>>>>>>> 17d898f (feat: add camera OCR flow for highlight capture)

  @override
  void initState() {
    super.initState();
    pageController = TextEditingController(text: widget.page?.toString() ?? "");
    memoController = TextEditingController(text: widget.memo ?? "");
    sentenceController = TextEditingController(text: widget.sentence ?? "");
    contentController = TextEditingController(text: widget.content ?? "");
    isPublic = widget.isPublic ?? false;
    _isReadOnly = widget.isReadOnly;

    if (widget.type == "highlight" &&
        widget.autoStartOcr &&
        !widget.isEdit &&
        !_isReadOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasTriggeredAutoOcr) return;
        _hasTriggeredAutoOcr = true;
        _handleHighlightOcrCapture();
      });
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    memoController.dispose();
    sentenceController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  void dispose() {
    pageController.dispose();
    memoController.dispose();
    sentenceController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookNoteController>();

    final double systemTopPadding = MediaQuery.of(context).padding.top;
    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double screenHeight = MediaQuery.of(context).size.height;

    // ✅ 핵심 수정 1:
    // sheetHeight에서 키보드 높이를 직접 뺌
    // → 키보드가 올라올수록 시트가 줄어들어 footer가 키보드 바로 위에 자연스럽게 붙음
    // → footer에 keyboardHeight 패딩 불필요 → 입력 필드 사라짐 버그 해결
    final double sheetHeight = (screenHeight - systemTopPadding - keyboardHeight)
        .clamp(200.0, screenHeight - systemTopPadding);

    // ✅ 핵심 수정 2:
    // 호출부에서 ignoreSafeArea: true 로 변경 필요 (아래 주석 참고)
    // CreationOverlay가 직접 systemTopPadding을 처리하므로
    // ignoreSafeArea: false 이면 SafeArea가 중복 적용되어 헤더가 잘림
    return Padding(
      padding: EdgeInsets.only(top: systemTopPadding),
      child: SizedBox(
        height: sheetHeight,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.white,
            child: Column(
              children: [
                // 1. 헤더 (고정)
                _buildHeader(controller),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: AppColors.divider,
                ),

                // 2. 스크롤 영역 (Expanded → 남은 공간 모두 차지)
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (widget.type == "bookmark")
                        ..._buildBookmarkItems(sheetHeight)
                      else if (widget.type == "highlight")
                        ..._buildHighlightItems(sheetHeight)
                      else
                        ..._buildMemoItems(sheetHeight),
                    ],
                  ),
                ),

                // 3. 푸터 (항상 시트 하단 = 키보드 바로 위)
                _buildFooter(systemBottomPadding, keyboardHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BookNoteController controller) {
    return Padding(
      // ✅ 추가된 기능: 상단 여백을 30으로 늘리고 하단을 12로 줄여서, 글자를 회색 구분선 쪽으로 내렸습니다.
      padding: const EdgeInsets.fromLTRB(17, 30, 17, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("취소", style: TextStyle(color: AppColors.textMedium)),
          ),
          Text(_title(), style: OverlayCommon.headerStyle),
          TextButton(
            onPressed: () => _onConfirm(controller),
            child: const Text("확인",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(double safeBottom, double keyboardHeight) {
    // ✅ 수정:
    // sheetHeight가 이미 키보드 높이만큼 줄어들었으므로
    // footer는 홈바 여백만 처리하면 됨
    // 키보드 열림 여부에 따라 분기
    final double bottomPadding =
    keyboardHeight > 0 ? 16.0 : safeBottom + 16.0;

    return Container(
      padding: EdgeInsets.only(
        left: 17,
        right: 17,
        top: 16,
        bottom: bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: widget.type == "highlight"
          ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "공개 여부",
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w400),
          ),
          Switch(
            value: isPublic,
            onChanged: _isReadOnly
                ? null
                : (v) => setState(() => isPublic = v),
            activeColor: AppColors.primary,
          ),
        ],
      )
          : const SizedBox.shrink(),
    );
  }

  List<Widget> _buildBookmarkItems(double h) => [
    _buildPageInput(),
    _buildMemoInput(h * 0.4),
  ];

  List<Widget> _buildHighlightItems(double h) => [
    _buildSentenceInput(h * 0.25),
    _buildPageInput(),
    _buildMemoInput(h * 0.25),
  ];

  List<Widget> _buildMemoItems(double h) => [
    _buildMemoInput(h * 0.5),
  ];

  Widget _buildPageInput() {
    final controller = Get.find<BookNoteController>();
    final totalPages = (controller.bookInfo["total_pages"] ?? 0) as int;
    final hintText = totalPages > 0 ? "페이지 번호 (최대 ${totalPages}p)" : "페이지 번호";

    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 14, 17, 0),
      child: Row(
        children: [
          const Text("p.",
              style: TextStyle(color: AppColors.textHint, fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: pageController,
              readOnly: _isReadOnly,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceInput(double maxHeight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      color: AppColors.primarySurface,
      child: Column(
        children: [
          if (!_isReadOnly) _buildOcrCaptureButton(),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: TextField(
              controller: sentenceController,
              readOnly: _isReadOnly,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "문장을 입력하세요.",
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoInput(double maxHeight) {
    return Padding(
      padding: const EdgeInsets.all(17),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: TextField(
          controller:
          widget.type == "memo" ? contentController : memoController,
          readOnly: _isReadOnly,
          maxLines: null,
          decoration: InputDecoration(
            hintText:
            widget.type == "memo" ? "메모를 입력하세요." : "생각을 자유롭게 적어주세요.",
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildOcrCaptureButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _isExtractingOcr ? null : _handleHighlightOcrCapture,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.camera_alt_outlined,
                size: 16, color: AppColors.primary),
            SizedBox(width: 6),
            Text(
              "카메라로 문장 가져오기",
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleHighlightOcrCapture() async {
    setState(() => _isExtractingOcr = true);
    try {
      final result = await MobileOcr.captureAndRecognize();
      if (!mounted || result == null) return;
      final selectedText = await Get.bottomSheet<String>(
        OcrLineSelectionOverlay(
          lines: result.lines.map((l) => l.text.trim()).toList(),
        ),
        isScrollControlled: true,
        ignoreSafeArea: false,
        backgroundColor: Colors.transparent,
      );
      if (selectedText != null) {
        setState(() => sentenceController.text = selectedText.trim());
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isExtractingOcr = false);
    }
  }

  Future<void> _onConfirm(BookNoteController controller) async {
    if (_isReadOnly) {
      Get.back();
      return;
    }

    final pageText = pageController.text.trim();
    final page = int.tryParse(pageText);
    final memo = memoController.text.trim();
    final sentence = sentenceController.text.trim();
    final content = contentController.text.trim();

    final totalPages = (controller.bookInfo["total_pages"] ?? 0) as int;

    if (widget.type == "bookmark") {
      if (page == null || page <= 0) {
        Get.snackbar("입력 오류", "페이지 번호를 입력해주세요.");
        return;
      }
      if (totalPages > 0 && page > totalPages) {
        Get.snackbar("입력 오류", "페이지는 최대 ${totalPages}p까지 입력 가능합니다.");
        return;
      }
      if (widget.isEdit && widget.itemId != null) {
        await controller.updateBookmark(widget.itemId!, page, memo);
      } else {
        await controller.createBookmark(page, memo);
      }
    } else if (widget.type == "highlight") {
      if (sentence.isEmpty) {
        Get.snackbar("입력 오류", "문장을 입력해주세요.");
        return;
      }
      if (page == null || page <= 0) {
        Get.snackbar("입력 오류", "페이지 번호를 입력해주세요.");
        return;
      }
      if (totalPages > 0 && page > totalPages) {
        Get.snackbar("입력 오류", "페이지는 최대 ${totalPages}p까지 입력 가능합니다.");
        return;
      }
      if (widget.isEdit && widget.itemId != null) {
        await controller.updateHighlight(widget.itemId!, page, sentence, memo, isPublic);
      } else {
        await controller.createHighlight(page, sentence, memo, isPublic);
      }
    } else {
      // memo
      if (content.isEmpty) {
        Get.snackbar("입력 오류", "메모 내용을 입력해주세요.");
        return;
      }
      if (widget.isEdit && widget.itemId != null) {
        await controller.updateMemo(widget.itemId!, content);
      } else {
        await controller.createMemo(content);
      }
    }
  }

  String _title() {
    if (_isReadOnly) return "상세 보기";
    switch (widget.type) {
      case "bookmark": return widget.isEdit ? "북마크 수정" : "북마크 작성";
      case "highlight": return widget.isEdit ? "하이라이트 수정" : "하이라이트 작성";
      default: return widget.isEdit ? "메모 수정" : "메모 작성";
    }
  }
<<<<<<< HEAD
}
=======

  // =========================================================
  // Bookmark 레이아웃
  // =========================================================
  Widget _buildBookmarkLayout(BookNoteController controller) {
    return Column(
      children: [
        // --------------------- Header ---------------------
        _buildHeader(controller),

        // --------------------- Divider ---------------------
        Container(
          width: double.infinity,
          height: 1,
          color: const Color(0xFFF3F3F3),
        ),

        // --------------------- 연두색 영역 (페이지 입력) ---------------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          color: const Color(0x80D1EDD9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "p.",
                style: TextStyle(
                  color: Color(0xFF717171),
                  fontSize: 15,
                  height: 1.67,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: TextField(
                  controller: pageController,
                  readOnly: _isReadOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: "북마크할 페이지 번호를 입력해주세요.",
                    hintStyle: TextStyle(
                      color: Color(0xFFABABAB),
                      fontSize: 13,
                      height: 1.9,
                    ),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF3F3F3F),
                    fontSize: 15,
                    height: 1.67,
                  ),
                ),
              ),
            ],
          ),
        ),

        // --------------------- 메모 입력 ---------------------
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
            child: TextField(
              controller: memoController,
              readOnly: _isReadOnly,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "페이지에 대한 생각을 자유롭게 적어주세요.",
                hintStyle: TextStyle(
                  color: Color(0xFFABABAB),
                  fontSize: 13,
                  height: 2.15,
                ),
              ),
              style: const TextStyle(
                color: Color(0xFF3F3F3F),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // highlight 레이아웃
  // =========================================================

  Widget _buildHighlightLayout(BookNoteController controller, BuildContext context) {
    return Column(
      children: [
        // --------------------- Header ---------------------
        _buildHeader(controller),

        // --------------------- Divider ---------------------
        Container(
          width: double.infinity,
          height: 1,
          color: const Color(0xFFF3F3F3),
        ),

        // --------------------- 내용 영역 ---------------------
        Expanded(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  maxHeight: 160,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                decoration: const BoxDecoration(
                  color: Color(0x7FD1ECD9),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isReadOnly)
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _isExtractingOcr
                              ? null
                              : _handleHighlightOcrCapture,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isExtractingOcr)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF4DB56C),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 16,
                                  color: Color(0xFF4DB56C),
                                ),
                              const SizedBox(width: 6),
                              Text(
                                _isExtractingOcr
                                    ? "문장 추출 중..."
                                    : "카메라로 문장 가져오기",
                                style: const TextStyle(
                                  color: Color(0xFF4DB56C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!_isReadOnly) const SizedBox(height: 10),
                    Expanded(
                      child: TextField(
                        controller: sentenceController,
                        readOnly: _isReadOnly,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: "하이라이트 문장을 입력해주세요.",
                          hintStyle: TextStyle(
                            color: Color(0xFFABABAB),
                            fontSize: 13,
                            height: 1.9,
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF3F3F3F),
                          fontSize: 15,
                          height: 1.67,
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              // --------------------- 페이지 입력 ---------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 14, 17, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "p.",
                      style: TextStyle(
                        color: Color(0xFFABABAB),
                        fontSize: 15,
                        height: 1.67,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: pageController,
                        readOnly: _isReadOnly,
                        maxLines: 1,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintText: "페이지 번호",
                          hintStyle: TextStyle(
                            color: Color(0xFFABABAB),
                            fontSize: 13,
                            height: 1.9,
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF3F3F3F),
                          fontSize: 15,
                          height: 1.67,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --------------------- 메모 입력 ---------------------
              Expanded(
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
                  child: TextField(
                    controller: memoController,
                    readOnly: _isReadOnly,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "문장에 대한 생각을 자유롭게 적어주세요.",
                      hintStyle: TextStyle(
                        color: Color(0xFFABABAB),
                        fontSize: 13,
                      ),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF3F3F3F),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // --------------------- 공개 여부 ---------------------
        Container(
          padding: EdgeInsets.fromLTRB(
            17, 16, 17,
            MediaQuery.of(context).viewInsets.bottom > 0
                ? MediaQuery.of(context).viewInsets.bottom
                : 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("공개 여부",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
              IgnorePointer(
                ignoring: _isReadOnly,
                child: Opacity(
                  opacity: _isReadOnly ? 0.5 : 1.0,
                  child: Switch(
                    value: isPublic,
                    onChanged: (v) => setState(() => isPublic = v),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // memo 레이아웃
  // =========================================================
  Widget _buildMemoLayout(BookNoteController controller) {
    return Column(
      children: [
        // -----------------------------------------------------
        // Header
        // -----------------------------------------------------
        _buildHeader(controller),

        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFF3F3F3), width: 1),
              bottom: BorderSide(color: Color(0xFFF3F3F3), width: 1),
            ),
          ),
        ),

        // -----------------------------------------------------
        // Memo 입력 영역
        // -----------------------------------------------------
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
            child: TextField(
              controller: contentController,
              readOnly: _isReadOnly,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "작품에 대한 생각을 자유롭게 적어주세요.",
                hintStyle: TextStyle(
                  color: Color(0xFFABABAB),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 2.15,
                ),
              ),
              style: const TextStyle(
                color: Color(0xFF3F3F3F),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }


  // =========================================================
  // Confirm 버튼 로직
  // =========================================================
  Future<void> _onConfirm(BookNoteController controller) async {
    switch (widget.type) {
      case "bookmark":
        final page = int.tryParse(pageController.text);
        if (page == null) {
          Get.snackbar("오류", "페이지 번호를 입력해주세요.");
          return;
        }

        final int totalPage = controller.bookInfo['total_pages'] ?? 0;
        if (page <= 0 || page > totalPage){
          Get.snackbar("오류", "정확한 페이지 번호를 입력해주세요.");
          return;
        }

        final isDuplicate = controller.bookmarks.any((bookmark) {
          if (widget.isEdit && bookmark['id'] == widget.itemId) {
            return false;
          }
          return bookmark['page'] == page;
        });

        if (isDuplicate) {
          Get.snackbar("알림", "이미 등록된 페이지입니다.");
          return;
        }

        final memo = memoController.text.trim();

        if (widget.isEdit) {
          controller.updateBookmark(widget.itemId!, page, memo);
        } else {
          controller.createBookmark(page, memo);
        }
        break;

      case "highlight":
        final page = int.tryParse(pageController.text);
        if (page == null) {
          Get.snackbar("오류", "페이지 번호를 입력해주세요.");
          return;
        }
        final sentence = sentenceController.text.trim();
        if (sentence.isEmpty) {
          Get.snackbar("오류", "문장을 입력해주세요.");
          return;
        }

        final int totalPage = controller.bookInfo['total_pages'] ?? 0;
        if (page <= 0 || page > totalPage){
          Get.snackbar("오류", "정확한 페이지 번호를 입력해주세요.");
          return;
        }

        final memo = memoController.text.trim();

        if (widget.isEdit) {
          controller.updateHighlight(
            widget.itemId!,
            page,
            sentence,
            memo,
            isPublic,
          );
        } else {
          final saved = await controller.createHighlight(
            page,
            sentence,
            memo,
            isPublic,
          );
          if (saved && widget.closeParentPageOnCreate) {
            Get.back();
          }
        }
        break;

      case "memo":
        final content = contentController.text.trim();
        if (content.isEmpty) {
          Get.snackbar("오류", "메모를 입력해주세요.");
          return;
        }

        if (widget.isEdit) {
          controller.updateMemo(widget.itemId!, content);
        } else {
          controller.createMemo(content);
        }
        break;
    }
  }

  Future<void> _handleHighlightOcrCapture() async {
    setState(() {
      _isExtractingOcr = true;
    });

    try {
      final result = await MobileOcr.captureAndRecognize();
      if (!mounted || result == null) {
        return;
      }

      final candidateLines = result.lines
          .map((line) => line.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (candidateLines.isEmpty) {
        Get.snackbar("안내", "추출된 문장이 없습니다.");
        return;
      }

      final selectedText = await Get.bottomSheet<String>(
        OcrLineSelectionOverlay(lines: candidateLines),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );

      if (selectedText != null && selectedText.trim().isNotEmpty) {
        sentenceController.text = selectedText.trim();
        sentenceController.selection = TextSelection.fromPosition(
          TextPosition(offset: sentenceController.text.length),
        );
        setState(() {});
      }
    } catch (_) {
      Get.snackbar("오류", "문장 추출에 실패했습니다.");
    } finally {
      if (mounted) {
        setState(() {
          _isExtractingOcr = false;
        });
      }
    }
  }
}
>>>>>>> 17d898f (feat: add camera OCR flow for highlight capture)
