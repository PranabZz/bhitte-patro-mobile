import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_space.dart';
import 'package:flutter/material.dart';

class PillButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSelected;

  const PillButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.medium,
          vertical: AppSpace.small,
        ),
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: AppColors.darkBlue),
          color: isSelected ? AppColors.darkBlue : AppColors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.black,
          ),
        ),
      ),
    );
  }
}
