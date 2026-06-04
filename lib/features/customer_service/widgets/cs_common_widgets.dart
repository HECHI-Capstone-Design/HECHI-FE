import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';

// 상단 메뉴 버튼 (문의내역 / 문의등록)
class CsMenuButton extends StatelessWidget {
  final String text;
  final bool isFilled;
  final VoidCallback onTap;

  const CsMenuButton({
    Key? key,
    required this.text,
    required this.isFilled,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFilled ? AppColors.primary : Colors.white,
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isFilled ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// 검색바
class CsSearchBar extends StatelessWidget {
  const CsSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 45,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 10),
          Text('검색', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}