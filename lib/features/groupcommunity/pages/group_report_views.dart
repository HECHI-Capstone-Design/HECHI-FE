import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/features/groupcommunity/widgets/group_post_card.dart';

class GroupReportListView extends GetView<GroupController> {
  const GroupReportListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text("신고함", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Wandukong 독서클럽", style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.reportList.isEmpty) {
                  return const Center(child: Text("접수된 신고가 없습니다.", style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  itemCount: controller.reportList.length,
                  itemBuilder: (context, index) {
                    final report = controller.reportList[index];
                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5))
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        title: Text(
                          "신고 사유: ${report["reason"]}", 
                          style: const TextStyle(fontSize: 15, color: Colors.black87)
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        onTap: () => Get.to(() => GroupReportDetailView(report: report)),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupReportDetailView extends StatelessWidget {
  final Map<String, dynamic> report;
  const GroupReportDetailView({Key? key, required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> targetPost = report["targetPost"];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("신고 상세 보기", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🚨 접수된 사유", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(report["reason"] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("👇 신고 대상 원본 글", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            GroupPostCard(post: targetPost),
          ],
        ),
      ),
    );
  }
}