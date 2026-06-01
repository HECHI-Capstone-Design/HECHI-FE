import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

mixin GroupShareMixin {
  static const String _baseUrl = "https://api.43-202-101-63.sslip.io";

  String get _token => GetStorage().read('access_token') ?? "";
  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer $_token",
  };

  void openGroupShareFlow({
    required String itemType,
    required Map<String, dynamic> itemData,
    String? preselectedGroupId,
    String? preselectedBoardType,
  }) {
    if (preselectedGroupId != null && preselectedBoardType != null) {
      _shareToBoard(
        groupId: preselectedGroupId,
        boardType: preselectedBoardType,
        itemType: itemType,
        itemData: itemData,
      );
      return;
    }
    _openGroupSelectSheet(itemType: itemType, itemData: itemData);
  }

  Future<void> _openGroupSelectSheet({
    required String itemType,
    required Map<String, dynamic> itemData,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me/groups'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        _showErrorSnackbar();
        return;
      }

      final dynamic raw = jsonDecode(utf8.decode(response.bodyBytes));
      final List groups = raw['groups'] ?? [];

      if (groups.isEmpty) {
        Get.snackbar(
          "그룹 없음",
          "가입된 그룹이 없습니다.",
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
        return;
      }

      Get.bottomSheet(
        _SelectBottomSheet(
          title: "그룹 선택",
          items: groups.map((g) => g["name"]?.toString() ?? "").toList(),
          onSelect: (index) {
            final selectedGroup = groups[index];
            final String groupId = selectedGroup["groupId"]?.toString() ?? "";
            final List boards = selectedGroup["boards"] ?? [];
            Get.back();
            _openBoardSelectSheet(
              groupId: groupId,
              boards: boards,
              itemType: itemType,
              itemData: itemData,
            );
          },
        ),
      );
    } catch (e) {
      print("❌ Fetch Groups Error: $e");
      _showErrorSnackbar();
    }
  }

  void _openBoardSelectSheet({
    required String groupId,
    required List boards,
    required String itemType,
    required Map<String, dynamic> itemData,
  }) {
    if (boards.isEmpty) {
      Get.snackbar(
        "게시판 없음",
        "게시판이 없습니다.",
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return;
    }

    Get.bottomSheet(
      _SelectBottomSheet(
        title: "게시판 선택",
        items: boards.map((b) => b["label"]?.toString() ?? "").toList(),
        onSelect: (index) {
          final selectedBoard = boards[index];
          final String boardType = selectedBoard["boardType"]?.toString() ?? "";
          Get.back();
          _shareToBoard(
            groupId: groupId,
            boardType: boardType,
            itemType: itemType,
            itemData: itemData,
          );
        },
      ),
    );
  }

  Future<void> _shareToBoard({
    required String groupId,
    required String boardType,
    required String itemType,
    required Map<String, dynamic> itemData,
  }) async {
    try {
      final int recordId = itemData["id"] ?? 0;
      final String recordType = _toRecordType(itemType);

      final url = Uri.parse('$_baseUrl/groups/$groupId/posts');
      final body = {
        "type": boardType,
        "title": "",
        "content": "",
        "bookId": null,
        "records": [
          {
            "recordType": recordType,
            "recordId": recordId,
          }
        ],
      };

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          "공유 완료",
          "게시판에 추가되었습니다.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4DB56C),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          duration: const Duration(seconds: 2),
        );
      } else {
        print("❌ Share Error: ${response.statusCode} ${response.body}");
        _showErrorSnackbar();
      }
    } catch (e) {
      print("❌ Share Error: $e");
      _showErrorSnackbar();
    }
  }

  String _toRecordType(String itemType) {
    switch (itemType) {
      case "bookmark":  return "BOOKMARK";
      case "highlight": return "HIGHLIGHT";
      case "memo":      return "NOTE";
      default:          return "NOTE";
    }
  }

  void _showErrorSnackbar() {
    Get.snackbar(
      "오류",
      "잠시 후 다시 시도해주세요.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade400,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }
}

class _SelectBottomSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final void Function(int index) onSelect;
  final List<Color>? itemColors;

  const _SelectBottomSheet({
    required this.title,
    required this.items,
    required this.onSelect,
    this.itemColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3F3F3F),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Text(
                      "취소",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF4DB56C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
            ...items.asMap().entries.map((entry) => InkWell(
              onTap: () => onSelect(entry.key),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 0.5, color: Color(0xFFDADADA)),
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: itemColors?[entry.key] ?? const Color(0xFF3F3F3F),
                  ),
                ),
              ),
            )),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}