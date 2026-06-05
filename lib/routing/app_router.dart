import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';

import '../features/admin/admin_bottom_nav.dart';
import '../features/admin/screens/admin_home_screen.dart';
import '../features/admin/screens/admin_users_screen.dart';
import '../features/admin/screens/admin_exhibitions_screen.dart';
import '../features/admin/screens/admin_exhibition_form_screen.dart';
import '../features/admin/screens/admin_booths_screen.dart';
import '../features/admin/screens/admin_booth_form_screen.dart';
import '../features/admin/screens/admin_applications_screen.dart';
import '../features/admin/screens/admin_booth_types_screen.dart';
import '../features/admin/providers/admin_provider.dart';

import '../features/organizer/providers/organizer_provider.dart';
import '../features/organizer/screens/organizer_home_screen.dart';
import '../features/organizer/screens/organizer_exhibitions_screen.dart';

import '../features/exhibitor/providers/exhibitor_provider.dart';
import '../features/exhibitor/screens/exhibitor_home_screen.dart';
import '../features/exhibitor/screens/my_applications_screen.dart';

import '../features/guest/screens/guest_home_screen.dart';
import '../features/guest/screens/guest_exhibition_detail_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final role = authProvider.userRole;
      final location = state.matchedLocation;

      // Redirect unauthenticated users away from protected routes
      if (!isLoggedIn &&
          (location.startsWith('/admin') ||
              location.startsWith('/organizer') ||
              location.startsWith('/exhibitor'))) {
        return '/login';
      }

      // Redirect authenticated users away from login/register/guest
      if (isLoggedIn &&
          (location == '/login' || location == '/register' || location == '/')) {
        if (role == 'admin') return '/admin';
        if (role == 'organizer') return '/organizer';
        return '/exhibitor';
      }

      return null;
    },
    routes: [
      // ── Guest ─────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const GuestHomeScreen(),
      ),

      // ── Auth ──────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Admin ─────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => AdminProvider(),
          child: const AdminHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => AdminProvider(),
          child: const AdminUsersScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/exhibitions',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => AdminProvider(),
          child: const AdminExhibitionsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/exhibitions/create',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => AdminProvider(),
          child: const AdminExhibitionFormScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/exhibitions/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChangeNotifierProvider(
            create: (_) => AdminProvider(),
            child: AdminExhibitionFormScreen(exhibitionId: id),
          );
        },
      ),
      GoRoute(
        path: '/admin/exhibitions/:id/booths',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChangeNotifierProvider(
            create: (_) => AdminProvider(),
            child: AdminBoothsScreen(exhibitionId: id),
          );
        },
      ),
      GoRoute(
        path: '/admin/exhibitions/:id/booths/create',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChangeNotifierProvider(
            create: (_) => AdminProvider(),
            child: AdminBoothFormScreen(exhibitionId: id),
          );
        },
      ),
      GoRoute(
        path: '/admin/applications',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => AdminProvider(),
          child: const AdminApplicationsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/booth-types',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => AdminProvider(),
          child: const AdminBoothTypesScreen(),
        ),
      ),

      // ── Exhibitor ─────────────────────────────────────────────
      GoRoute(
        path: '/exhibitor',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => ExhibitorProvider(),
          child: const ExhibitorHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/exhibitor/applications',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => ExhibitorProvider(),
          child: const MyApplicationsScreen(),
        ),
      ),

      // ── Organizer ─────────────────────────────────────────────
      GoRoute(
        path: '/organizer',
        builder: (context, state) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => OrganizerProvider()),
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: const OrganizerHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/organizer/exhibitions',
        builder: (context, state) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => OrganizerProvider()),
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: const OrganizerExhibitionsScreen(),
        ),
      ),
      GoRoute(
        path: '/organizer/applications',
        builder: (context, state) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => OrganizerProvider()),
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: const OrganizerExhibitionsScreen(showApplicationsHint: true),
        ),
      ),
    ],
  );
}