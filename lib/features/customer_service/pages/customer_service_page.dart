import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/customer_service_controller.dart';
import '../widgets/faq_tile.dart';
import '../widgets/inquiry_tile.dart';

class CustomerServicePage extends StatelessWidget {
  CustomerServicePage({Key? key}) : super(key: key);
  final controller = Get.put(CustomerServiceController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        switch (controller.currentViewIndex.value) {
          case 0: return _buildMainView();
          case 1: return _buildHistoryView();
          case 2: return _buildRegisterView();
          case 3: return _buildDetailView();
          case 4: return _buildFaqDetailView();
          default: return _buildMainView();
        }
      }),
        ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      actions: [
        Obx(() => IconButton(
          icon: Icon(controller.isAdminMode.value ? Icons.admin_panel_settings : Icons.person, color: Colors.black),
          onPressed: controller.toggleAdminMode,
        ))
      ],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => controller.currentViewIndex.value == 0 ? Get.back() : controller.changeView(0),
      ),
      title: Obx(() {
        String prefix = controller.isAdminMode.value ? "[관리자] " : "";
        String title = '고객센터';
        if (controller.currentViewIndex.value == 1) title = '문의내역';
        if (controller.currentViewIndex.value == 2) title = '문의등록';
        return Text(prefix + title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
      }),
    );
  }

  Widget _buildMainView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton('문의목록', false, () => controller.changeView(1)),
                if (!controller.isAdminMode.value) ...[
                  const SizedBox(width: 10),
                  _buildActionButton('문의등록', true, () => controller.changeView(2)),
                ]
              ],
            ),
          ),
          Obx(() => Column(
            children: controller.faqList.map((faq) => FaqTile(title: faq.question, onTap: () => controller.viewFaqDetail(faq))).toList(),
          )),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return Obx(() {
      var list = controller.isAdminMode.value ? controller.adminInquiries : controller.myInquiries;
      if (list.isEmpty) return const Center(child: Text("내역이 없습니다."));
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return InquiryTile(title: item.title, status: item.displayStatus, date: item.formattedDate, onTap: () => controller.viewDetail(item));
        },
      );
    });
  }

  Widget _buildRegisterView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(controller: controller.titleController, decoration: const InputDecoration(hintText: '제목')),
          const SizedBox(height: 20),
          TextField(controller: controller.contentController, maxLines: 8, decoration: const InputDecoration(hintText: '내용')),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: controller.submitInquiry, child: const Text('제출')),
        ],
      ),
    );
  }

  Widget _buildDetailView() {
    final item = controller.selectedInquiry.value;
    if (item == null) return const SizedBox();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(height: 40),
          Text(item.description),
          if (controller.isAdminMode.value) ...[
            const SizedBox(height: 40),
            const Text("답변 작성", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: controller.answerController, maxLines: 5),
            ElevatedButton(onPressed: controller.submitAdminAnswer, child: const Text("답변 등록")),
          ]
        ],
      ),
    );
  }

  Widget _buildFaqDetailView() {
    final faq = controller.selectedFaq.value;
    if (faq == null) return const SizedBox();
    return Padding(padding: const EdgeInsets.all(20), child: Text(faq.answer));
  }

  Widget _buildActionButton(String text, bool isFilled, VoidCallback onTap) {
    return ElevatedButton(onPressed: onTap, child: Text(text));
  }
}