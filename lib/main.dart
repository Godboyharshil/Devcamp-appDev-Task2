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
  static Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
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
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AddTaskScreen(),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
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

    final task = Task(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
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
      const inputStyle = TextStyle(color: Colors.white);
      const labelStyle = TextStyle(color: Colors.white70);
      const fillColor  = Colors.white12;
  
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 62, 45, 136),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Add Task', style: TextStyle(color: Colors.white)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                style: inputStyle,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  labelStyle: labelStyle,
                  hintText: 'e.g. Buy groceries',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: fillColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                style: inputStyle,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: labelStyle,
                  hintText: 'Optional details...',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: fillColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    _dueDate == null
                        ? 'No due date'
                        : DateFormat('MMM dd, yyyy').format(_dueDate!),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    label: const Text('Pick Date',
                        style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Add Task', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TaskListScreen()),
                  );
                },
                icon: const Icon(Icons.list_alt, color: Colors.white),
                label: const Text(
                  'Show Current Tasks',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.white38),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
 
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}
 
class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> _tasksFuture;
 
  @override
  void initState() {
    super.initState();
    _tasksFuture = DatabaseHelper.getTasks();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 62, 45, 136),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Current Tasks',
            style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }
 
          final tasks = snapshot.data ?? [];
 
          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, color: Colors.white38, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'No tasks yet!\nAdd one from the previous screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
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
                color: Colors.white12,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task.isCompleted
                        ? Colors.greenAccent
                        : Colors.white54,
                    size: 28,
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: Colors.white54,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                      if (task.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 12, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text(
                              'Due ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}