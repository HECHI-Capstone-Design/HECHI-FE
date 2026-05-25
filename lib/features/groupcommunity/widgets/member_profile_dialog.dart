import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';

class MemberProfileDialog extends GetView<GroupController> {
  final Map<String, dynamic> member;
  const MemberProfileDialog({Key? key, required this.member}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF4EB56D);

    return Dialog(
      backgroundColor: Colors.white, // 🔔 보라색 기운을 완전히 제거한 순백의 화이트 테마 강제 정비
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(member["nickname"] ?? "그룹원", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                TextButton(onPressed: () => Get.back(), child: const Text("취소", style: TextStyle(color: brandColor))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("미션책 진행률", style: TextStyle(color: Colors.black54)),
                Text("${((member["progress"] ?? 0.0) * 100).toInt()}%", style: const TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFEAEAEA)),
            if (controller.isLeader.value && member["isLeader"] != true)
              InkWell(
                onTap: () {
                  controller.kickMember(member["nickname"] ?? "");
                  Get.back();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("강제 탈퇴", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              )
          ],
        ),
      ),
    );
  }
}