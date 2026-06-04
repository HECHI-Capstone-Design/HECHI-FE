import 'package:hechi/app/colors.dart';
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

  void _onConfirm() => Get.back(result: _controller.text);
  void _onCancel() => Get.back(result: null);

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = (screenHeight * 0.9 - keyboardHeight)
        .clamp(300.0, screenHeight * 0.9);

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(),
              Container(
                width: double.infinity,
                height: 1,
                color: AppColors.divider,
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
                            color: AppColors.textDark,
                            fontSize: 13,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            height: 2.15,
                          ),
                          decoration: const InputDecoration(
                            hintText: '컬렉션에 대한 설명을 입력해주세요.',
                            hintStyle: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 13,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                              height: 2.15,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                            counterText: '',
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '$_charCount/${widget.maxLength}',
                            style: const TextStyle(
                              color: AppColors.textHint,
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
                  color: AppColors.textDark,
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
                color: AppColors.textDark,
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
                  color: AppColors.primary,
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