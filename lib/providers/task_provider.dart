import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  List<Task> _tasks = [];
  List<Task> _completedTasks = [];

  TaskProvider(this._prefs) {
    _loadTasks();
  }

  List<Task> get tasks => _tasks;
  List<Task> get completedTasks => _completedTasks;

  void _loadTasks() {
    final tasksJson = _prefs.getStringList('tasks') ?? [];
    _tasks = tasksJson
        .map((json) => Task.fromJson(jsonDecode(_prefs.getString(json) ?? '{}')))
        .where((task) => !task.isCompleted)
        .toList();
    _completedTasks = tasksJson
        .map((json) => Task.fromJson(jsonDecode(_prefs.getString(json) ?? '{}')))
        .where((task) => task.isCompleted)
        .toList();
  }

  void _saveTasks() {
    final allTasks = [..._tasks, ..._completedTasks];
    final tasksJson = allTasks.map((task) => task.id).toList();
    _prefs.setStringList('tasks', tasksJson);
    for (var task in allTasks) {
      _prefs.setString(task.id, jsonEncode(task.toJson()));
    }
  }

  void addTask(Task task) {
    if (task.isCompleted) {
      _completedTasks.add(task);
    } else {
      _tasks.add(task);
    }
    _saveTasks();
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    if (updatedTask.isCompleted) {
      final taskIndex = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (taskIndex != -1) {
        _tasks.removeAt(taskIndex);
        _completedTasks.add(updatedTask);
      }
    } else {
      final taskIndex = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (taskIndex != -1) {
        _tasks[taskIndex] = updatedTask;
      }
    }
    _saveTasks();
    notifyListeners();
  }

  void completeTask(String taskId) {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      _tasks.removeAt(taskIndex);
      _completedTasks.add(task.copyWith(isCompleted: true));
      _saveTasks();
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    _completedTasks.removeWhere((task) => task.id == taskId);
    _prefs.remove(taskId);
    _saveTasks();
    notifyListeners();
  }

  void reorderTasks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final task = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, task);
    _saveTasks();
    notifyListeners();
  }
} 