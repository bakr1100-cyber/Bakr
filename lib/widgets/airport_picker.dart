import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/airport.dart';

class AirportPicker extends StatelessWidget {
  const AirportPicker({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.icon = Icons.flight_takeoff_rounded,
    this.compact = false,
  });

  final String label;
  final List<Airport> options;
  final Airport? selected;
  final ValueChanged<Airport> onChanged;
  final IconData icon;

  /// Tighter layout for side-by-side placement (e.g. "Von" | "Nach" sharing
  /// a row): drops the prefix icon and shows the airport code as a small
  /// line under the city instead of a trailing badge, so it never has to
  /// squeeze both onto one cramped line.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _openPicker(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: compact ? null : Icon(icon, color: theme.colorScheme.primary),
          ),
          child: selected == null
              ? Text(
                  AppLocalizations.of(context).t('selectPlaceholder'),
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                )
              : compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selected!.city,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          selected!.code,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected!.city,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _CodeBadge(code: selected!.code),
                      ],
                    ),
        ),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AirportSheet(
        title: label,
        options: options,
        selected: selected,
        onChanged: onChanged,
      ),
    );
  }
}

class _AirportSheet extends StatefulWidget {
  const _AirportSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<Airport> options;
  final Airport? selected;
  final ValueChanged<Airport> onChanged;

  @override
  State<_AirportSheet> createState() => _AirportSheetState();
}

class _AirportSheetState extends State<_AirportSheet> {
  final _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.options
        : widget.options
            .where((a) =>
                a.city.toLowerCase().contains(q) ||
                a.code.toLowerCase().contains(q) ||
                a.country.toLowerCase().contains(q))
            .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _queryController,
                    autofocus: false,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).t('airportSearchHint'),
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        AppLocalizations.of(context)
                            .t('noMatchForQuery')
                            .replaceAll('{query}', _query),
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final airport = filtered[index];
                        final isSelected = airport == widget.selected;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.moroccoGreen
                                : theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                            child: Text(
                              airport.code.substring(0, 2),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Text(
                            airport.city,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(_countryLabel(context, airport.country)),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                              : _CodeBadge(code: airport.code),
                          onTap: () {
                            widget.onChanged(airport);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// [Airport.country] is stored as a fixed German string internally (it also
/// doubles as an identifier elsewhere, e.g. `origin.country != 'Deutschland'`
/// in [FlightSearchService]) - this maps it to the localized display label
/// instead of showing that raw German value regardless of app language.
String _countryLabel(BuildContext context, String rawCountry) {
  final t = AppLocalizations.of(context).t;
  return switch (rawCountry) {
    'Deutschland' => t('countryGermany'),
    'Niederlande' => t('countryNetherlands'),
    'Belgien' => t('countryBelgium'),
    'Frankreich' => t('countryFrance'),
    'Spanien' => t('countrySpain'),
    'Portugal' => t('countryPortugal'),
    'Italien' => t('countryItaly'),
    'Marokko' => t('countryMorocco'),
    _ => rawCountry,
  };
}
