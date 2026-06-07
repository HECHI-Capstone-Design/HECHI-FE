import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommentOverlay extends StatefulWidget {
  final Function(String, bool) onSubmit;
  final String initialText;
  final bool initialSpoiler;
  final bool isEditMode;

  const CommentOverlay({
    super.key,
    required this.onSubmit,
    this.initialText = "",
    this.initialSpoiler = false,
    this.isEditMode = false,
  });

  @override
  State<CommentOverlay> createState() => _CommentOverlayState();
}

class _CommentOverlayState extends State<CommentOverlay> {
  late final TextEditingController textController;
  late bool isSpoiler;
  late String text;

  @override
  void initState() {
    super.initState();
    text = widget.initialText;
    isSpoiler = widget.initialSpoiler;
    textController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double systemTopPadding = MediaQuery.of(context).padding.top;
    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double screenHeight = MediaQuery.of(context).size.height;

    // CreationOverlay와 동일한 방식: sheetHeight에서 키보드 높이 직접 차감
    final double sheetHeight = (screenHeight - systemTopPadding - keyboardHeight)
        .clamp(200.0, screenHeight - systemTopPadding);

    final double bottomPadding =
    keyboardHeight > 0 ? 16.0 : systemBottomPadding + 16.0;

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
                // 헤더 (고정)
                _buildHeader(),
                const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

                // 텍스트 입력 (남은 공간)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(17, 12, 17, 0),
                    child: TextField(
                      controller: textController,
                      autofocus: true,
                      maxLines: null,
                      expands: true,
                      onChanged: (v) => text = v,
                      decoration: const InputDecoration(
                        hintText: "작품에 대한 생각을 자유롭게 적어주세요",
                        hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w400),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                // 푸터: 스포일러 토글 (항상 키보드 바로 위)
                Container(
                  padding: EdgeInsets.fromLTRB(17, 5, 17, bottomPadding),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "스포일러",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      Switch(
                        value: isSpoiler,
                        onChanged: (v) => setState(() => isSpoiler = v),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 30, 10, 12),
      child: Row(
        children: [
          TextButton(
            onPressed: Get.back,
            child: const Text("취소",
                style: TextStyle(fontSize: 13, color: Colors.black)),
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.isEditMode ? "코멘트 수정" : "코멘트 등록",
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          TextButton(
            onPressed: _onConfirm,
            child: Text(
              widget.isEditMode ? "수정" : "등록",
              style: const TextStyle(fontSize: 13, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    if (text.trim().isEmpty) {
      Get.snackbar("알림", "내용을 입력해주세요");
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await widget.onSubmit(text.trim(), isSpoiler);
    Get.back();
    Get.snackbar("완료", widget.isEditMode ? "리뷰가 수정되었습니다." : "리뷰가 등록되었습니다.");
  }
}