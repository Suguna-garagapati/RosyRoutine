import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

void main() {
  runApp(const RosyRoutineApp());
}

class RosyRoutineApp extends StatelessWidget {
  const RosyRoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RosyRoutine',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFFF8FA),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> tasks = [
    {"title": "Wake up at 5:30 AM", "done": false},
    {"title": "Drink 3L Water", "done": false},
    {"title": "Workout for 30 mins", "done": false},
    {"title": "Sleep at 10:00 PM", "done": false},
  ];
  int streak = 0;

  String lastCompletedDate = "";
  final TextEditingController taskController = TextEditingController();
  late ConfettiController confettiController;
  @override
  void initState() {
    super.initState();
    confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    loadTasks().then((_) {
      resetTasksIfNewDay();
    });
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> taskList = tasks.map((task) => jsonEncode(task)).toList();

    await prefs.setStringList('tasks', taskList);
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();

    List<String>? savedTasks = prefs.getStringList('tasks');
    streak = prefs.getInt('streak') ?? 0;

    lastCompletedDate = prefs.getString('lastCompletedDate') ?? "";
    if (savedTasks != null) {
      setState(() {
        tasks = savedTasks
            .map((task) => jsonDecode(task))
            .cast<Map<String, dynamic>>()
            .toList();
      });
    }
  }

  Future<void> resetTasksIfNewDay() async {
    String today = DateTime.now().toString().substring(0, 10);

    if (lastCompletedDate != today) {
      setState(() {
        for (var task in tasks) {
          task["done"] = false;
        }
      });

      saveTasks();
    }
  }

  // streak updating function
  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();

    bool allCompleted = tasks.every((task) => task["done"] == true);

    String today = DateTime.now().toString().substring(0, 10);

    DateTime todayDate = DateTime.parse(today);

    if (lastCompletedDate.isNotEmpty) {
      DateTime lastDate = DateTime.parse(lastCompletedDate);

      int difference = todayDate.difference(lastDate).inDays;

      // if skipped more than 1 day
      if (difference > 1) {
        streak = 0;
      }
    }

    if (allCompleted && lastCompletedDate != today) {
      setState(() {
        streak++;

        lastCompletedDate = today;

        confettiController.play();
      });

      await prefs.setInt('streak', streak);

      await prefs.setString('lastCompletedDate', lastCompletedDate);
    }
  }

  @override
  void dispose() {
    confettiController.dispose();

    taskController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8BBD0),
        elevation: 0,

        title: const Text(
          '🌸 RosyRoutine',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),

      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const SizedBox(height: 20),

                Text(
                  "🔥 $streak Day Streak",

                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF5A5F),
                  ),
                ),

                const SizedBox(height: 15),
                const Text(
                  "Today's Goals ✨",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 25),
                Builder(
                  builder: (context) {
                    int completedTasks = tasks
                        .where((task) => task["done"] == true)
                        .length;

                    double progress = tasks.isEmpty
                        ? 0
                        : completedTasks / tasks.length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          "$completedTasks / ${tasks.length} Tasks Completed 🌸",

                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 10),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),

                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,

                            backgroundColor: Colors.pink.shade100,

                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF5A5F),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),
                      ],
                    );
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: tasks.length,

                    itemBuilder: (context, index) {
                      return taskCard(index)
                          .animate()
                          .fade(duration: 800.ms)
                          .slideY(
                            begin: 1,
                            end: 0,
                            duration: 800.ms,
                            curve: Curves.easeOutBack,
                          )
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1, 1),
                            duration: 800.ms,
                          );
                    },
                  ),
                ),
              ],
            ),
          ),

          Align(
            child: ConfettiWidget(
              confettiController: confettiController,

              blastDirectionality: BlastDirectionality.explosive,

              shouldLoop: false,

              emissionFrequency: 0.08,

              numberOfParticles: 40,

              maxBlastForce: 30,

              minBlastForce: 10,

              gravity: 0.3,

              colors: const [
                Colors.pink,
                Colors.red,
                Colors.white,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF8BBD0),

        onPressed: () {
          showDialog(
            context: context,

            builder: (context) {
              return AlertDialog(
                title: const Text("Add New Task 🌸"),

                content: TextField(
                  controller: taskController,

                  decoration: const InputDecoration(
                    hintText: "Enter your task",
                  ),
                ),

                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    child: const Text("Cancel"),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        tasks.add({
                          "title": taskController.text,
                          "done": false,
                        });
                        saveTasks();
                      });

                      taskController.clear();

                      Navigator.pop(context);
                    },

                    child: const Text("Add"),
                  ),
                ],
              );
            },
          );
        },

        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget taskCard(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: tasks[index]["done"] ? Colors.pink.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: tasks[index]["done"]
                ? Colors.pink.withOpacity(0.18)
                : Colors.pink.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Checkbox(
            value: tasks[index]["done"],

            onChanged: (value) {
              setState(() {
                tasks[index]["done"] = value;
                saveTasks();
                updateStreak();
              });
            },

            activeColor: const Color.fromARGB(255, 148, 26, 152),
          ),

          Expanded(
            child: Text(
              tasks[index]["title"],

              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: tasks[index]["done"]
                    ? FontWeight.bold
                    : FontWeight.normal,

                decoration: tasks[index]["done"]
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                tasks.removeAt(index);
                saveTasks();
              });
            },

            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }
}