import 'package:intl/intl.dart';

import '../models/trip_leg.dart';

/// Turns "book this leg" into a real, commission-tracked outbound link
/// instead of an in-app checkout - this app has no payment processing or
/// airline/rail booking backend of its own, so revenue comes from routing
/// the user to book on a real travel-affiliate network's site, which pays
/// a commission when the booking completes there.
///
/// Configured for a self-serve network in the style of Travelpayouts
/// (free instant signup, no partner-approval gate, unlike Skyscanner or
/// Amadeus's now-defunct self-service program - see README). Travelpayouts
/// itself calls its affiliate id a "marker", and its flight brands (e.g.
/// Aviasales) accept deep links shaped like a normal search URL with the
/// marker appended as a query parameter - that's the shape
/// [defaultUrlTemplate] mirrors, but the template is fully configurable so
/// this can point at whichever specific program you actually join.
///
/// Only flight legs are monetized this way: there is no affiliate program
/// for ONCF/ICE wired in, so train legs get a plain link to the operator's
/// own site with no commission - see [officialBookingUrl].
class AffiliateService {
  const AffiliateService({
    this.marker = '',
    this.urlTemplate = defaultUrlTemplate,
  });

  /// Travelpayouts/Aviasales-shaped default: origin/destination as IATA
  /// codes, date as ddMMyy, one-way, marker appended for commission
  /// tracking. Pass a different template (e.g. via
  /// `--dart-define=AFFILIATE_URL_TEMPLATE=...` read in `app.dart`) to
  /// point this at a different program's link format.
  static const defaultUrlTemplate =
      'https://www.aviasales.com/search/{origin}{date}{destination}1?marker={marker}';

  /// Affiliate/tracking id ("marker" in Travelpayouts' terminology). Empty
  /// means no program has been configured yet - links still work, they
  /// just don't earn a commission until this is set.
  final String marker;
  final String urlTemplate;

  bool get isConfigured => marker.isNotEmpty;

  /// Commission-tracked booking link for a single flight leg. Works even
  /// when [isConfigured] is false (falls back to an un-tracked marker
  /// value), so the button is always useful, just not yet earning
  /// anything until you've joined a program and set a real marker.
  Uri affiliateBookingUrl(TripLeg leg) {
    assert(leg.mode == LegMode.flight, 'Only flight legs have affiliate links.');
    final dateCode = DateFormat('ddMMyy').format(leg.departure);
    final url = urlTemplate
        .replaceAll('{origin}', leg.from.code)
        .replaceAll('{destination}', leg.to.code)
        .replaceAll('{date}', dateCode)
        .replaceAll('{marker}', isConfigured ? marker : 'unconfigured');
    return Uri.parse(url);
  }

  /// Plain (non-commission) link to the operator's own booking site for a
  /// train leg - there's no rail affiliate program hooked up here.
  Uri officialBookingUrl(TripLeg leg) {
    assert(leg.mode == LegMode.train, 'Use affiliateBookingUrl for flights.');
    if (leg.carrier == 'ONCF') return Uri.parse('https://www.oncf-voyages.ma');
    if (leg.carrier == 'ICE') return Uri.parse('https://www.bahn.de');
    final query = Uri.encodeComponent('${leg.carrier} Zug ${leg.from.city} ${leg.to.city}');
    return Uri.parse('https://www.google.com/search?q=$query');
  }
}
