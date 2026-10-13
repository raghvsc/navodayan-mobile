import 'package:flutter/foundation.dart';
import '../models/offering.dart';
import 'api_client.dart';

class OfferingsService {
  final ApiClient _client;

  OfferingsService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<OfferingItem>> getOfferings({String? category, String? search}) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category.isNotEmpty && category != 'ALL') {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['q'] = search;
      }

      final queryStr = queryParams.isNotEmpty
          ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
          : '';

      final response = await _client.get('/offerings$queryStr');
      final list = (response['data'] as List<dynamic>?) ?? [];
      return list.map((e) => OfferingItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('OfferingsService.getOfferings error: $e');
      rethrow;
    }
  }

  Future<List<OfferingCategory>> getCategories() async {
    try {
      final response = await _client.get('/offerings/categories');
      final list = (response['data'] as List<dynamic>?) ?? [];
      return list.map((e) => OfferingCategory.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('OfferingsService.getCategories error: $e');
      return [
        const OfferingCategory(key: 'SERVICE', label: 'Service'),
        const OfferingCategory(key: 'HIRING', label: 'Hiring'),
        const OfferingCategory(key: 'PRODUCT', label: 'Product'),
        const OfferingCategory(key: 'PRACTICE', label: 'Practice'),
        const OfferingCategory(key: 'VOLUNTEER', label: 'Volunteer'),
        const OfferingCategory(key: 'OTHER', label: 'Other'),
      ];
    }
  }

  Future<Map<String, dynamic>> getMyOfferings() async {
    try {
      final response = await _client.get('/offerings/mine');
      return response['data'] is Map<String, dynamic> ? response['data'] : response;
    } catch (e) {
      debugPrint('OfferingsService.getMyOfferings error: $e');
      return {'offering': null, 'volunteers': []};
    }
  }

  Future<bool> saveMyOffering(Map<String, dynamic> data) async {
    try {
      await _client.put('/offerings/mine', data);
      return true;
    } catch (e) {
      debugPrint('OfferingsService.saveMyOffering error: $e');
      rethrow;
    }
  }

  Future<bool> expressInterest(String offeringId) async {
    try {
      await _client.post('/offerings/$offeringId/interest', {});
      return true;
    } catch (e) {
      debugPrint('OfferingsService.expressInterest error: $e');
      rethrow;
    }
  }
}
