import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/local_storage/hive_storage_service.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/task.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    ref.watch(dioProvider),
    ref.watch(authRepositoryProvider),
  );
});

class TaskRepository {
  final Dio _dio;
  final AuthRepository _authRepository;
  final _connectivity = Connectivity();

  TaskRepository(this._dio, this._authRepository);

  String? get _userId => _authRepository.currentUser?.uid;

  Future<bool> _isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<List<Task>> getTasks({int skip = 0, int limit = 10}) async {
    if (_userId == null) throw AuthException("User not logged in");

    final isConnected = await _isConnected();
    if (!isConnected) {
      final tasksJson = HiveStorageService.tasksBox.get('tasks_$_userId');
      if (tasksJson != null) {
        final List<dynamic> decoded = jsonDecode(tasksJson);
        return decoded.map((e) => Task.fromJson(e)).toList();
      }
      return [];
    }

    try {
      final response = await _dio.get(
        ApiConstants.tasksEndpoint,
        queryParameters: {
          'user_id': _userId,
          'skip': skip,
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data is List ? response.data : response.data['data'] ?? [];
      final tasks = data.map((e) => Task.fromJson(e)).toList();
      
      if (skip == 0) {
        await HiveStorageService.tasksBox.put('tasks_$_userId', jsonEncode(data));
      }
      return tasks;
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to fetch tasks');
    }
  }

  Future<Task> addTask(Task task) async {
    if (_userId == null) throw AuthException("User not logged in");
    try {
      final response = await _dio.post(
        ApiConstants.tasksEndpoint,
        queryParameters: {'user_id': _userId},
        data: task.toJson()..remove('id'),
      );
      final responseData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return Task.fromJson(responseData);
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to add task');
    }
  }

  Future<Task> updateTask(Task task) async {
    if (_userId == null) throw AuthException("User not logged in");
    try {
      final response = await _dio.put(
        '${ApiConstants.tasksEndpoint}${task.id}',
        queryParameters: {'user_id': _userId},
        data: task.toJson(),
      );
      final responseData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return Task.fromJson(responseData);
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to update task');
    }
  }

  Future<void> deleteTask(String id) async {
    if (_userId == null) throw AuthException("User not logged in");
    try {
      await _dio.delete(
        '${ApiConstants.tasksEndpoint}$id',
        queryParameters: {'user_id': _userId},
      );
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Failed to delete task');
    }
  }
}
