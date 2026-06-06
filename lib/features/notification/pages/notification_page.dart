import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
  final NotificationController controller = Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    // 페이지 열릴 때마다 새로 fetch (onInit은 앱 시작 시 로그인 전에 실행됨)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshNotificationPage();
    });
  }

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
              else if (value == 'delete_all') {
                final category = _selectedTab == 0 ? 'GENERAL' : 'GROUP';
                controller.deleteAllByCategory(category);
              }
            },
            icon: const Icon(Icons.more_vert, color: Colors.black),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'read_all', child: Text('전체 읽음')),
              PopupMenuItem(
                value: 'delete_all',
                child: Text(
                  '${_selectedTab == 0 ? '일반' : '그룹'} 알림 전체 삭제',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final category = _selectedTab == 0 ? 'GENERAL' : 'GROUP';
          await controller.fetchNotifications(category: category);
          await controller.fetchUnreadCount();
        },
        child: Column(
          children: [
            NotificationTabBar(
              selectedTab: _selectedTab,
              onTabChanged: (i) => setState(() => _selectedTab = i),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                return _selectedTab == 0 ? const _GeneralListView() : const _GroupListView();
              }),
            ),
          ],
        ),
      ),
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
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.22,
        children: [
          CustomSlidableAction(
            onPressed: (context) => onDelete(item.notificationId),
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFDEAEA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      // ✅ 겉포장지의 GestureDetector를 깔끔하게 제거하고 tileWidget만 남겼습니다!
      // (터치 로직은 이제 General/Group 타일 내부의 InkWell이 완벽하게 처리합니다)
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
        padding: const EdgeInsets.only(bottom: 16),
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
        padding: const EdgeInsets.only(bottom: 16),
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