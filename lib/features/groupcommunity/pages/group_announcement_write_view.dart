// D:\HECHI\lib\features\groupcommunity\pages\group_announcement_write_view.dart 전체 수정

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';

class GroupAnnouncementWriteView extends StatelessWidget {
  const GroupAnnouncementWriteView({super.key});

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final controller = Get.find<GroupController>();
    const brandColor = Color(0xFF4EB56D);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton(
          onPressed: () => Get.back(),
          child: const Text("취소", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
        title: const Text("공지사항 작성", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              final String title = titleController.text;
              final String content = contentController.text;

              // 🛡️ [안전 예외 가드]: 빈 껍데기 전송 차단
              if (title.trim().isEmpty) {
                Get.snackbar("경고", "공지사항 제목을 입력해주세요.", snackPosition: SnackPosition.BOTTOM);
                return;
              }
              if (content.trim().isEmpty) {
                Get.snackbar("경고", "공지사항 내용을 입력해주세요.", snackPosition: SnackPosition.BOTTOM);
                return;
              }

              // 🚀 백엔드로 정품 스펙 API 전송 기동!
              final bool isSuccess = await controller.addAnnouncement(title, content);

              if (isSuccess) {
                Get.back(); // 통신 성공 확인 후 안전하게 이전 스크린 백
                Get.snackbar("성공", "새 공지사항이 등록되었습니다.", snackPosition: SnackPosition.BOTTOM);
              } else {
                Get.snackbar("오류", "공지사항 등록에 실패했습니다. 다시 시도해주세요.", snackPosition: SnackPosition.BOTTOM);
              }
            },
            child: const Text("확인", style: TextStyle(color: brandColor, fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: "제목",
                border: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: brandColor)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: contentController,
                maxLines: null,
                decoration: const InputDecoration(hintText: "그룹 공지사항을 작성하세요", border: InputBorder.none),
              ),
            ),
          ],
        ),
      ),
    );
  }
}