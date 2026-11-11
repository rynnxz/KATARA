import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:katara/features/culture/article_detail_screen.dart';
import 'package:katara/features/culture/collection_screen.dart';
import 'package:katara/features/culture/culture_screen.dart';
import 'package:katara/features/culture/jawi_screen.dart';
import 'package:katara/features/dev/dev_gallery_screen.dart';
import 'package:katara/features/dialect_comparison/dialect_comparison_screen.dart';
import 'package:katara/features/dictionary/dictionary_screen.dart';
import 'package:katara/features/lesson/lesson_result_screen.dart';
import 'package:katara/features/lesson/lesson_screen.dart';
import 'package:katara/features/lesson/level_up_screen.dart';
import 'package:katara/features/onboarding/onboarding_screen.dart';
import 'package:katara/features/onboarding/splash_screen.dart';
import 'package:katara/features/path_map/home_shell_screen.dart';
import 'package:katara/features/path_map/learn_map_screen.dart';
import 'package:katara/features/path_map/unit_detail_screen.dart';
import 'package:katara/features/practice/conversation_practice_screen.dart';
import 'package:katara/features/practice/practice_screen.dart';
import 'package:katara/features/practice/pronunciation_guide_screen.dart';
import 'package:katara/features/profile/profile_screen.dart';
import 'package:katara/features/quests/quests_screen.dart';
import 'package:katara/features/region_picker/region_picker_screen.dart';
import 'package:katara/features/settings/about_screen.dart';
import 'package:katara/features/settings/settings_screen.dart';
import 'package:katara/features/shop/shop_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (!kDebugMode && state.matchedLocation.startsWith('/dev')) {
        return '/home/learn';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/region',
        builder: (context, state) => const RegionPickerScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShellScreen(
          currentLocation: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/home/learn',
            builder: (context, state) => const LearnMapScreen(),
          ),
          GoRoute(
            path: '/home/practice',
            builder: (context, state) => const PracticeScreen(),
          ),
          GoRoute(
            path: '/home/culture',
            builder: (context, state) => const CultureScreen(),
          ),
          GoRoute(
            path: '/home/quests',
            builder: (context, state) => const QuestsScreen(),
          ),
          GoRoute(
            path: '/home/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/unit/:id',
        builder: (context, state) => UnitDetailScreen(
          unitId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/lesson/:id',
        builder: (context, state) => LessonScreen(
          lessonId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/lesson/:id/result',
        builder: (context, state) => LessonResultScreen(
          lessonId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/levelup',
        builder: (context, state) => const LevelUpScreen(),
      ),
      GoRoute(
        path: '/dictionary',
        builder: (context, state) => const DictionaryScreen(),
      ),
      GoRoute(
        path: '/jawi',
        builder: (context, state) => const JawiScreen(),
      ),
      GoRoute(
        path: '/article/:id',
        builder: (context, state) => ArticleDetailScreen(
          articleId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/collection',
        builder: (context, state) => const CollectionScreen(),
      ),
      GoRoute(
        path: '/shop',
        builder: (context, state) => const ShopScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/dialect-comparison',
        builder: (context, state) => const DialectComparisonScreen(),
      ),
      GoRoute(
        path: '/practice/conversation',
        builder: (context, state) => const ConversationPracticeScreen(),
      ),
      GoRoute(
        path: '/practice/pronunciation',
        builder: (context, state) => const PronunciationGuideScreen(),
      ),
      if (kDebugMode)
        GoRoute(
          path: '/dev/gallery',
          builder: (context, state) => const DevGalleryScreen(),
        ),
    ],
  );
});
