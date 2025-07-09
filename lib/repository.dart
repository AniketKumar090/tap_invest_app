import 'package:http/http.dart' as http;
import 'dart:convert';

class TapInvestRepository {
  // Fixed: Removed trailing spaces from URLs
  final String _listOfBondsApi = 'https://eol122duf9sy4de.m.pipedream.net';
  final String _detailOfBondsApi = 'https://eo61q3zd4heiwke.m.pipedream.net';

  Future<List<dynamic>> fetchBondList() async {
    try {
      final response = await http.get(Uri.parse(_listOfBondsApi));
      print('API Response Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Fetched Data: $responseData');
        
        // Extract the data array from the response
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final data = responseData['data'];
          return data is List ? data : [];
        }
        
        // Fallback if data is already a list
        return responseData is List ? responseData : [];
      } else {
        throw Exception('Failed to load bonds: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bond list: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchBondDetails(String isin) async {
    try {
      final response = await http.get(Uri.parse('$_detailOfBondsApi?isin=$isin'));
      print('API Response Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Fetched Details: $data');
        return data is Map<String, dynamic> ? data : {};
      } else {
        throw Exception('Failed to load bond details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bond details: $e');
      rethrow;
    }
  }
}