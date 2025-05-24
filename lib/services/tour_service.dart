import 'dart:convert';
import '../models/tour_models.dart';
import 'api_service.dart';

class TourService {
  final ApiService _api = ApiService();

  Future<TourListResponse> getTours({
    String? searchTerm,
    String? location,
    String? category,
    String? difficultyLevel,
    String? activityType,
    double? minPrice,
    double? maxPrice,
    int? minDuration,
    int? maxDuration,
    String? sortBy,
    bool ascending = false,
    int pageIndex = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (searchTerm != null && searchTerm.isNotEmpty)
        queryParams['searchTerm'] = searchTerm;
      if (location != null && location.isNotEmpty)
        queryParams['location'] = location;
      if (category != null && category.isNotEmpty)
        queryParams['category'] = category;
      if (difficultyLevel != null && difficultyLevel.isNotEmpty)
        queryParams['difficultyLevel'] = difficultyLevel;
      if (activityType != null && activityType.isNotEmpty)
        queryParams['activityType'] = activityType;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (minDuration != null)
        queryParams['minDuration'] = minDuration.toString();
      if (maxDuration != null)
        queryParams['maxDuration'] = maxDuration.toString();
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
      queryParams['ascending'] = ascending.toString();
      queryParams['pageIndex'] = pageIndex.toString();
      queryParams['pageSize'] = pageSize.toString();

      final response = await _api.get('/tours', queryParams: queryParams);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TourListResponse.fromJson(data);
      } else {
        throw Exception('Failed to load tours');
      }
    } catch (e) {
      throw Exception('Error fetching tours: $e');
    }
  }

  Future<Tour> getTourById(int id) async {
    try {
      final response = await _api.get('/tours/$id');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Tour.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Tour not found');
      } else {
        throw Exception('Failed to load tour');
      }
    } catch (e) {
      throw Exception('Error fetching tour: $e');
    }
  }

  Future<TourListResponse> searchTours({
    required Map<String, dynamic> searchCriteria,
    int pageIndex = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = {
        'pageIndex': pageIndex.toString(),
        'pageSize': pageSize.toString(),
      };

      final response = await _api.post(
        '/tours/search?${Uri(queryParameters: queryParams).query}',
        body: searchCriteria,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TourListResponse.fromJson(data);
      } else {
        throw Exception('Failed to search tours');
      }
    } catch (e) {
      throw Exception('Error searching tours: $e');
    }
  }
}
