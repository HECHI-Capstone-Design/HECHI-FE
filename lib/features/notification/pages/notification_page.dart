import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_tab_bar.dart';
import '../widgets/general_notification_tile.dart';
import '../widgets/group_notification_tile.dart';
import '../widgets/notification_empty_state.dart';

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
        itemBuilder: (_, i) => GeneralNotificationTile(item: items[i]),
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
        itemBuilder: (_, i) => GroupNotificationTile(item: items[i]),
      );
    });
  }
}