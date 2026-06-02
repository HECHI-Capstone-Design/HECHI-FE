import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_ocr_flutter/mobile_ocr_flutter.dart';
import '../../controllers/book_note_controller.dart';
import '../styles/overlay_common.dart';
import 'ocr_line_selection_overlay.dart';

class CreationOverlay extends StatefulWidget {
  final String type; // bookmark | highlight | memo
  final bool isEdit;
  final bool isReadOnly;

  // 공통
  final int? itemId;

  // bookmark
  final int? page;
  final String? memo;

  // highlight
  final String? sentence;
  final bool? isPublic;
  final bool autoStartOcr;
  final bool closeParentPageOnCreate;

  // memo
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
  bool _hasTriggeredAutoOcr = false;

  @override
  void initState() {
    super.initState();

    pageController = TextEditingController(text: widget.page?.toString() ?? "");
    memoController = TextEditingController(text: widget.memo ?? "");
    sentenceController = TextEditingController(text: widget.sentence ?? "");
    contentController = TextEditingController(text: widget.content ?? "");
    isPublic = widget.isPublic ?? false;
    _isReadOnly = widget.isReadOnly;

    if (widget.type == "highlight" && widget.autoStartOcr && !widget.isEdit && !_isReadOnly) {
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
  Widget build(BuildContext context) {
    final controller = Get.find<BookNoteController>();

    return Container(
      // 🚀 최대 높이를 제한하되, 기기 화면의 92%까지만 허용 (노치 대응)
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // 모서리 살짝 더 둥글게
      ),
      clipBehavior: Clip.hardEdge,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false, // 🚀 하단 패딩을 수동으로 주므로 false 유지
        body: SafeArea(
          top: false,
          bottom: false,
          child: widget.type == "bookmark"
              ? _buildBookmarkLayout(controller)
              : widget.type == "highlight"
              ? _buildHighlightLayout(controller, context)
              : _buildMemoLayout(controller),
        ),
      ),
    );
  }

