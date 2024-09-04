import 'package:timecop/global_key.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import './constants.dart';
import 'screens/about/AboutScreen.dart';
import 'screens/dashboard/DashboardScreen.dart';
import 'screens/export/ExportScreen.dart';
import 'screens/projects/ProjectsScreen.dart';
import 'screens/reports/ReportsScreen.dart';
import 'screens/settings/SettingsScreen.dart';

// final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {

  static final GoRouter _router = GoRouter(
    initialLocation: Routes.dashboardNamedPage,
    debugLogDiagnostics: true,
    navigatorKey: navigatorKey,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        // builder: (context, state, child) {
        //   return BlocProvider(
        //     create: (context) => NavigationCubit(),
        //     child: MainScreen(screen: child),
        //   );
        // },
        routes: [
          GoRoute(
            path: Routes.dashboardNamedPage,
            pageBuilder: (context, state) =>
            const NoTransitionPage(
              child: DashboardScreen(),
            ),
            routes: [
              GoRoute(
                path: Routes.homeDetailsNamedPage,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.projectsNamedPage,
            pageBuilder: (context, state) =>
            const NoTransitionPage(
              child: ProjectsScreen(),
            ),
            routes: [
              GoRoute(
                path: Routes.profileDetailsNamedPage,
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.exportNamedPage,
            pageBuilder: (context, state) =>
            const NoTransitionPage(
              child: ExportScreen(),
            ),
          ),
          GoRoute(
            path: Routes.settingsNamedPage,
            pageBuilder: (context, state) =>
            NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: Routes.aboutNamedPage,
            pageBuilder: (context, state) =>
            const NoTransitionPage(
              child: AboutScreen(),
            ),
          ),
          // This solution doesn't make sense. It is just using a dialog as a page.
          // GoRoute(
          //   path: Routes.settingsNamedPage,
          //   builder: (context, state) => const ProfileScreen(),
          //   pageBuilder: (context, state) {
          //     return CustomTransitionPage<vorid>(
          //       key: state.pageKey,
          //       child: const ProfileScreen(), // Current page
          //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
          //         return Stack(
          //           children: [
          //             child,
          //             AlertDialogWidget(), // Dialog on top of the current page
          //           ],
          //         );
          //       },
          //     );
          //   },
          // ),
        ],
      ),
    ],
    // errorBuilder: (context, state) => const NotFoundScreen(),

  );

  static GoRouter get router => _router;
}

class AlertDialogWidget extends StatelessWidget {
  const AlertDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dialog'),
      content: const Text('This is a dialog'),
      actions: [
        TextButton(
          onPressed: () {
            // Close the dialog and navigate back to the previous route
            context.pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
