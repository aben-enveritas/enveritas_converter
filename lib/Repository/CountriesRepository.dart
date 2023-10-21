import 'dart:convert';
import 'package:http/http.dart' as http;

class CountriesRepository {
  Future<List<String>> fetchCountries() async {
    final countriesApiUrl = "https://raw.githubusercontent.com/aben-enveritas/enveritas_conversion_rules/main/countries.json";
    final response = await http.get(Uri.parse(countriesApiUrl));
    if (response.statusCode == 200) {
      List<dynamic> countriesList = jsonDecode(response.body);
      return countriesList.cast<String>();
    } else {
      throw Exception('Failed to load countries');
    }
  }
}