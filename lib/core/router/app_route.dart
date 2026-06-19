import 'package:bhitte_patro/core/router/auth_refresh_listenable.dart';
import 'package:bhitte_patro/core/router/route_page.dart';
import 'package:bhitte_patro/features/auth/login_page.dart';
import 'package:bhitte_patro/features/home/home_page.dart';
import 'package:bhitte_patro/features/news/news_detail_page.dart';
import 'package:bhitte_patro/features/news/news_page.dart';
import 'package:bhitte_patro/features/profile/profile_page.dart';
import 'package:bhitte_patro/features/profile/date_conversion_page.dart';
import 'package:bhitte_patro/features/profile/about_page.dart';
import 'package:bhitte_patro/features/schedule/schedule_page.dart';
import 'package:bhitte_patro/shared/layout/main_layout.dart';
import 'package:bhitte_patro/features/globe/globe_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class AppRoute {
  static final GoRouter router = GoRouter(
    initialLocation: RoutePage.home,
    refreshListenable: AuthRefreshListenable(),
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final loggingIn = state.matchedLocation == RoutePage.login;
      final accessingProtected = state.matchedLocation == RoutePage.schedule || state.matchedLocation == RoutePage.profile;

      if (user == null && accessingProtected && !loggingIn) return RoutePage.login;
      if (user != null && loggingIn) return RoutePage.home;
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePage.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePage.globe,
        builder: (context, state) => const GlobePage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          int index = 0;
          if (state.matchedLocation == RoutePage.schedule) {
            index = 1;
          } else if (state.matchedLocation == RoutePage.news) {
            index = 2;
          } else if (state.matchedLocation == RoutePage.profile) {
            index = 3;
          }
          return MainLayout(index: index, child: child);
        },
        routes: [
          GoRoute(
            path: RoutePage.home,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomePage(),
            ),
          ),
          GoRoute(
            path: RoutePage.schedule,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SchedulePage(),
            ),
          ),
          GoRoute(
            path: RoutePage.news,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const NewsPage(),
            ),
          ),
          GoRoute(
            path: RoutePage.profile,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfilePage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: RoutePage.newsDetail,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return NewsDetailPage(
            url: extras['url'] as String,
            title: extras['title'] as String,
          );
        },
      ),
      GoRoute(
        path: RoutePage.dateConversion,
        builder: (context, state) => const DateConversionPage(),
      ),
      GoRoute(
        path: RoutePage.about,
        builder: (context, state) => const AboutPage(),
      ),
    ],
  );
}
