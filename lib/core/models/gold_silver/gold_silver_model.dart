class GoldSilverRates {
  final String fineGold9999;
  final String silver;

  GoldSilverRates({required this.fineGold9999, required this.silver});

  factory GoldSilverRates.fromJson(Map<String, dynamic> json) {
    return GoldSilverRates(
      fineGold9999: json['fine_gold_9999']?.toString() ?? '',
      silver: json['silver']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'fine_gold_9999': fineGold9999, 'silver': silver};
  }
}

class GoldSilverResponse {
  final String source;
  final String currency;
  final String unit;
  final GoldSilverRates rates;
  final String timestamp;

  GoldSilverResponse({
    required this.source,
    required this.currency,
    required this.unit,
    required this.rates,
    required this.timestamp,
  });

  factory GoldSilverResponse.fromJson(Map<String, dynamic> json) {
    return GoldSilverResponse(
      source: json['source']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      rates: GoldSilverRates.fromJson(
        Map<String, dynamic>.from(json['rates'] ?? {}),
      ),
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'currency': currency,
      'unit': unit,
      'rates': rates.toJson(),
      'timestamp': timestamp,
    };
  }

  static List<GoldSilverResponse> listFromJson(List<dynamic> json) {
    return json
        .map((e) => GoldSilverResponse.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
