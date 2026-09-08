// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Task _$TaskFromJson(Map<String, dynamic> json) => _Task(
  id: json['id'].toString(),
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  priority: json['priority'] as String,
  category: json['category'] as String,
  dueDate: DateTime.parse(json['due_date'] as String),
  isCompleted: json['is_completed'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$TaskToJson(_Task instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'priority': instance.priority,
  'category': instance.category,
  'due_date': instance.dueDate.toIso8601String(),
  'is_completed': instance.isCompleted,
  'created_at': instance.createdAt.toIso8601String(),
};
