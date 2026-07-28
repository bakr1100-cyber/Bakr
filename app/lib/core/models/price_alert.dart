class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.origin,
    required this.destination,
    required this.maxPrice,
    required this.currentPrice,
    required this.currency,
  });

  final String id;
  final String origin;
  final String destination;
  final double maxPrice;
  final double currentPrice;
  final String currency;

  bool get isTriggered => currentPrice <= maxPrice;
}
