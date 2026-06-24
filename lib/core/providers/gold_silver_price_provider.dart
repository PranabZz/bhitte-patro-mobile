import 'dart:convert';

import 'package:bhitte_patro/core/models/gold_silver/gold_silver_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final goldSilverProvider = FutureProvider<List<GoldSilverResponse>>((
  ref,
) async {
  final response = await http.get(
    Uri.parse(
      'https://raw.githubusercontent.com/PranabZz/gold-silver/main/rates.json',
    ),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to load gold silver rates');
  }

  final List<dynamic> jsonList = jsonDecode(response.body);

  return jsonList
      .map(
        (item) => GoldSilverResponse.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList();
});
