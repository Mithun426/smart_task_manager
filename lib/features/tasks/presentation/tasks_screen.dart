import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'tasks_controller.dart';
import '../domain/task.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/widgets/styled_dropdown.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  String _selectedFilter = 'All';
  String _selectedSort = 'Due Date';
  
  bool _isFilterBarVisible = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOffline = result.contains(ConnectivityResult.none);
      });
    });
    
    Connectivity().checkConnectivity().then((result) {
      setState(() {
        _isOffline = result.contains(ConnectivityResult.none);
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(tasksControllerProvider.notifier).loadMore();
    }
    
    if (_scrollController.position.pixels > _lastScrollPosition + 15) {
      if (_isFilterBarVisible) setState(() => _isFilterBarVisible = false);
      _lastScrollPosition = _scrollController.position.pixels;
    } else if (_scrollController.position.pixels < _lastScrollPosition - 15) {
      if (!_isFilterBarVisible) setState(() => _isFilterBarVisible = true);
      _lastScrollPosition = _scrollController.position.pixels;
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(tasksControllerProvider.notifier).setSearchQuery(query);
    });
  }

  IconData _filterIcon(String filter) {
    switch (filter) {
      case 'Completed': return Icons.check_circle_outline;
      case 'Pending': return Icons.radio_button_unchecked;
      default: return Icons.filter_list_rounded;
    }
  }

  IconData _sortIcon(String sort) {
    switch (sort) {
      case 'Priority': return Icons.flag_outlined;
      case 'Created Date': return Icons.access_time;
      default: return Icons.calendar_today_outlined;
    }
  }

  String _getFriendlyErrorMessage(String error) {
    final lowerError = error.toLowerCase();
    if (lowerError.contains('connection') || lowerError.contains('timeout') || lowerError.contains('unavailable')) {
      return 'We couldn\'t connect to the server. Please check your internet connection and try again.';
    } else if (lowerError.contains('auth')) {
      return 'There was an issue with your account. Please log in again.';
    }
    return 'We encountered an unexpected error while loading your tasks. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              if (_isOffline)
                Container(
                  color: Colors.red.shade400,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Text(
                    'Offline Mode',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: Icon(Icons.search),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(tasksControllerProvider.notifier).refresh(),
            child: tasksState.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No tasks found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              itemCount: tasks.length + (tasksState.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == tasks.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final task = tasks[index];
                return TaskCard(task: task);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.red),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Oops! Connection Failed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getFriendlyErrorMessage(err.toString()),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(tasksControllerProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              offset: _isFilterBarVisible ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: StyledDropdown(
                        label: 'Filter',
                        value: _selectedFilter,
                        icon: _filterIcon(_selectedFilter),
                        items: const ['All', 'Completed', 'Pending'],
                        isDark: isDark,
                        openUpward: true,
                        onChanged: (val) {
                          setState(() => _selectedFilter = val);
                          ref.read(tasksControllerProvider.notifier).setFilter(val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StyledDropdown(
                        label: 'Sort',
                        value: _selectedSort,
                        icon: _sortIcon(_selectedSort),
                        items: const ['Due Date', 'Priority', 'Created Date'],
                        isDark: isDark,
                        openUpward: true,
                        onChanged: (val) {
                          setState(() => _selectedSort = val);
                          ref.read(tasksControllerProvider.notifier).setSort(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(bottom: _isFilterBarVisible ? 90.0 : 24.0),
        child: FloatingActionButton(
          onPressed: () => context.push('/tasks/add'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}


class TaskCard extends ConsumerWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color priorityColor;
    switch (task.priority.toLowerCase()) {
      case 'high': priorityColor = Colors.red; break;
      case 'medium': priorityColor = Colors.orange; break;
      case 'low': priorityColor = Colors.green; break;
      default: priorityColor = Colors.grey;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
    
    String dateStr;
    Color dateColor;
    
    if (taskDate.isAtSameMomentAs(today)) {
      dateStr = 'Due Today';
      dateColor = Colors.red;
    } else if (taskDate.isAtSameMomentAs(tomorrow)) {
      dateStr = 'Due Tom';
      dateColor = Colors.red;
    } else {
      dateStr = DateFormat('MMM dd').format(task.dueDate);
      dateColor = Colors.grey.shade600;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/tasks/edit', extra: task),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (val) async {
                  if (val != null) {
                    final updated = task.copyWith(isCompleted: val);
                    try {
                      await ref.read(tasksControllerProvider.notifier).updateTask(updated);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Connection Error',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Failed to update. Please check your internet.',
                                      style: TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          elevation: 4,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
                shape: const CircleBorder(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.priority,
                            style: TextStyle(color: priorityColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.category,
                            style: const TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        if (!task.isCompleted) ...[
                          Icon(Icons.calendar_today, size: 14, color: dateColor),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12, 
                              color: dateColor,
                              fontWeight: dateColor == Colors.red ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (task.isCompleted)
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Image.asset(
                        'assets/icon/checklist.png',
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

