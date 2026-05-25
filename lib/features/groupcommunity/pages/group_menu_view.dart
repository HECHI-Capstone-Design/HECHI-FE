import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/features/groupcommunity/pages/group_report_views.dart';
import 'package:hechi/features/search/data/book_model.dart';

class GroupMenuView extends GetView<GroupController> {
  const GroupMenuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const unifiedGreen = Color(0xFF8DC695);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("그룹 메뉴", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.collections_bookmark, color: Colors.black87),
            title: const Text("미션 책 보관함"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Get.toNamed('/group/mission-history'),
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.black87),
            title: const Text("멤버 보기"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Get.toNamed('/group/members'),
          ),
          Obx(() {
            if (!controller.isLeader.value) return const SizedBox.shrink();
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.campaign, color: Colors.black87),
                  title: const Text("공지사항 작성하기"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Get.toNamed('/group/announcement/write'),
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book, color: Colors.black87),
                  title: const Text("미션책 변경"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showChangeMissionBookSheet(),
                ),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.black87),
                  title: const Text("신고함"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Get.to(() => const GroupReportListView()),
                ),
              ],
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () => _showLeaveOrDeleteConfirm(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: Colors.grey.shade100,
                child: Center(
                  child: Obx(() => Text(
                        controller.isLeader.value ? "그룹 삭제" : "그룹 탈퇴",
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      )),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showChangeMissionBookSheet() {
    final searchInputController = TextEditingController();
    controller.searchedBooksResult.clear();
    const brandColor = Color(0xFF8DC695);

    Get.to(
      Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Get.back()),
          title: const Text("미션 책 변경하기", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchInputController,
                onSubmitted: (val) => controller.searchBooksFromAPI(val),
                decoration: InputDecoration(
                  hintText: "새 미션 도서 검색 후 엔터",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Text("검색 결과 선택", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const Divider(),
            Expanded(
              child: Obx(() {
                if (controller.isSearching.value) return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(brandColor)));
                if (controller.searchedBooksResult.isEmpty) {
                  return const Center(child: Text("변경할 새 도서를 검색해 주세요.", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: controller.searchedBooksResult.length,
                  itemBuilder: (context, index) {
                    final Book book = controller.searchedBooksResult[index];
                    
                    final String title = book.title;
                    final String author = book.authorString;
                    final String coverUrl = book.thumbnail ?? "https://images.unsplash.com/photo-1495640388908-05fa85288e61?q=80&w=200";
                    
                    final String targetIsbn = book.isbn ?? "";

                    return ListTile(
                      leading: Container(
                        width: 40, height: 60,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                        child: Image.network(coverUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(author, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: const Icon(Icons.check_circle_outline, color: Colors.grey),
                      onTap: () async {
                        if (targetIsbn.isEmpty) {
                          Get.snackbar("알림", "해당 도서는 ISBN 정보가 식별되지 않아 미션책으로 등록할 수 없습니다.");
                          return;
                        }
                        
                        bool isSuccess = await controller.changeMissionBook(targetIsbn);
                        Get.back(); 
                        if (isSuccess) {
                          Get.snackbar("성공", "미션 책이 '$title'로 변경 및 보관함에 적치되었습니다.");
                        } else {
                          Get.snackbar("오류", "서버 미션책 변경 처리에 실패했습니다. (422/500 에러)");
                        }
                      },
                    );
                  },
                );
              }),
            )
          ],
        ),
      )
    );
  }

  void _showLeaveOrDeleteConfirm() {
    Get.defaultDialog(
      title: controller.isLeader.value ? "그룹 삭제" : "그룹 탈퇴",
      content: Text(controller.isLeader.value ? "그룹을 삭제 하시겠습니까?\n그룹 정보가 모두 사라집니다." : "그룹을 탈퇴 하시겠습니까?"),
      textConfirm: "예",
      textCancel: "아니오",
      confirmTextColor: Colors.red,
      cancelTextColor: Colors.black,
      onConfirm: () {
        Get.back();
        Get.back();
      }
    );
  }
}