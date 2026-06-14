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
  late final PageController _pageController;
  final NotificationController controller = Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged(int i) {
    setState(() => _selectedTab = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
        child: Column(
          children: [
            NotificationTabBar(
              selectedTab: _selectedTab,
              onTabChanged: _onTabChanged,
            ),
            Expanded(
              // PageView를 Obx로 감싸지 않아서 isLoading 변화에도 페이지 위치 유지
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _selectedTab = i),
                children: const [
                  _GeneralListView(),
                  _GroupListView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 공통 스와이프 삭제 타일
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
              child: const Icon(Icons.delete_outline, color: AppColors.error, size: 28),
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
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await controller.fetchNotifications(category: 'GENERAL');
        await controller.fetchUnreadCount();
      },
      child: Obx(() {
        final items = controller.generalNotifications;
        // 초기 로딩 중 (아이템 없을 때만 스피너)
        if (controller.isLoadingGeneral.value && items.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (items.isEmpty) {
          return const CustomScrollView(
            slivers: [SliverFillRemaining(child: NotificationEmptyState(message: '일반 알림이 없습니다.'))],
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: items.length,
          itemBuilder: (_, i) => _buildSwipeableTile(
            item: items[i],
            tileWidget: GeneralNotificationTile(item: items[i]),
            onDelete: (id) => controller.deleteNotification(id),
          ),
        );
      }),
    );
  }
}

class _GroupListView extends StatelessWidget {
  const _GroupListView();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await controller.fetchNotifications(category: 'GROUP');
        await controller.fetchUnreadCount();
      },
      child: Obx(() {
        final items = controller.groupNotifications;
        if (controller.isLoadingGroup.value && items.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (items.isEmpty) {
          return const CustomScrollView(
            slivers: [SliverFillRemaining(child: NotificationEmptyState(message: '그룹 알림이 없습니다.'))],
          );
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: items.length,
          itemBuilder: (_, i) => _buildSwipeableTile(
            item: items[i],
            tileWidget: GroupNotificationTile(item: items[i]),
            onDelete: (id) => controller.deleteNotification(id),
          ),
        );
      }),
    );
  }
}
