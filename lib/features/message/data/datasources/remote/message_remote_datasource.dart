import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/api/api_client.dart';
import 'package:rentora/core/api/api_endpoints.dart';

final messageRemoteDataSourceProvider = Provider<MessageRemoteDataSource>((
  ref,
) {
  final dio = ref.read(apiClientProvider).dio;
  return MessageRemoteDataSource(dio);
});

class MessageRemoteDataSource {
  final Dio _dio;
  MessageRemoteDataSource(this._dio);

  Future<List<dynamic>> getConversations() async {
    final res = await _dio.get(ApiEndpoints.conversationList);
    final data = res.data;
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return <dynamic>[];
  }

  Future<Map<String, dynamic>> getConversation(String id) async {
    final res = await _dio.get(ApiEndpoints.conversationGet(id));
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final res = await _dio.post(
      ApiEndpoints.conversationSendMessage(conversationId),
      data: {'conversationId': conversationId, 'content': content},
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createConversation({
    required List<String> participants,
  }) async {
    final res = await _dio.post(
      ApiEndpoints.conversationCreate,
      data: {'participants': participants},
    );
    return (res.data as Map).cast<String, dynamic>();
  }
}
