import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String note;
  final DateTime date;
  final TaskPriority priority;
  final DateTime? reminder;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    this.priority = TaskPriority.medium,
    this.reminder,
    this.isCompleted = false,
  });

  Color get priorityColor {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  String get priorityText {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'date': date.toIso8601String(),
      'priority': priority.index,
      'reminder': reminder?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      note: json['note'] as String,
      date: DateTime.parse(json['date'] as String),
      priority: TaskPriority.values[json['priority'] as int],
      reminder: json['reminder'] != null ? DateTime.parse(json['reminder'] as String) : null,
      isCompleted: json['isCompleted'] as bool,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? date,
    TaskPriority? priority,
    DateTime? reminder,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      reminder: reminder ?? this.reminder,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
} 