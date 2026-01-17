import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/api/api_client.dart';
import 'package:rentora/core/api/api_endpoints.dart';
import 'package:rentora/core/services/storage/user_session_service.dart';
import 'package:rentora/features/auth/data/datasources/auth_datasource.dart';
import 'package:rentora/features/auth/data/models/auth_api_model.dart';

final authRemoteDatasourceProvider = Provider<IAuthRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final userSessionService = ref.read(userSessionServiceProvider);
  return AuthRemoteDatasource(
    apiClient: apiClient,
    userSessionService: userSessionService,
  );
});

class AuthRemoteDatasource implements IAuthRemoteDataSource {
  final ApiClient _apiClient;
  final UserSessionService _userSessionService;

  AuthRemoteDatasource({
    required ApiClient apiClient,
    required UserSessionService userSessionService,
  }) : _apiClient = apiClient,
       _userSessionService = userSessionService;

  @override
  Future<AuthApiModel> register(AuthApiModel user) async {
    try {
      final Map<String, dynamic> registrationData = user.toJson();
      registrationData['confirmPass'] = user.password;

      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: registrationData,
      );

      if (response.statusCode == 201) {
        final data = response.data['user'] as Map<String, dynamic>;
        return AuthApiModel.fromJson(data);
      } else {
        throw Exception("Failed to register: ${response.data['message']}");
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? e.message;
      throw Exception(errorMessage);
    }
  }

  @override
  Future<AuthApiModel?> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {"email": email, "password": password},
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        final userData = response.data['data'] as Map<String, dynamic>;
        final String token = response.data['token'];

        final user = AuthApiModel.fromJson(userData);

        await _userSessionService.saveUserSession(
          userId: user.id ?? '',
          email: user.email,
          name: user.name,
          token: token,
        );

        return user;
      }
      return null;
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? "Login failed";
      throw Exception(errorMessage);
    }
  }

  @override
  Future<AuthApiModel?> getUserById(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userById(id));

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return AuthApiModel.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception("Error fetching profile: $e");
    }
  }
}
