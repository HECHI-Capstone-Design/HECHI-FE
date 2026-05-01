import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CollectionDescriptionOverlay extends StatefulWidget {
  final String initialText;
  final int maxLength;

  const CollectionDescriptionOverlay({
    super.key,
    this.initialText = '',
    this.maxLength = 200,
  });

  @override
  State<CollectionDescriptionOverlay> createState() =>
      _CollectionDescriptionOverlayState();
}

class _CollectionDescriptionOverlayState
    extends State<CollectionDescriptionOverlay> {
  late final TextEditingController _controller;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _charCount = widget.initialText.length;
    _controller.addListener(() {
      setState(() {
        _charCount = _controller.text.length;
      });
    });

    // 오버레이가 열리면 자동으로 키보드 올림
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onConfirm() {
    Get.back(result: _controller.text);
  }

  void _onCancel() {
    Get.back(result: null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF3F3F3),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLength: widget.maxLength,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          color: Color(0xFF3F3F3F),
                          fontSize: 13,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          height: 2.15,
                        ),
                        decoration: InputDecoration(
                          hintText: '컬렉션에 대한 설명을 입력해주세요.',
                          hintStyle: const TextStyle(
                            color: Color(0xFFABABAB),
                            fontSize: 13,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            height: 2.15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                          // 기본 글자수 카운터 숨김 (커스텀으로 표시)
                          counterText: '',
                        ),
                      ),
                    ),
                    // 글자수 카운터 (우측 하단)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '$_charCount/${widget.maxLength}',
                          style: const TextStyle(
                            color: Color(0xFFABABAB),
                            fontSize: 13,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 앱바 ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _onCancel,
              child: const Text(
                '취소',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF3F3F3F),
                  fontSize: 15,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height: 1.87,
                ),
              ),
            ),
            const Text(
              '컬렉션 설명',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF3F3F3F),
                fontSize: 15,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                height: 1.87,
              ),
            ),
            GestureDetector(
              onTap: _onConfirm,
              child: const Text(
                '확인',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF4DB56C),
                  fontSize: 15,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height: 1.87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}