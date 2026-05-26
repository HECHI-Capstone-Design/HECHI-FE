import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_tab_bar.dart';
import '../widgets/general_notification_tile.dart';
import '../widgets/group_notification_tile.dart';
import '../widgets/notification_empty_state.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedTab = 0;
  final NotificationController controller = Get.put(NotificationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('알림', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'read_all') controller.markAllAsRead();
              else if (value == 'delete_all') controller.deleteAllNotifications();
            },
            icon: const Icon(Icons.more_vert, color: Colors.black),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'read_all', child: Text('전체 읽음')),
              const PopupMenuItem(value: 'delete_all', child: Text('알림 전체 삭제', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          NotificationTabBar(
            selectedTab: _selectedTab,
            onTabChanged: (i) => setState(() => _selectedTab = i),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF4DB56C)));
              }
              return _selectedTab == 0 ? const _GeneralListView() : const _GroupListView();
            }),
          ),
        ],
      ),
    );
  }
}

// 공통 리스트 아이템 빌더 (스와이프 UI 적용)
Widget _buildSwipeableTile({
  required dynamic item,
  required Widget tileWidget,
  required Function(dynamic) onDelete,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Slidable(
      key: Key(item.notificationId.toString()),
      // 우측에서 좌측으로 밀었을 때(end) 액션 메뉴가 나타납니다.
      endActionPane: ActionPane(
        motion: const ScrollMotion(), // 자연스럽게 밀려오는 애니메이션
        extentRatio: 0.25, // 휴지통이 차지하는 너비 비율 (화면의 25%)
        children: [
          CustomSlidableAction(
            onPressed: (context) => onDelete(item.notificationId),
            backgroundColor: Colors.transparent, // 기본 배경 투명하게
            padding: const EdgeInsets.only(left: 8, right: 16),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFDEAEA), // 연한 핑크/레드 배경
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFE57373), // 차분한 레드 아이콘
                size: 28,
              ),
            ),
          ),
        ],
      ),
      child: tileWidget,
    ),
  );
}

class _GeneralListView extends StatelessWidget {
  const _GeneralListView();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    return Obx(() {
      final items = controller.generalNotifications;
      if (items.isEmpty) return const NotificationEmptyState(message: '일반 알림이 없습니다.');

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 30),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildSwipeableTile(
          item: items[i],
          tileWidget: GeneralNotificationTile(item: items[i]),
          onDelete: (id) => controller.deleteNotification(id),
        ),
      );
    });
  }
}

class _GroupListView extends StatelessWidget {
  const _GroupListView();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    return Obx(() {
      final items = controller.groupNotifications;
      if (items.isEmpty) return const NotificationEmptyState(message: '그룹 알림이 없습니다.');

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 30),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildSwipeableTile(
          item: items[i],
          tileWidget: GroupNotificationTile(item: items[i]),
          onDelete: (id) => controller.deleteNotification(id),
        ),
      );
    });
  }
}