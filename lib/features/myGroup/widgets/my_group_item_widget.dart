import 'package:flutter/material.dart';
import '../models/group_model.dart';

class MyGroupItemWidget extends StatelessWidget {
  final GroupModel group;

  const MyGroupItemWidget({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300], // 임시 이미지 배경
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            group.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}