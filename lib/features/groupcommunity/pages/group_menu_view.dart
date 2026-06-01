import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/features/groupcommunity/pages/group_report_views.dart';
import 'package:hechi/features/search/data/book_model.dart';

class GroupMenuView extends StatelessWidget {
  const GroupMenuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GroupController controller = Get.find<GroupController>();
    const brandMainGreen = Color(0xFF4EB56D); 

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
                  onTap: () => _showChangeMissionBookSheet(brandMainGreen, controller),
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
              onTap: () => _showCustomConfirmDialog(context, controller),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Obx(() => Text(
                        controller.isLeader.value ? "그룹 삭제" : "그룹 탈퇴",
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                      )),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showCustomConfirmDialog(BuildContext context, GroupController controller) {
    final bool isLeader = controller.isLeader.value;
    final String titleText = isLeader ? "그룹 삭제" : "그룹 탈퇴";
    final String bodyText = isLeader ? "정말 그룹을 삭제하시겠습니까?" : "정말 그룹을 탈퇴하시겠습니까?";

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 20.0, left: 16.0, right: 16.0),
                  child: Column(
                    children: [
                      Text(
                        titleText,
                        style: const TextStyle(
                          color: Color(0xFF222222),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bodyText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 0.5,
                  color: const Color(0xFFE5E5E5),
                ),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14)),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            
                            if (isLeader) {
                              bool success = await controller.deleteGroup();
                              if (success) {
                                Get.back(); 
                                Get.offAllNamed('/home');
                                Get.snackbar("삭제 완료", "그룹이 성공적으로 삭제되었습니다.");
                              } else {
                                Get.snackbar("오류", "그룹 삭제 요청 처리에 실패했습니다.");
                              }
                            } else {
                              bool success = await controller.leaveGroup();
                              if (success) {
                                Get.back(); 
                                Get.offAllNamed('/home');
                                Get.snackbar("탈퇴 완료", "그룹에서 성공적으로 탈퇴되었습니다.");
                              } else {
                                Get.snackbar("오류", "그룹 탈퇴 요청 처리에 실패했습니다.");
                              }
                            }
                          },
                          child: const Text(
                            "예",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 0.5,
                        color: const Color(0xFFE5E5E5),
                      ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(bottomRight: Radius.circular(14)),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            "아니오",
                            style: TextStyle(
                              color: Color(0xFF999999),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangeMissionBookSheet(Color brandColor, GroupController controller) {
    final searchInputController = TextEditingController();
    controller.searchedBooksResult.clear();

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
                if (controller.isSearching.value) return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(brandColor)));
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
                          Get.snackbar("성공", "미션책이 변경 되었습니다.");
                        } else {
                          Get.snackbar("오류", "서버 미션책 변경 처리에 실패했습니다.");
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
}