import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/task_repository.dart';
import '../domain/task.dart';

final tasksControllerProvider = AsyncNotifierProvider<TasksController, List<Task>>(() {
  return TasksController();
});

class TasksController extends AsyncNotifier<List<Task>> {
  TaskRepository get _repository => ref.read(taskRepositoryProvider);
  bool _hasMore = true;
  int _skip = 0;
  final int _limit = 10;
  String _searchQuery = '';
  String _filter = 'All'; // All, Completed, Pending
  String _sort = 'Due Date'; // Due Date, Priority, Created Date

  List<Task> _allLoadedTasks = [];

  @override
  Future<List<Task>> build() async {
    _skip = 0;
    _hasMore = true;
    _allLoadedTasks = [];
    return _fetchTasks();
  }

  Future<List<Task>> _fetchTasks() async {
    final tasks = await _repository.getTasks(skip: _skip, limit: _limit);
    if (tasks.length < _limit) {
      _hasMore = false;
    }
    _skip += tasks.length;
    _allLoadedTasks.addAll(tasks);
    return _applyClientFilters(_allLoadedTasks);
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    state = const AsyncLoading();
    try {
      final tasks = await _repository.getTasks(skip: _skip, limit: _limit);
      if (tasks.length < _limit) {
        _hasMore = false;
      }
      _skip += tasks.length;
      _allLoadedTasks.addAll(tasks);
      state = AsyncData(_applyClientFilters(_allLoadedTasks));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    _skip = 0;
    _hasMore = true;
    _allLoadedTasks.clear();
    state = const AsyncLoading();
    try {
      state = AsyncData(await _fetchTasks());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _reapplyFilters();
  }

  void setFilter(String filter) {
    _filter = filter;
    _reapplyFilters();
  }

  void setSort(String sort) {
    _sort = sort;
    _reapplyFilters();
  }

  void _reapplyFilters() {
    state = AsyncData(_applyClientFilters(_allLoadedTasks));
  }

  List<Task> _applyClientFilters(List<Task> tasks) {
    var result = List<Task>.from(tasks);
    
    // Filter
    if (_filter == 'Completed') {
      result = result.where((t) => t.isCompleted).toList();
    } else if (_filter == 'Pending') {
      result = result.where((t) => !t.isCompleted).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      result = result.where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Sort
    result.sort((a, b) {
      if (_sort == 'Due Date') {
        return a.dueDate.compareTo(b.dueDate);
      } else if (_sort == 'Priority') {
        return _priorityWeight(b.priority).compareTo(_priorityWeight(a.priority));
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });

    return result;
  }

  int _priorityWeight(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return 3;
      case 'medium': return 2;
      case 'low': return 1;
      default: return 0;
    }
  }

  Future<void> addTask(Task task) async {
    _allLoadedTasks.insert(0, task); // Optimistic
    _reapplyFilters();
    try {
      final created = await _repository.addTask(task);
      final index = _allLoadedTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _allLoadedTasks[index] = created; // Update with actual
      }
      _reapplyFilters();
    } catch (e) {
      _allLoadedTasks.removeWhere((t) => t.id == task.id); // Rollback
      _reapplyFilters();
      throw Exception('Failed to add task: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    final oldTaskIndex = _allLoadedTasks.indexWhere((t) => t.id == task.id);
    if (oldTaskIndex == -1) return;
    
    final oldTask = _allLoadedTasks[oldTaskIndex];
    _allLoadedTasks[oldTaskIndex] = task; // Optimistic
    _reapplyFilters();
    try {
      final updated = await _repository.updateTask(task);
      _allLoadedTasks[oldTaskIndex] = updated;
      _reapplyFilters();
    } catch (e) {
      _allLoadedTasks[oldTaskIndex] = oldTask; // Rollback
      _reapplyFilters();
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String id) async {
    final oldTaskIndex = _allLoadedTasks.indexWhere((t) => t.id == id);
    if (oldTaskIndex == -1) return;
    
    final oldTask = _allLoadedTasks.removeAt(oldTaskIndex); // Optimistic
    _reapplyFilters();
    try {
      await _repository.deleteTask(id);
    } catch (e) {
      _allLoadedTasks.insert(oldTaskIndex, oldTask); // Rollback
      _reapplyFilters();
      throw Exception('Failed to delete task: $e');
    }
  }
}
