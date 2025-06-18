import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/config/supabase_config.dart';
import 'package:template/src/controllers/tasks_controller.dart';
import 'package:template/src/models/task_model.dart';
import 'package:template/src/views/board_detail_view.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';

@GenerateMocks([SupabaseConfig])
void main() {
  group('Real-time Synchronization Tests', () {
    late TaskUpdateEvent initialEvent;
    late StreamController<TaskUpdateEvent> mockStreamController;
    
    setUp(() {
      mockStreamController = StreamController<TaskUpdateEvent>.broadcast();
      
      initialEvent = TaskUpdateEvent(
        [
          TaskModel(
            id: '1',
            boardId: 'board-1',
            title: 'Task 1',
            status: TaskStatus.todo,
            category: 'default',
            position: 0,
            tags: ['tag1'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        TaskUpdateType.initial,
      );
      
      // Add initial task to the stream
      mockStreamController.add(initialEvent);
      
      // Mock the tasks subscription
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    
    tearDown(() {
      mockStreamController.close();
    });
    
    testWidgets('Board view should display new tasks in real-time', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BoardDetailView(boardId: 'board-1'),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify initial task is displayed
      expect(find.text('Task 1'), findsOneWidget);
      
      // Simulate a new task being added via real-time subscription
      final newTask = TaskModel(
        id: '2',
        boardId: 'board-1',
        title: 'New Real-time Task',
        status: TaskStatus.todo,
        category: 'default',
        position: 1,
        tags: ['realtime'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      mockStreamController.add(
        TaskUpdateEvent(
          [initialEvent.tasks.first, newTask],
          TaskUpdateType.otherUpdate,
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify both tasks are displayed
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('New Real-time Task'), findsOneWidget);
    });
    
    testWidgets('Board view should reflect task column changes in real-time', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BoardDetailView(boardId: 'board-1'),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Initial task is in todo column
      expect(find.text('Task 1'), findsOneWidget);
      
      // Simulate task moving to in progress column
      final updatedTask = initialEvent.tasks.first.copyWith(
        status: TaskStatus.inProgress,
      );
      
      mockStreamController.add(
        TaskUpdateEvent(
          [updatedTask],
          TaskUpdateType.columnMove,
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify the task has moved columns
      expect(find.text('Task 1'), findsOneWidget);
      
      // Verify snackbar appears for column move
      expect(find.text('Task moved to a new column'), findsOneWidget);
    });
    
    testWidgets('Board view should update when task tags change', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BoardDetailView(boardId: 'board-1'),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify initial tag is displayed
      expect(find.text('tag1'), findsOneWidget);
      
      // Simulate tag update
      final tagUpdatedTask = initialEvent.tasks.first.copyWith(
        tags: ['tag1', 'newtag'],
      );
      
      mockStreamController.add(
        TaskUpdateEvent(
          [tagUpdatedTask],
          TaskUpdateType.tagUpdate,
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify both tags are now displayed
      expect(find.text('tag1'), findsOneWidget);
      expect(find.text('newtag'), findsOneWidget);
    });
    
    testWidgets('Filter by tag should work with real-time updates', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BoardDetailView(boardId: 'board-1'),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Initial state has one task with 'tag1'
      expect(find.text('Task 1'), findsOneWidget);
      
      // Add a second task with different tag
      final secondTask = TaskModel(
        id: '2',
        boardId: 'board-1',
        title: 'Task 2',
        status: TaskStatus.todo,
        category: 'default',
        position: 1,
        tags: ['tag2'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      mockStreamController.add(
        TaskUpdateEvent(
          [initialEvent.tasks.first, secondTask],
          TaskUpdateType.otherUpdate,
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Both tasks should be visible
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
      
      // Filter by tag1
      await tester.tap(find.text('All tags'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('tag1'));
      await tester.pumpAndSettle();
      
      // Only Task 1 should be visible
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsNothing);
      
      // Add a third task with tag1 in real-time
      final thirdTask = TaskModel(
        id: '3',
        boardId: 'board-1',
        title: 'Task 3',
        status: TaskStatus.todo,
        category: 'default',
        position: 2,
        tags: ['tag1'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      mockStreamController.add(
        TaskUpdateEvent(
          [initialEvent.tasks.first, secondTask, thirdTask],
          TaskUpdateType.otherUpdate,
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Both Task 1 and Task 3 should be visible (both have tag1)
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 3'), findsOneWidget);
      expect(find.text('Task 2'), findsNothing);
    });
  });
}