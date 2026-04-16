import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommentOverlay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final RxString text = initialText.obs;
    final RxBool isSpoiler = initialSpoiler.obs;
    final TextEditingController textController = TextEditingController(text: initialText);

    return Container(
      height: Get.height * 0.9,
      // padding: const EdgeInsets.only(bottom: 5),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.hardEdge,

      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,

        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                // ===== 헤더 =====
                child: Row(
                  children: [
                    TextButton(
                      onPressed: Get.back,
                      child: const Text("취소",
                          style: TextStyle(fontSize: 13, color: Colors.black)),
                    ),
                    const Spacer(),
                    Text(
                        isEditMode ? "코멘트 수정" : "코멘트 등록",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
                    ),
                    const Spacer(),

                    TextButton(
                      onPressed: () async {
                        if (text.value.trim().isEmpty) {
                          Get.snackbar("알림", "내용을 입력해주세요");
                          return;
                        }

                        FocusManager.instance.primaryFocus?.unfocus();
                        await onSubmit(text.value.trim(), isSpoiler.value);

                        Get.back();
                        if (isEditMode){
                          Get.snackbar("완료", "리뷰가 수정되었습니다.");
                        } else {
                          Get.snackbar("완료", "리뷰가 등록되었습니다.");
                        }
                      },
                      child: Text(
                          isEditMode ? "수정" : "등록",
                          style: TextStyle(fontSize: 13, color: Colors.black)
                      ),
                    ),
                  ],
                ),
              ),

              // ===== 내용 입력 =====
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 17,
                    right: 17,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: TextField(
                    controller: textController,
                    autofocus: true,
                    maxLines: null,
                    expands: true,
                    onChanged: (v) => text.value = v,
                    decoration: const InputDecoration(
                      hintText: "작품에 대한 생각을 자유롭게 적어주세요",
                      hintStyle:
                      TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w400),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // ===== 스포일러 토글 =====
              Container(
                padding: EdgeInsets.fromLTRB(
                  17, 5, 17,
                  MediaQuery.of(context).viewInsets.bottom > 0
                      ? MediaQuery.of(context).viewInsets.bottom
                      : 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "스포일러",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 10),
                    Obx(() => Switch(
                      value: isSpoiler.value,
                      onChanged: (v) => isSpoiler.value = v,
                      activeColor: Colors.green,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}