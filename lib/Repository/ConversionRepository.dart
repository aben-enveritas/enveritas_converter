import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

abstract class ConversionRepository {
  final String apiUrl;
  final String localStorageKey;
  final String assetPath;

  ConversionRepository(this.apiUrl, this.localStorageKey, this.assetPath);

  Future<Map<String, dynamic>> fetchConversionRules() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(response.body));
        await _saveToLocal(data);
        return data;
      } else {
        throw Exception('Failed to load conversion rules');
      }
    } catch (e) {
      print("E: "+ e.toString());
      return await _loadFromLocalOrAssets();
    }
  }

  Future<void> _saveToLocal(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(localStorageKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>> _loadFromLocalOrAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(localStorageKey);
    if (savedData != null && savedData.isNotEmpty) {
      return Map<String, dynamic>.from(jsonDecode(savedData));
    } else {
      final data = await rootBundle.loadString(assetPath);
      return Map<String, dynamic>.from(jsonDecode(data));
    }
  }
}