import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/src/controllers/tasks_controller.dart';
import 'package:template/src/models/task_model.dart';
import 'package:template/src/views/board_detail_view.dart';

// This test simulates multiple clients viewing and updating the same board

class MultiClientSimulator {
  final String boardId;
  final StreamController<TaskUpdateEvent> _controller = StreamController<TaskUpdateEvent>.broadcast();
  final List<TaskModel> _sharedTasks = [];
  
  MultiClientSimulator(this.boardId) {
    // Initialize with some tasks
    _sharedTasks.add(
      TaskModel(
        id: '1',
        boardId: boardId,
        title: 'Shared Task 1',
        status: TaskStatus.todo,
        category: 'default',
        position: 0,
        tags: ['shared'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )
    );
    
    // Emit initial tasks
    _controller.add(TaskUpdateEvent(_sharedTasks, TaskUpdateType.initial));
  }
  
  Stream<TaskUpdateEvent> getStream() {
    return _controller.stream;
  }
  
  void addTask(TaskModel task) {
    _sharedTasks.add(task);
    _controller.add(TaskUpdateEvent(_sharedTasks, TaskUpdateType.otherUpdate));
  }
  
  void moveTask(String taskId, String newStatus) {
    final index = _sharedTasks.indexWhere((task) => task.id == taskId);
    if (index >= 0) {
      _sharedTasks[index] = _sharedTasks[index].copyWith(status: newStatus);
      _controller.add(TaskUpdateEvent(_sharedTasks, TaskUpdateType.columnMove));
    }
  }
  
  void updateTaskTags(String taskId, List<String> newTags) {
    final index = _sharedTasks.indexWhere((task) => task.id == taskId);
    if (index >= 0) {
      _sharedTasks[index] = _sharedTasks[index].copyWith(tags: newTags);
      _controller.add(TaskUpdateEvent(_sharedTasks, TaskUpdateType.tagUpdate));
    }
  }
  
  void dispose() {
    _controller.close();
  }
}

void main() {
  group('Multi-client Real-time Synchronization Tests', () {
    late MultiClientSimulator simulator;
    
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      simulator = MultiClientSimulator('shared-board');
    });
    
    tearDown(() {
      simulator.dispose();
    });
    
    testWidgets('Multiple clients should see the same tasks', (WidgetTester tester) async {
      // Build client 1 view
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<TaskUpdateEvent>(
              stream: simulator.getStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                
                final tasks = snapshot.data!.tasks;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => 
                    ListTile(title: Text(tasks[index].title)),
                );
              },
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify initial task
      expect(find.text('Shared Task 1'), findsOneWidget);
      
      // Simulate client 2 adding a task
      simulator.addTask(
        TaskModel(
          id: '2',
          boardId: 'shared-board',
          title: 'Added by Client 2',
          status: TaskStatus.todo,
          category: 'default',
          position: 1,
          tags: ['client2'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      );
      
      await tester.pumpAndSettle();
      
      // Client 1 should see both tasks now
      expect(find.text('Shared Task 1'), findsOneWidget);
      expect(find.text('Added by Client 2'), findsOneWidget);
    });
    
    testWidgets('Task status changes should sync across clients', (WidgetTester tester) async {
      // Build client view with custom widget to see status
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<TaskUpdateEvent>(
              stream: simulator.getStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                
                final tasks = snapshot.data!.tasks;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(tasks[index].title),
                    subtitle: Text('Status: ${tasks[index].status}'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Initial status
      expect(find.text('Status: todo'), findsOneWidget);
      
      // Simulate client 2 moving the task
      simulator.moveTask('1', TaskStatus.inProgress);
      
      await tester.pumpAndSettle();
      
      // Status should be updated in client 1
      expect(find.text('Status: in_progress'), findsOneWidget);
      expect(find.text('Status: todo'), findsNothing);
    });
    
    testWidgets('Tag updates should sync across clients', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<TaskUpdateEvent>(
              stream: simulator.getStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                
                final tasks = snapshot.data!.tasks;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tasks[index].title),
                      Wrap(
                        children: tasks[index].tags.map((tag) => 
                          Chip(label: Text(tag))
                        ).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Initial tags
      expect(find.text('shared'), findsOneWidget);
      
      // Simulate client 2 updating tags
      simulator.updateTaskTags('1', ['shared', 'urgent', 'sprint']);
      
      await tester.pumpAndSettle();
      
      // All tags should appear in client 1
      expect(find.text('shared'), findsOneWidget);
      expect(find.text('urgent'), findsOneWidget);
      expect(find.text('sprint'), findsOneWidget);
    });
  });
}