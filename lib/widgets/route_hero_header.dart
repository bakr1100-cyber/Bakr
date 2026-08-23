import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../models/airport.dart';
import 'city_hero_header.dart' show HeroPhotoFrame, heroImageForDestination;

/// The same photo-header treatment as [CityHeroHeader], reused on the
/// search-results screen: a back button in place of the AppBar's, and the
/// route ("Brussels -> Tangier") as the headline instead of a greeting -
/// added per direct feedback that every screen in the mockup carries this
/// header, not just the landing page.
class RouteHeroHeader extends StatelessWidget {
  const RouteHeroHeader({super.key, required this.origin, required this.destination});

  final Airport? origin;
  final Airport? destination;

  @override
  Widget build(BuildContext context) {
    return HeroPhotoFrame(
      image: heroImageForDestination(destination),
      height: 200,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackButton(onTap: () => Navigator.of(context).maybePop()),
              const Spacer(),
              Text(
                '${origin?.city ?? '?'} → ${destination?.city ?? '?'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: const [
                        Shadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 2)),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(side: BorderSide(color: Color(0x38FFFFFF))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(9),
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
