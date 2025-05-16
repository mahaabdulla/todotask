import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/task_provider.dart';
import 'models/task.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ChangeNotifierProvider(
      create: (_) => TaskProvider(prefs),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Task Manager',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.task_alt),
                text: 'Active Tasks',
              ),
              Tab(
                icon: const Icon(Icons.check_circle),
                text: 'Completed Tasks',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TaskList(isCompleted: false),
            _TaskList(isCompleted: true),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showTaskDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Task'),
        ),
      ),
    );
  }

  void _showTaskDialog(BuildContext context, {Task? task}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final noteController = TextEditingController(text: task?.note ?? '');
    DateTime selectedDate = task?.date ?? DateTime.now();
    TaskPriority selectedPriority = task?.priority ?? TaskPriority.medium;
    DateTime? selectedReminder = task?.reminder;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          task == null ? 'Add New Task' : 'Edit Task',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Note',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                value: selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: const Icon(Icons.priority_high),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: priority == TaskPriority.low
                                ? Colors.green
                                : priority == TaskPriority.medium
                                    ? Colors.orange
                                    : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(priority.name.toUpperCase()),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedPriority = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          selectedDate = date;
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        DateFormat('yyyy-MM-dd').format(selectedDate),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          selectedReminder = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            time.hour,
                            time.minute,
                          );
                        }
                      },
                      icon: const Icon(Icons.alarm),
                      label: Text(
                        selectedReminder != null
                            ? DateFormat('HH:mm').format(selectedReminder!)
                            : 'Set Reminder',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final newTask = Task(
                  id: task?.id ?? const Uuid().v4(),
                  title: titleController.text,
                  note: noteController.text,
                  date: selectedDate,
                  priority: selectedPriority,
                  reminder: selectedReminder,
                  isCompleted: task?.isCompleted ?? false,
                );
                if (task == null) {
                  context.read<TaskProvider>().addTask(newTask);
                } else {
                  context.read<TaskProvider>().updateTask(newTask);
                }
                Navigator.pop(context);
              }
            },
            icon: Icon(task == null ? Icons.add_task : Icons.save),
            label: Text(task == null ? 'Add Task' : 'Save Changes'),
          ),
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final bool isCompleted;

  const _TaskList({required this.isCompleted});

  void _showTaskDialog(BuildContext context, {Task? task}) {
    final titleController = TextEditingController(text: task?.title ?? '');
    final noteController = TextEditingController(text: task?.note ?? '');
    DateTime selectedDate = task?.date ?? DateTime.now();
    TaskPriority selectedPriority = task?.priority ?? TaskPriority.medium;
    DateTime? selectedReminder = task?.reminder;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          task == null ? 'Add New Task' : 'Edit Task',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Note',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                value: selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: const Icon(Icons.priority_high),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: priority == TaskPriority.low
                                ? Colors.green
                                : priority == TaskPriority.medium
                                    ? Colors.orange
                                    : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(priority.name.toUpperCase()),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedPriority = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          selectedDate = date;
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        DateFormat('yyyy-MM-dd').format(selectedDate),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          selectedReminder = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            time.hour,
                            time.minute,
                          );
                        }
                      },
                      icon: const Icon(Icons.alarm),
                      label: Text(
                        selectedReminder != null
                            ? DateFormat('HH:mm').format(selectedReminder!)
                            : 'Set Reminder',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final newTask = Task(
                  id: task?.id ?? const Uuid().v4(),
                  title: titleController.text,
                  note: noteController.text,
                  date: selectedDate,
                  priority: selectedPriority,
                  reminder: selectedReminder,
                  isCompleted: task?.isCompleted ?? false,
                );
                if (task == null) {
                  context.read<TaskProvider>().addTask(newTask);
                } else {
                  context.read<TaskProvider>().updateTask(newTask);
                }
                Navigator.pop(context);
              }
            },
            icon: Icon(task == null ? Icons.add_task : Icons.save),
            label: Text(task == null ? 'Add Task' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = isCompleted ? taskProvider.completedTasks : taskProvider.tasks;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.check_circle_outline : Icons.task_alt,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted ? 'No completed tasks yet' : 'No tasks yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          onDismissed: (direction) {
            taskProvider.deleteTask(task.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Task "${task.title}" deleted'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    taskProvider.addTask(task);
                  },
                ),
              ),
            );
          },
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: task.priorityColor.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: task.priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      task.note,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('yyyy-MM-dd').format(task.date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (task.reminder != null) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.alarm,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('HH:mm').format(task.reminder!),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCompleted) ...[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showTaskDialog(context, task: task),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      color: Colors.green,
                      onPressed: () => taskProvider.completeTask(task.id),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
