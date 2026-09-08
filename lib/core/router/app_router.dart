import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/tasks/presentation/task_form_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/tasks/domain/task.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isAuth = FirebaseAuth.instance.currentUser != null;

  final router = GoRouter(
    initialLocation: isAuth ? '/tasks' : '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TasksScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const TaskFormScreen(),
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final task = state.extra as Task;
              return TaskFormScreen(task: task);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );

  ref.listen(
    authControllerProvider,
    (previous, next) {
      if (next.isLoading) return;
      
      final isAuthenticated = next.value != null;
      // Get current path to avoid unnecessary navigation
      final currentPath = router.routerDelegate.currentConfiguration.uri.toString();
      
      if (isAuthenticated) {
        if (currentPath == '/login' || currentPath == '/register') {
          router.go('/tasks');
        }
      } else {
        if (currentPath != '/login' && currentPath != '/register') {
          router.go('/login');
        }
      }
    },
  );

  return router;
});

