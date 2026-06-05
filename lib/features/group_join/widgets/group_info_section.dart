import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';

class GroupInfoSection extends StatelessWidget {
  final String memberCount;
  final String createdDate;
  final String masterNickname;
  final String groupName;

  const GroupInfoSection({
    Key? key,
    required this.memberCount,
    required this.createdDate,
    required this.masterNickname,
    required this.groupName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(memberCount, style: const TextStyle(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w500)),
              const Text('  ·  ', style: TextStyle(color: Colors.grey)),
              Text('개설일: $createdDate', style: const TextStyle(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w500)),
              const Text('  ·  ', style: TextStyle(color: Colors.grey)),
              Text(masterNickname, style: const TextStyle(fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            groupName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}