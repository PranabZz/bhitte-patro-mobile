import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_font_size.dart';
import 'package:bhitte_patro/core/consts/app_space.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/router/route_page.dart';
import 'package:bhitte_patro/features/gold_silver/gold_silver_page.dart';
import 'package:bhitte_patro/features/home/calendar/calendar_view.dart';
import 'package:bhitte_patro/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpace.medium),
                child: GreetingHeader(),
              ),
              Padding(
                padding: EdgeInsets.all(AppSpace.small),
                child: CalendarView(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning,';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon,';
    } else if (hour >= 17 && hour < 22) {
      return 'Good Evening,';
    } else {
      return 'Good Night,';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.when(
      data: (user) => user?.displayName?.split(' ').first ?? 'Guest',
      loading: () => '...',
      error: (error, stack) => 'Guest',
    );

    return Row(
      children: [
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Aligns text to the left
          children: [
            Text(
              _getGreeting(),
              style: AppTypography.boldTitle.copyWith(
                fontSize: AppFontSize.xLarge,
              ),
            ),
            Text(
              '$userName👋',
              style: AppTypography.subtitle.copyWith(
                fontSize: AppFontSize.large,
              ),
            ),
          ],
        ),
        const Spacer(),
        // IconButton(
        //   onPressed: () => context.push(RoutePage.globe),
        //   icon: const FaIcon(
        //     FontAwesomeIcons.satellite,
        //     size: AppFontSize.large,
        //     color: AppColors.lightBlue,
        //     fontWeight: FontWeight.normal,
        //   ),
        // ),
        GestureDetector(
          onTap: () => context.push(RoutePage.globe),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.medium),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent.withOpacity(0.1),
            ),
            child: SvgPicture.asset(
              'assets/satellite-4-svgrepo-com.svg',
              width: 26,
              height: 26,
              colorFilter: const ColorFilter.mode(
                AppColors.black,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
