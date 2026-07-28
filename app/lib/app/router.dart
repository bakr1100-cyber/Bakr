import 'package:go_router/go_router.dart';

import '../features/ai_assistant/presentation/ai_assistant_screen.dart';
import '../features/flight_search/presentation/flight_search_screen.dart';
import '../features/price_alerts/presentation/price_alerts_screen.dart';
import '../features/travel_companion/presentation/travel_companion_screen.dart';
import 'main_shell.dart';

/// 4 top-level destinations behind a bottom navigation shell. Flight search
/// is the default/home tab so it's reachable in the fewest taps.
final appRouter = GoRouter(
  initialLocation: '/search',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/search',
          builder: (context, state) => const FlightSearchScreen(),
        ),
        GoRoute(
          path: '/assistant',
          builder: (context, state) => const AiAssistantScreen(),
        ),
        GoRoute(
          path: '/companion',
          builder: (context, state) => const TravelCompanionScreen(),
        ),
        GoRoute(
          path: '/alerts',
          builder: (context, state) => const PriceAlertsScreen(),
        ),
      ],
    ),
  ],
);
