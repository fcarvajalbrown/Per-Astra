/// Application routing (ADR-004, go_router).
///
/// The route map mirrors ADR-004. The lesson player's internal step flow
/// (multiple-choice -> write-a-prompt) is driven by Riverpod state, not by
/// nested routes, keeping the router flat and readable.
library;

import 'package:go_router/go_router.dart';

import '../screens/badge_screen.dart';
import '../screens/certificate_screen.dart';
import '../screens/lesson_complete_screen.dart';
import '../screens/lesson_player/lesson_player_screen.dart';
import '../screens/module_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/skill_tree_screen.dart';

/// Named route identifiers, used with `context.goNamed` / `pushNamed`.
class AppRoutes {
  AppRoutes._();

  static const String skillTree = 'skillTree';
  static const String module = 'module';
  static const String lesson = 'lesson';
  static const String lessonComplete = 'lessonComplete';
  static const String badge = 'badge';
  static const String certificate = 'certificate';
  static const String settings = 'settings';
}

/// The app's single [GoRouter] instance.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: AppRoutes.skillTree,
      builder: (context, state) => const SkillTreeScreen(),
    ),
    GoRoute(
      path: '/module/:moduleId',
      name: AppRoutes.module,
      builder: (context, state) => ModuleDetailScreen(
        moduleId: state.pathParameters['moduleId']!,
      ),
    ),
    GoRoute(
      path: '/module/:moduleId/lesson/:lessonId',
      name: AppRoutes.lesson,
      builder: (context, state) => LessonPlayerScreen(
        moduleId: state.pathParameters['moduleId']!,
        lessonId: state.pathParameters['lessonId']!,
      ),
    ),
    GoRoute(
      path: '/lesson-complete',
      name: AppRoutes.lessonComplete,
      builder: (context, state) => const LessonCompleteScreen(),
    ),
    GoRoute(
      path: '/badge/:badgeId',
      name: AppRoutes.badge,
      builder: (context, state) => BadgeScreen(
        badgeId: state.pathParameters['badgeId']!,
      ),
    ),
    GoRoute(
      path: '/certificate',
      name: AppRoutes.certificate,
      builder: (context, state) => const CertificateScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
