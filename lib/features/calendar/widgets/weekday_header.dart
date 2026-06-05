import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';

class WeekdayHeader extends StatelessWidget {
  const WeekdayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}