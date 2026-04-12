import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final saved = await LocalStorageService.loadTasks();
      setState(() {
        _tasks = saved.map((e) => Task.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to load tasks: $e')),
        );
      }
    }
  }

  Future<void> _saveTasks() async {
    await LocalStorageService.saveTasks(_tasks.map((e) => e.toJson()).toList());
  }

  void _addTask() {
    String title = '';
    String desc = '';
    DateTime scheduled = DateTime.now().add(const Duration(hours: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Task',
                style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                style: const TextStyle(color: AppTheme.white),
                decoration: const InputDecoration(labelText: 'Task Title'),
                onChanged: (v) => title = v,
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: AppTheme.white),
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (v) => desc = v,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text(
                  'Schedule Time',
                  style: TextStyle(color: AppTheme.whiteSecondary),
                ),
                subtitle: Text(
                  '${scheduled.day}/${scheduled.month}/${scheduled.year}  '
                  '${scheduled.hour}:${scheduled.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: AppTheme.white),
                ),
                trailing: const Icon(Icons.access_time_rounded,
                    color: AppTheme.primaryBlue),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: scheduled,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    if (!ctx.mounted) return;
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(scheduled),
                    );
                    if (time != null) {
                      setModalState(() => scheduled = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          ));
                    }
                  }
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (title.isEmpty) return;

                    final task = Task(
                      id: 'T-${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      description: desc,
                      scheduledTime: scheduled,
                    );

                    // Close sheet first, then save
                    Navigator.pop(ctx);

                    try {
                      setState(() => _tasks.add(task));
                      await _saveTasks();

                      // Schedule local notification for the task reminder
                      await NotificationService.scheduleTaskReminder(
                        id: task.id.hashCode,
                        title: '⏰ Task Reminder: ${task.title}',
                        body: task.description.isNotEmpty
                            ? task.description
                            : 'Your scheduled task is due now.',
                        scheduledTime: task.scheduledTime,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Task added & reminder scheduled!'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ Failed to save task: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('CREATE TASK'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTask(int index) async {
    final task = _tasks[index];
    try {
      setState(() => _tasks.removeAt(index));
      await _saveTasks();
      // Cancel the notification for this task
      await NotificationService.cancel(task.id.hashCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Task deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to delete task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('My Tasks')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    final completed = task.status == 'completed';
                    return Dismissible(
                      key: Key(task.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.danger,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteTask(index),
                      child: Opacity(
                        opacity: completed ? 0.6 : 1.0,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: ListTile(
                            title: Text(
                              task.title,
                              style: TextStyle(
                                color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                                decoration: completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              '${task.scheduledTime.day}/${task.scheduledTime.month}/${task.scheduledTime.year} '
                              'at ${task.scheduledTime.hour}:${task.scheduledTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  color: AppTheme.whiteTertiary, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                completed
                                    ? Icons.undo_rounded
                                    : Icons.check_circle_rounded,
                                color: completed
                                    ? AppTheme.whiteTertiary
                                    : AppTheme.success,
                              ),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  setState(() => task.status =
                                      completed ? 'pending' : 'completed');
                                  await _saveTasks();
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          completed
                                              ? '↩️ Task marked as pending'
                                              : '✅ Task completed!',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              '❌ Failed to update task: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt_rounded,
                size: 80, color: AppTheme.surfaceElevated),
            const SizedBox(height: 16),
            const Text('All clear!',
                style: TextStyle(color: AppTheme.white, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('No pending tasks. Tap + to add one.',
                style: TextStyle(color: AppTheme.whiteTertiary)),
          ],
        ),
      );
}
