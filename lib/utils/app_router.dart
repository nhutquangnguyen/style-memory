import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/clients/home_screen.dart';
import '../screens/clients/add_client_screen.dart';
import '../screens/clients/client_profile_screen.dart';
import '../screens/simple_photo_notes_screen.dart';
import '../screens/visits/visit_details_screen.dart';
import '../screens/gallery/gallery_screen.dart';
import '../screens/loved_styles/loved_styles_screen.dart';
import '../screens/settings_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.isAuthenticated;
      final isAuthRoute = state.fullPath?.startsWith('/auth') == true ||
          state.fullPath == '/welcome';

      // If user is not authenticated and trying to access protected route
      if (!isAuthenticated && !isAuthRoute) {
        return '/welcome';
      }

      // If user is authenticated and trying to access auth routes
      if (isAuthenticated && isAuthRoute) {
        return '/clients';
      }

      return null; // No redirect needed
    },
    routes: [
      // Welcome and Auth routes
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),

      // Main app routes with shell navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationShell(child: child);
        },
        routes: [
          // Clients route
          GoRoute(
            path: '/clients',
            name: 'clients',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add_client',
                builder: (context, state) => const AddClientScreen(),
              ),
              GoRoute(
                path: ':clientId',
                name: 'client_profile',
                builder: (context, state) {
                  final clientId = state.pathParameters['clientId']!;
                  return ClientProfileScreen(clientId: clientId);
                },
                routes: [
                  GoRoute(
                    path: 'capture',
                    name: 'capture_photos',
                    builder: (context, state) {
                      final clientId = state.pathParameters['clientId']!;
                      // Find the client from the provider
                      final clientsProvider = Provider.of<ClientsProvider>(context, listen: false);
                      final client = clientsProvider.clients.firstWhere((c) => c.id == clientId);
                      return SimplePhotoNotesScreen(client: client);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Loved Styles route
          GoRoute(
            path: '/loved-styles',
            name: 'loved_styles',
            builder: (context, state) => const LovedStylesScreen(),
          ),

          // Settings route
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Other routes that don't use bottom navigation
      GoRoute(
        path: '/visits/:visitId',
        name: 'visit_details',
        builder: (context, state) {
          final visitId = state.pathParameters['visitId']!;
          return VisitDetailsScreen(visitId: visitId);
        },
      ),
      // Full gallery accessible from settings
      GoRoute(
        path: '/gallery',
        name: 'gallery',
        builder: (context, state) => const GalleryScreen(),
      ),
    ],
  );
}

// Shell widget for bottom navigation
class MainNavigationShell extends StatelessWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const MainBottomNavigation(),
    );
  }
}

class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).fullPath;

    int selectedIndex = 0;
    if (currentRoute?.startsWith('/clients') == true) {
      selectedIndex = 0; // Clients tab
    } else if (currentRoute == '/loved-styles') {
      selectedIndex = 1; // Loved Styles tab
    } else if (currentRoute?.startsWith('/settings') == true) {
      selectedIndex = 2;
    }

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.goNamed('clients');
            break;
          case 1:
            context.go('/loved-styles');
            break;
          case 2:
            context.goNamed('settings');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Clients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Loved Styles',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}

