import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../domain/task.dart';
import 'tasks_controller.dart';
import '../../../core/widgets/styled_dropdown.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'Medium';
  String _category = 'Work';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descController.text = widget.task!.description;
      _priority = widget.task!.priority;
      _category = widget.task!.category;
      _dueDate = widget.task!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        category: _category,
        dueDate: _dueDate,
        isCompleted: widget.task?.isCompleted ?? false,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
      );

      try {
        if (widget.task == null) {
          ref.read(tasksControllerProvider.notifier).addTask(task);
        } else {
          ref.read(tasksControllerProvider.notifier).updateTask(task);
        }
        context.pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add Task'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete Task?'),
                    content: const Text('Are you sure you want to delete this task?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    await ref.read(tasksControllerProvider.notifier).deleteTask(widget.task!.id);
                    if (context.mounted) context.pop();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting task: $e')),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Task Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
                validator: (v) => v!.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48.0),
                    child: Icon(Icons.description_rounded),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 36),
              const Text('Classification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StyledDropdown(
                      label: 'Priority',
                      value: _priority,
                      icon: Icons.flag_rounded,
                      items: const ['Low', 'Medium', 'High'],
                      isDark: isDark,
                      onChanged: (v) => setState(() => _priority = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StyledDropdown(
                      label: 'Category',
                      value: _category,
                      icon: Icons.category_rounded,
                      items: const ['Work', 'Personal', 'Shopping', 'Health', 'Other'],
                      isDark: isDark,
                      onChanged: (v) => setState(() => _category = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Text('Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Due Date', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMM d, yyyy').format(_dueDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                ),
                child: Text(
                  isEditing ? 'Update Task' : 'Create Task',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
