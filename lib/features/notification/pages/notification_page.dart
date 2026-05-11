import 'package:flutter/material.dart';
// ▼ 아래 import 경로들의 "../" 가 에러를 해결하는 핵심입니다!
import '../models/notification_item.dart';
import '../widgets/notification_tab_bar.dart';
import '../widgets/general_notification_tile.dart';
import '../widgets/group_notification_tile.dart';
import '../widgets/notification_empty_state.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedTab = 0; // 0: 일반, 1: 그룹

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kNotifTextDark, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          _selectedTab == 0 ? '알림' : '그룹 알림',
          style: const TextStyle(
            color: kNotifTextDark,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kNotifBorder),
        ),
      ),
      body: Column(
        children: [
          // ── 탭 바 ──
          NotificationTabBar(
            selectedTab: _selectedTab,
            onTabChanged: (i) => setState(() => _selectedTab = i),
          ),
          // ── 콘텐츠 ──
          Expanded(
            child: _selectedTab == 0
                ? const _GeneralListView()
                : const _GroupListView(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 일반 알림 리스트 뷰
// ─────────────────────────────────────────
class _GeneralListView extends StatelessWidget {
  const _GeneralListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = generalNotificationDummies;

    if (items.isEmpty) {
      return const NotificationEmptyState(message: '일반 알림이 없습니다.');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 30),
      itemCount: items.length,
      itemBuilder: (_, i) => GeneralNotificationTile(item: items[i]),
    );
  }
}

// ─────────────────────────────────────────
// 그룹 알림 리스트 뷰
// ─────────────────────────────────────────
class _GroupListView extends StatelessWidget {
  const _GroupListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = groupNotificationDummies;

    if (items.isEmpty) {
      return const NotificationEmptyState(message: '그룹 알림이 없습니다.');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 30),
      itemCount: items.length,
      itemBuilder: (_, i) => GroupNotificationTile(item: items[i]),
    );
  }
}