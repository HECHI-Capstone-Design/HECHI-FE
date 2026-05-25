import 'package:flutter/material.dart';
import 'package:hechi/features/groupcommunity/pages/group_post_list_view.dart';

class GroupFreeBoardView extends StatelessWidget {
  const GroupFreeBoardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const GroupPostListView(isMissionBoard: false);
  }
}