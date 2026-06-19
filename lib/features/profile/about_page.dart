import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_font_size.dart';
import 'package:bhitte_patro/core/consts/app_space.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'About Bhitte Patro',
          style: AppTypography.boldTitle.copyWith(color: AppColors.black),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.large,
          vertical: AppSpace.large,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpace.medium),
            
            // App Logo
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpace.medium),
                child: Image.asset(
                  'assets/logo.png',
                  width: AppFontSize.xxxLarge * 3, // 96.0
                  height: AppFontSize.xxxLarge * 3, // 96.0
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.large),
            
            // App Title
            Text(
              'Bhitte Patro',
              style: AppTypography.boldTitle.copyWith(
                fontSize: AppFontSize.xxLarge,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: AppSpace.small),
            
            // Version Info
            Text(
              'Version 1.1.0',
              style: AppTypography.boldBody.copyWith(
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: AppSpace.extraLarge),
            
            // Description Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.medium),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.grey),
                borderRadius: BorderRadius.circular(AppSpace.medium),
              ),
              child: Text(
                'Bhitte Patro is a modern, feature-rich Nepali calendar, scheduling, and news aggregator application built with Flutter. It provides a traditional Bikram Sambat calendar, event management, local notifications, Google Calendar syncing, and curated news articles.',
                textAlign: TextAlign.justify,
                style: AppTypography.body.copyWith(
                  fontSize: AppFontSize.medium,
                  color: AppColors.black,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.extraLarge),
            
            // Features Header
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Key Features',
                style: AppTypography.boldSubtitle.copyWith(
                  color: AppColors.lightBlue,
                  fontSize: AppFontSize.large,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.medium),
            
            // Feature List Items
            _buildFeatureItem(
              Icons.calendar_month,
              'Bikram Sambat Calendar',
              'Traditional Nepali calendar view with local holidays, festivals, and events.',
            ),
            _buildFeatureItem(
              Icons.sync,
              'Google Calendar Integration',
              'Synchronize your tasks and reminders with Google Calendar automatically.',
            ),
            _buildFeatureItem(
              Icons.public,
              'Interactive Globe View',
              'Visualize Earth orbits, sun-moon angles, and tracking metrics in 3D/2D.',
            ),
            _buildFeatureItem(
              Icons.light_mode,
              'Astronomical Solar times',
              'Access real-time sunrise and sunset coordinates computed locally.',
            ),
            _buildFeatureItem(
              Icons.newspaper,
              'Scraped News Portal',
              'Stay updated with aggregated headlines and article summaries from online sources.',
            ),
            
            const SizedBox(height: AppSpace.extraLarge),
            const Divider(color: AppColors.grey),
            const SizedBox(height: AppSpace.medium),
            
            // Copyright
            Text(
              'Copyright © 2026 Bhitte Patro. All rights reserved.',
              style: AppTypography.caption.copyWith(
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: AppSpace.large),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.darkBlue,
            size: AppFontSize.xLarge,
          ),
          const SizedBox(width: AppSpace.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.boldBody.copyWith(
                    fontSize: AppFontSize.medium,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: AppSpace.extraExtraSmall),
                Text(
                  description,
                  style: AppTypography.body.copyWith(
                    color: AppColors.black,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
