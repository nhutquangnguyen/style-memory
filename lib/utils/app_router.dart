import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import '../l10n/app_localizations.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/home_screen.dart';
import '../screens/clients/clients_screen.dart';
import '../screens/clients/add_client_screen.dart';
import '../screens/clients/edit_client_screen.dart';
import '../screens/clients/client_profile_screen.dart';
import '../screens/simple_photo_notes_screen.dart';
import '../screens/visits/visit_details_screen.dart';
import '../screens/visits/edit_visit_screen.dart';
import '../screens/gallery/gallery_screen.dart';
import '../screens/loved_styles/loved_styles_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/staff/staff_list_screen.dart';
import '../screens/staff/staff_visit_history_screen.dart';
import '../screens/services/service_list_screen.dart';

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
        return '/home';
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
          // Home route - main landing page
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Clients route
          GoRoute(
            path: '/clients',
            name: 'clients',
            builder: (context, state) => const ClientsScreen(),
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

          // Staff management routes
          GoRoute(
            path: '/staff',
            name: 'staff_list',
            builder: (context, state) => const StaffListScreen(),
          ),

          // Staff visit history (with bottom navigation)
          GoRoute(
            path: '/staff/:staffId/visits',
            name: 'staff_visit_history',
            builder: (context, state) {
              final staffId = state.pathParameters['staffId']!;
              return StaffVisitHistoryScreen(staffId: staffId);
            },
          ),

          // Services route (with bottom navigation)
          GoRoute(
            path: '/services',
            name: 'services',
            builder: (context, state) => const ServiceListScreen(),
          ),

          // Settings route (with bottom navigation)
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
      // Edit client route
      GoRoute(
        path: '/clients/:clientId/edit',
        name: 'edit_client',
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          return EditClientScreen(clientId: clientId);
        },
      ),
      // Edit visit route
      GoRoute(
        path: '/visits/:visitId/edit',
        name: 'edit_visit',
        builder: (context, state) {
          final visitId = state.pathParameters['visitId']!;
          return EditVisitScreen(visitId: visitId);
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
class MainNavigationShell extends StatefulWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  @override
  void initState() {
    super.initState();
    // Initialize providers when main navigation initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  Future<void> _initializeProviders() async {
    // Small delay to ensure main navigation is fully settled
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if widget is still mounted before using context
    if (!mounted) return;

    // Initialize stores provider first (needed for store data)
    try {
      final storesProvider = context.read<StoresProvider>();
      if (!storesProvider.hasStores && !storesProvider.isLoading) {
        await storesProvider.initialize();
        debugPrint('StoresProvider initialized successfully');
      }
    } catch (e) {
      debugPrint('Failed to initialize StoresProvider: $e');
    }

    // Preload Loved Styles data in background without blocking UI
    if (mounted) {
      LovedStylesScreen.preloadLovedStylesData(context).catchError((e) {
        debugPrint('Background preload failed: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: const MainBottomNavigation(),
    );
  }
}

class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentRoute = GoRouterState.of(context).fullPath;

    int selectedIndex = 0;
    if (currentRoute?.startsWith('/home') == true) {
      selectedIndex = 0; // Home tab
    } else if (currentRoute?.startsWith('/clients') == true) {
      selectedIndex = 1; // Clients tab
    } else if (currentRoute == '/loved-styles') {
      selectedIndex = 2; // Loved Styles tab
    }

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.goNamed('home');
            break;
          case 1:
            context.goNamed('clients');
            break;
          case 2:
            context.goNamed('loved_styles');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people),
          label: l10n.clients,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.favorite),
          label: l10n.lovedStyles,
        ),
      ],
    );
  }
}

