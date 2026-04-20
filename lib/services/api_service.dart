// flutter_app/lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/application_model.dart';
// import '../models/prediction_result_model.dart';
import '../models/shap_explanation_model.dart';
import '../models/user_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = AppConstants.baseUrl;

  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${AppConstants.healthEndpoint}'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  // Create user
  Future<Map<String, dynamic>> createUser(UserModel user) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl${AppConstants.usersEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  // Submit credit application
  Future<Map<String, dynamic>> submitApplication(
    ApplicationModel application, 
    {String userId = 'anonymous'}
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl${AppConstants.applicationsEndpoint}')
          .replace(queryParameters: {'user_id': userId});
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(application.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to submit application: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error submitting application: $e');
    }
  }

  // Get user applications
  Future<List<Map<String, dynamic>>> getUserApplications(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${AppConstants.applicationsEndpoint}$userId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['applications'] ?? []);
      } else {
        throw Exception('Failed to get applications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting applications: $e');
    }
  }

  // Get explanation
  Future<ShapExplanation> getExplanation(String applicationId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl${AppConstants.explainEndpoint}$applicationId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return ShapExplanation.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get explanation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting explanation: $e');
    }
  }
}
