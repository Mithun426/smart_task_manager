import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/app_exception.dart';
import 'api_constants.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    responseType: ResponseType.json,
  ));

  dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
    error: true,
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onError: (DioException e, handler) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.unknown) {
        throw NetworkException("Connection failed. Please check your internet.");
      }
      if (e.response != null) {
        throw ServerException(
            "Server returned an error: ${e.response?.statusCode} ${e.response?.statusMessage}");
      }
      handler.next(e);
    },
  ));

  return dio;
});
