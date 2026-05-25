import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';

class GroupAnnouncementWriteView extends StatelessWidget {
  // 🔔 에러 해결: 부모 위젯 super Key 규격 완전 튜닝 수리 완료
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
        leading: TextButton(
          onPressed: () => Get.back(),
          child: const Text("취소", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
        title: const Text("공지사항 작성", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              if (contentController.text.isNotEmpty) {
                controller.addAnnouncement(titleController.text, contentController.text);
                Get.back();
                Get.snackbar("성공", "새 공지사항이 등록되었습니다.");
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
              decoration: const InputDecoration(hintText: "제목", border: UnderlineInputBorder()),
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