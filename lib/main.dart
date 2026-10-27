import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class Task {
  final int? id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  Task({
    this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  Task.fromMap(Map<String, dynamic> map)
    : id = map['id'] as int?,
      title = map['title'] as String,
      description = map['description'] as String?,
      dueDate = map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isCompleted = (map['isCompleted'] as int) == 1,
      createdAt = DateTime.parse(map['createdAt']);
}


class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    return openDatabase(
      p.join(await getDatabasesPath(), 'tasks_database.db'),
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE tasks(
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          title       TEXT,
          description TEXT,
          dueDate     DATETIME,
          isCompleted INTEGER,
          createdAt   DATETIME
        )
      '''),
      
    );
    
  }

  static Future<int> insertTask(Task task) async {
    final db = await database;
    return db.insert('tasks', task.toMap());
  }
  static Future<List<Task>> getTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'dueDate ASC');
    return maps.map((m) => Task.fromMap(m)).toList();
  }
  static Future<int> updateTask(Task task) async {
    if (task.id == null) return 0;
    final db = await database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }
  static Future<int> setTaskCompleted(int id, bool isCompleted) async {
    final db = await database;
    return db.update(
      'tasks',
      {'isCompleted': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  static Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}

ThemeData _buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6C4DF6),
    brightness: brightness,
  );

  final textColor = isDark ? Colors.white : const Color(0xFF241B52);
  final mutedColor = isDark ? Colors.white70 : const Color(0xFF5B5479);
  final hintColor = isDark ? Colors.white38 : const Color(0xFF8A83A6);
  final fieldFillColor = isDark ? Colors.white12 : Colors.white;
  final borderColor = isDark ? Colors.white38 : const Color(0xFFB7A9E8);

  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF3E2D88) : const Color(0xFFF4F1FF),
    appBarTheme: AppBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: textColor,
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: fieldFillColor,
      labelStyle: TextStyle(color: mutedColor),
      hintStyle: TextStyle(color: hintColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: borderColor),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.database;
  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(Brightness.light),
      darkTheme: _buildAppTheme(Brightness.dark),
      themeMode: _themeMode,
      home: AddTaskScreen(onToggleTheme: _toggleTheme),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({
    super.key,
    required this.onToggleTheme,
    this.taskToEdit,
  });

  final VoidCallback onToggleTheme;
  final Task? taskToEdit;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _dueDate = task.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: widget.taskToEdit == null ? DateTime.now() : DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    setState(() => _saving = true);

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final original = widget.taskToEdit;

    if (original != null) {
      final updatedTask = Task(
        id: original.id,
        title: title,
        description: description,
        dueDate: _dueDate,
        isCompleted: original.isCompleted,
        createdAt: original.createdAt,
      );

      await DatabaseHelper.updateTask(updatedTask);

      if (!mounted) return;

      Navigator.pop(context, true);
      return;
    }

    final task = Task(
      title: title,
      description: description,
      dueDate: _dueDate,
    );

    final id = await DatabaseHelper.insertTask(task);

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task saved! (id: $id)')),
      );
      _titleController.clear();
      _descriptionController.clear();
      setState(() => _dueDate = null);
    }
  }

  @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.taskToEdit == null ? 'Add Task' : 'Edit Task'),
          actions: [
            IconButton(
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onToggleTheme,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g. Buy groceries',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional details...',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    _dueDate == null
                        ? 'No due date'
                        : DateFormat('MMM dd, yyyy').format(_dueDate!),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pick Date'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        widget.taskToEdit == null
                            ? 'Add Task'
                            : 'Save Changes',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              if (widget.taskToEdit == null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskListScreen(
                          onToggleTheme: widget.onToggleTheme,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text(
                    'Show Current Tasks',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
  }
  class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;
 
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}
 
class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> _tasksFuture;
  bool _editMode = false;
 
  @override
  void initState() {
    super.initState();
    _tasksFuture = DatabaseHelper.getTasks();
  }
 void _reload() {
  setState(() {
    _tasksFuture = DatabaseHelper.getTasks();
  });
}

  Future<void> _editTask(Task task) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(
          onToggleTheme: widget.onToggleTheme,
          taskToEdit: task,
        ),
      ),
    );

    if (!mounted || changed != true) return;

    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task updated')),
    );
  }

  Future<void> _toggleCompleted(Task task) async {
    if (task.id == null) return;

    await DatabaseHelper.setTaskCompleted(task.id!, !task.isCompleted);

    if (!mounted) return;

    _reload();
  }

Future<void> _deleteTask(Task task) async {
  if (task.id == null) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete task?'),
      content: Text('Delete "${task.title}"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  await DatabaseHelper.deleteTask(task.id!);

  if (!mounted) return;

  _reload();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Deleted "${task.title}"')),
  );
}
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editMode ? 'Edit Tasks' : 'Current Tasks'),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
 
          final tasks = snapshot.data ?? [];
 
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    color: isDark ? Colors.white38 : Colors.black26,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tasks yet!\nAdd one from the previous screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 16,
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
              return Card(
                color: isDark ? Colors.white12 : Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: IconButton(
                    tooltip: task.isCompleted
                        ? 'Mark as incomplete'
                        : 'Mark as complete',
                    onPressed: () => _toggleCompleted(task),
                    icon: Icon(
                      task.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: task.isCompleted
                          ? (isDark ? Colors.greenAccent : Colors.green)
                          : (isDark ? Colors.white54 : Colors.black38),
                      size: 28,
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor:
                          isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        
                      ],
                      if (task.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: isDark ? Colors.white38 : Colors.black45,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Due ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}',
                              style: TextStyle(
                                color:
                                    isDark ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_editMode)
                        IconButton(
                          tooltip: 'Edit task',
                          icon: Icon(
                            Icons.edit_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => _editTask(task),
                        ),
                      IconButton(
                        tooltip: 'Delete task',
                        icon: Icon(
                          Icons.delete_outline,
                          color: isDark ? Colors.redAccent : Colors.red,
                        ),
                        onPressed: () => _deleteTask(task),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text(
                    'Back',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _editMode = !_editMode),
                  icon: Icon(_editMode ? Icons.check : Icons.edit_outlined),
                  label: Text(
                    _editMode ? 'Done' : 'Edit Tasks',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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