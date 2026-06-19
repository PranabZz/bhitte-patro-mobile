import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/providers/auth_provider.dart';
import 'package:bhitte_patro/core/providers/calendar_provider.dart';
import 'package:bhitte_patro/core/providers/notification_provider.dart';
import 'package:bhitte_patro/core/router/route_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text("Not logged in"));
          }
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: user.photoURL != null
                        ? Image.network(
                            user.photoURL!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.person, size: 50, color: AppColors.darkBlue),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(user.displayName ?? 'No Name',
                    style: AppTypography.boldTitle.copyWith(fontSize: 20)),
              ),
              Center(
                child: Text(user.email ?? 'No Email',
                    style: AppTypography.body.copyWith(color: Colors.grey)),
              ),
              const SizedBox(height: 32),
              const Divider(),
              
              // Notification Settings Toggle Switch
              SwitchListTile(
                value: notificationsEnabled,
                onChanged: (val) {
                  ref.read(notificationsEnabledProvider.notifier).toggle(val);
                },
                title: const Text("Notification Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                secondary: const Icon(Icons.notifications_outlined, color: AppColors.darkBlue),
                activeColor: AppColors.darkBlue,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              
              // Date Conversion Tile (Navigates to new DateConversionPage)
              _buildListTile(
                Icons.calendar_today_outlined,
                "Date Conversion",
                onTap: () => context.push(RoutePage.dateConversion),
              ),

              // Language Tile
              _buildListTile(
                Icons.language_outlined,
                "Language",
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Icon(Icons.translate, size: 48, color: AppColors.darkBlue),
                            const SizedBox(height: 16),
                            const Text(
                              "Language",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Support for multiple languages (Nepali/English) will be available in a future update.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600], height: 1.4),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Got it", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              // About Tile showing version
              _buildListTile(
                Icons.info_outline,
                "About",
                subtitle: "Version 1.1.0",
                onTap: () => context.push(RoutePage.about),
              ),
              
              const Divider(),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                  },
                  child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text("Error loading profile")),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: AppColors.darkBlue),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey)) : null,
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
