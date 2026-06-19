import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_font_size.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/router/route_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bhitte_patro/core/consts/app_space.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.white),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.medium),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              index: 0,
              route: RoutePage.home,
              icon: FaIcon(FontAwesomeIcons.house, size: AppFontSize.large),
              label: 'Home',
            ),
            _buildNavItem(
              context: context,
              index: 1,
              route: RoutePage.schedule,
              icon: FaIcon(
                FontAwesomeIcons.calendarDays,
                size: AppFontSize.large,
              ),
              label: 'Schedule',
            ),
            _buildNavItem(
              context: context,
              index: 2,
              route: RoutePage.news,
              icon: FaIcon(FontAwesomeIcons.newspaper, size: AppFontSize.large),
              label: 'News',
            ),
            _buildNavItem(
              context: context,
              index: 3,
              route: RoutePage.profile,
              icon: FaIcon(FontAwesomeIcons.user, size: AppFontSize.large),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String route,
    required FaIcon icon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;

    // Determine colors based on selection state
    final Color iconColor = isSelected ? AppColors.black : Colors.grey;
    final Color labelColor = isSelected ? AppColors.darkBlue : Colors.grey;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!isSelected && route.isNotEmpty) {
          context.go(route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconTheme(
            data: IconThemeData(color: iconColor),
            child: icon,
          ),
          const SizedBox(height: AppSpace.small),
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: labelColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
