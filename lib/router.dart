import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:template/config/supabase_config.dart';
import 'package:template/src/views/boards_view.dart';
import 'package:template/src/views/login_view.dart';
import 'package:template/src/views/register_view.dart';
import 'package:template/src/views/splash_view.dart';
import 'package:template/src/views/board_detail_view.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const SplashView(),
      ),
      redirect: (context, state) {
        final isAuthenticated = SupabaseConfig.client.auth.currentUser != null;
        if (isAuthenticated) {
          return '/boards';
        }
        return '/login';
      },
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const LoginView(),
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const RegisterView(),
      ),
    ),
    GoRoute(
      path: '/boards',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const BoardsView(),
      ),
      redirect: (context, state) {
        final isAuthenticated = SupabaseConfig.client.auth.currentUser != null;
        if (!isAuthenticated) {
          return '/login';
        }
        return null;
      },
    ),
    GoRoute(
      path: '/board/:id',
      pageBuilder: (context, state) {
        final boardId = state.pathParameters['id'] ?? '';
        return NoTransitionPage(
          child: BoardDetailView(boardId: boardId),
        );
      },
      redirect: (context, state) {
        final isAuthenticated = SupabaseConfig.client.auth.currentUser != null;
        if (!isAuthenticated) {
          return '/login';
        }
        return null;
      },
    ),
  ],
  redirect: (context, state) {
    final isAuthenticated = SupabaseConfig.client.auth.currentUser != null;
    final isGoingToLogin = state.matchedLocation == '/login';
    final isGoingToRegister = state.matchedLocation == '/register';
    
    if (!isAuthenticated && !isGoingToLogin && !isGoingToRegister) {
      return '/login';
    }
    
    if (isAuthenticated && (isGoingToLogin || isGoingToRegister)) {
      return '/boards';
    }
    
    return null;
  },
);