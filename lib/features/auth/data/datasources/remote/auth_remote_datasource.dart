import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/api/api_client.dart';
import 'package:rentora/core/api/api_endpoints.dart';
import 'package:rentora/features/auth/data/datasources/auth_datasource.dart';
import 'package:rentora/features/auth/data/models/auth_api_model.dart';

// Provider for remote data source - uses the ApiClient with auth interceptor
final authRemoteDatasourceProvider = Provider<IAuthRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient.dio);
});

// Implementation
class AuthRemoteDataSourceImpl implements IAuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  String _resolveDioMessage(DioException e, String fallback) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Cannot reach server. Verify backend is running and API_BASE_URL is correct.';
    }

    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }

  @override
  Future<AuthApiModel> register(
    AuthApiModel user, {
    String? roleName,
    String? confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'name': user.name,
          'email': user.email,
          'password': user.password,
          if (confirmPassword != null && confirmPassword.isNotEmpty)
            'confirmPass': confirmPassword,
          if (roleName != null) 'roleName': roleName,
        },
      );

      return AuthApiModel.fromJson(response.data['user'] ?? response.data);
    } on DioException catch (e) {
      debugPrint('Registration Error: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      throw Exception(_resolveDioMessage(e, 'Registration failed'));
    }
  }

  @override
  Future<AuthApiModel?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      // Backend returns: { success, token, data: user }
      // We need to merge token into the user object
      final userData = response.data['data'] ?? response.data;
      final token = response.data['token'];

      // Add token to the user data before parsing
      if (userData is Map<String, dynamic>) {
        userData['token'] = token;
        return AuthApiModel.fromJson(userData);
      }

      return AuthApiModel.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('Login Error: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      throw Exception(_resolveDioMessage(e, 'Login failed'));
    }
  }

  @override
  Future<AuthApiModel?> getUserById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.userById(id));
      return AuthApiModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get user');
    }
  }

  @override
  Future<AuthApiModel?> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.profile);
      final userData = response.data['data'] ?? response.data;

      debugPrint('Profile data received: $userData');
      debugPrint('ProfilePicture field: ${userData['profilePicture']}');

      return AuthApiModel.fromJson(userData);
    } on DioException catch (e) {
      debugPrint('Get Current User Error: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      throw Exception(_resolveDioMessage(e, 'Failed to get current user'));
    }
  }

  @override
  Future<bool> logOut() async {
    try {
      await _dio.post('auth/logout');
      return true;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Logout failed');
    }
  }

  @override
  Future<String> uploadPhoto(File photo) async {
    try {
      FormData formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: photo.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        'auth/upload-photo',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return response.data['data']['photoUrl'] ?? '';
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Photo upload failed');
    }
  }

  @override
  Future<AuthApiModel?> getUserByEmail(String email) async {
    try {
      final response = await _dio.get('auth/user-by-email/$email');
      return AuthApiModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get user');
    }
  }

  @override
  Future<bool> updateUser(AuthApiModel user) async {
    try {
      await _dio.put('auth/user/${user.id}', data: user.toJson());
      return true;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update user');
    }
  }

  @override
  Future<bool> deleteUser(String authId) async {
    try {
      await _dio.delete('auth/user/$authId');
      return true;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete user');
    }
  }
}
