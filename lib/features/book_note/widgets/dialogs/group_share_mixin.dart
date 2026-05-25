import 'package:flutter/material.dart';
import 'package:get/get.dart';

mixin GroupShareMixin {
  void openGroupShareFlow({
    required String itemType,
    required Map<String, dynamic> itemData,
  }) {
    // TODO: GET /groups/my
    final dummyGroups = [
      {"id": "1", "name": "그룹 1"},
      {"id": "2", "name": "그룹 2"},
    ];

    Get.bottomSheet(
      _SelectBottomSheet(
        title: "그룹 선택",
        items: dummyGroups.map((g) => g["name"]!).toList(),
        onSelect: (index) {
          final selectedGroup = dummyGroups[index];
          Get.back();
          _openBoardSelectSheet(
            groupId: selectedGroup["id"]!,
            groupName: selectedGroup["name"]!,
            itemType: itemType,
            itemData: itemData,
          );
        },
      ),
    );
  }

  void _openBoardSelectSheet({
    required String groupId,
    required String groupName,
    required String itemType,
    required Map<String, dynamic> itemData,
  }) {
    // TODO: GET /groups/{groupId}/boards
    final dummyBoards = {
      "1": [
        {"id": "1", "name": "게시판 1"},
        {"id": "2", "name": "게시판 2"},
      ],
      "2": [
        {"id": "3", "name": "게시판 1"},
        {"id": "4", "name": "게시판 2"},
      ],
    };

    final boards = dummyBoards[groupId] ?? [];

    Get.bottomSheet(
      _SelectBottomSheet(
        title: "게시판 선택",
        items: boards.map((b) => b["name"]!).toList(),
        onSelect: (index) {
          final selectedBoard = boards[index];
          Get.back();
          // TODO: POST /groups/{groupId}/boards/{boardId}/posts
          print("공유 완료 - groupId: $groupId, boardId: ${selectedBoard["id"]}");
          /*
          Get.toNamed('/group-board', arguments: {
            'groupId': groupId,
            'groupName': groupName,
            'boardId': selectedBoard["id"],
            'boardName': selectedBoard["name"],
            'sharedItemType': itemType,
            'sharedItemData': itemData,
          });
          */
        },
      ),
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