  // =========================================================
  // 공통 헤더
  // =========================================================
  Widget _buildHeader(BookNoteController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 10, 17, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              if (_isReadOnly) {
                setState(() => _isReadOnly = false);
              } else {
                Get.back();
              }
            },
            child: Text(_isReadOnly ? "수정" : "취소", style: OverlayCommon.actionStyle),
          ),
          Text(_title(), style: OverlayCommon.headerStyle),
          TextButton(
            onPressed: () {
              if (_isReadOnly) {
                Get.back();
              } else {
                _onConfirm(controller);
              }
            },
            child: Text(
              _isReadOnly ? "닫기" : "확인",
              style: OverlayCommon.actionStyle.copyWith(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  String _title() {
    if (_isReadOnly) return "상세 보기";
    switch (widget.type) {
      case "bookmark": return widget.isEdit ? "북마크 수정" : "북마크 작성";
      case "highlight": return widget.isEdit ? "하이라이트 수정" : "하이라이트 작성";
      default: return widget.isEdit ? "메모 수정" : "메모 작성";
    }
  }

  // =========================================================
  // Bookmark 레이아웃
  // =========================================================
  Widget _buildBookmarkLayout(BookNoteController controller) {
    return Column(
      children: [
        _buildHeader(controller),
        Container(width: double.infinity, height: 1, color: const Color(0xFFF3F3F3)),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          color: const Color(0x80D1EDD9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("p.", style: TextStyle(color: Color(0xFF717171), fontSize: 15, height: 1.67)),
              const SizedBox(width: 5),
              Expanded(
                child: TextField(
                  controller: pageController,
                  readOnly: _isReadOnly,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    border: InputBorder.none, isCollapsed: true,
                    hintText: "북마크할 페이지 번호를 입력해주세요.",
                    hintStyle: TextStyle(color: Color(0xFFABABAB), fontSize: 13, height: 1.9),
                  ),
                  style: const TextStyle(color: Color(0xFF3F3F3F), fontSize: 15, height: 1.67),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          // 🚀 수정: 키보드 올라와도 터지지 않게 스크롤뷰 적용 및 expands 제거
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 17, right: 17, top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16, // 키보드 패딩
            ),
            child: TextField(
              controller: memoController,
              readOnly: _isReadOnly,
              minLines: 8, // 최소 높이 확보
              maxLines: null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "페이지에 대한 생각을 자유롭게 적어주세요.",
                hintStyle: TextStyle(color: Color(0xFFABABAB), fontSize: 13, height: 2.15),
              ),
              style: const TextStyle(color: Color(0xFF3F3F3F), fontSize: 15, height: 1.6),
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
        _buildHeader(controller),
        Container(width: double.infinity, height: 1, color: const Color(0xFFF3F3F3)),

        Expanded(
          // 🚀 핵심 수정: 하이라이트 입력 폼 전체를 스크롤 가능하게 묶어줌
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 문장 입력 영역
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                  decoration: const BoxDecoration(color: Color(0x7FD1ECD9)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isReadOnly)
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _isExtractingOcr ? null : _handleHighlightOcrCapture,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isExtractingOcr)
                                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4DB56C)))
                                else
                                  const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF4DB56C)),
                                const SizedBox(width: 6),
                                Text(
                                  _isExtractingOcr ? "문장 추출 중..." : "카메라로 문장 가져오기",
                                  style: const TextStyle(color: Color(0xFF4DB56C), fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!_isReadOnly) const SizedBox(height: 10),
                      TextField( // 🚀 Expanded 제거, 스크롤 뷰 안에 있으므로 자연스럽게 늘어남
                        controller: sentenceController,
                        readOnly: _isReadOnly,
                        minLines: 2,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          isCollapsed: true, border: InputBorder.none,
                          hintText: "하이라이트 문장을 입력해주세요.",
                          hintStyle: TextStyle(color: Color(0xFFABABAB), fontSize: 13, height: 1.9),
                        ),
                        style: const TextStyle(color: Color(0xFF3F3F3F), fontSize: 15, height: 1.67),
                      ),
                    ],
                  ),
                ),

                // 페이지 입력
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 14, 17, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("p.", style: TextStyle(color: Color(0xFFABABAB), fontSize: 15, height: 1.67)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: pageController,
                          readOnly: _isReadOnly,
                          maxLines: 1,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            border: InputBorder.none, isCollapsed: true,
                            hintText: "페이지 번호",
                            hintStyle: TextStyle(color: Color(0xFFABABAB), fontSize: 13, height: 1.9),
                          ),
                          style: const TextStyle(color: Color(0xFF3F3F3F), fontSize: 15, height: 1.67),
                        ),
                      ),
                    ],
                  ),
                ),

                // 메모 입력
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
                  child: TextField( // 🚀 Expanded 제거, 최소 5줄 확보
                    controller: memoController,
                    readOnly: _isReadOnly,
                    minLines: 5,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "문장에 대한 생각을 자유롭게 적어주세요.",
                      hintStyle: TextStyle(color: Color(0xFFABABAB), fontSize: 13),
                    ),
                    style: const TextStyle(color: Color(0xFF3F3F3F), fontSize: 15, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ),

        // --------------------- 공개 여부 (바닥 고정) ---------------------
        Container(
          padding: EdgeInsets.fromLTRB(
            17, 16, 17,
            // 🚀 키보드가 올라오면 스위치 박스 전체를 키보드 위로 예쁘게 밀어올림
            MediaQuery.of(context).viewInsets.bottom > 0
                ? MediaQuery.of(context).viewInsets.bottom + 20 // 키보드 있을 때: 키보드 위로 20px
                : MediaQuery.of(context).padding.bottom + 20,  // 🚀 키보드 없을 때: 기기 홈 버튼 영역(padding.bottom) + 20px 여백 추가
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF3F3F3))), // 구분선 추가
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("공개 여부", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
              IgnorePointer(
                ignoring: _isReadOnly,
                child: Opacity(
                  opacity: _isReadOnly ? 0.5 : 1.0,
                  child: Switch(
                    value: isPublic,
                    onChanged: (v) => setState(() => isPublic = v),
                    activeColor: const Color(0xFF4DB56C),
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
        _buildHeader(controller),
        Container(width: double.infinity, height: 1, color: const Color(0xFFF3F3F3)),
        Expanded(
          // 🚀 수정: 스크롤뷰 추가 및 expands 옵션 제거
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 17, right: 17, top: 14,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16, // 키보드 패딩
            ),
            child: TextField(
              controller: contentController,
              readOnly: _isReadOnly,
              minLines: 10,
              maxLines: null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "작품에 대한 생각을 자유롭게 적어주세요.",
                hintStyle: TextStyle(color: Color(0xFFABABAB), fontSize: 13, fontWeight: FontWeight.w400, height: 2.15),
              ),
              style: const TextStyle(color: Color(0xFF3F3F3F), fontSize: 15, height: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  // Confirm 버튼 로직 등은 기존 코드와 100% 동일하게 유지했습니다.
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