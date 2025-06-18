import 'package:template/config/supabase_config.dart';
import 'package:template/src/models/task_model.dart';
import 'package:flutter/foundation.dart';

class TasksController {
  static final _client = SupabaseConfig.client;

  static Future<List<TaskModel>> getTasksByBoardId(String boardId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('board_id', boardId)
        .order('position');

    return response.map((task) => TaskModel.fromJson(task)).toList();
  }
  
  static Future<List<TaskModel>> getTasksByBoardIdAndCategory(String boardId, String category) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('board_id', boardId)
        .eq('category', category)
        .order('position');

    return response.map((task) => TaskModel.fromJson(task)).toList();
  }

  static Future<List<TaskModel>> getTasksByFilters({
    required String boardId,
    String? tag,
    String? searchQuery,
    String? category,
  }) async {
    var query = _client
        .from('tasks')
        .select()
        .eq('board_id', boardId);
        
    if (tag != null) {
      query = query.contains('tags', [tag]);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('title', '%$searchQuery%');
    }
    
    if (category != null) {
      query = query.eq('category', category);
    }
    
    final response = await query.order('position');
    return response.map((task) => TaskModel.fromJson(task)).toList();
  }

  static Future<TaskModel> createTask({
    required String boardId,
    required String title,
    String? description,
    required String status,
    required int position,
    String category = 'default',
    List<String> tags = const [],
  }) async {
    final response = await _client
        .from('tasks')
        .insert({
          'board_id': boardId,
          'title': title,
          'description': description,
          'status': status,
          'position': position,
          'category': category,
          'tags': tags,
        })
        .select()
        .single();

    return TaskModel.fromJson(response);
  }

  static Future<TaskModel> updateTask({
    required String id,
    String? title,
    String? description,
    bool? completed,
    String? status,
    int? position,
    String? category,
    List<String>? tags,
  }) async {
    final Map<String, dynamic> updates = {};
    
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (completed != null) updates['completed'] = completed;
    if (status != null) updates['status'] = status;
    if (position != null) updates['position'] = position;
    if (category != null) updates['category'] = category;
    if (tags != null) updates['tags'] = tags;

    final response = await _client
        .from('tasks')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return TaskModel.fromJson(response);
  }

  static Future<void> deleteTask(String id) async {
    await _client
        .from('tasks')
        .delete()
        .eq('id', id);
  }

  static Future<List<TaskModel>> reorderTasks(List<TaskModel> tasks) async {
    final batch = _client.from('tasks').upsert(
      tasks.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;
        return {
          'id': task.id,
          'position': index,
        };
      }).toList(),
    );

    await batch;
    return getTasksByBoardId(tasks.first.boardId);
  }
}

// Class to hold task update event info
class TaskUpdateEvent {
  final List<TaskModel> tasks;
  final TaskUpdateType updateType;
  
  TaskUpdateEvent(this.tasks, this.updateType);
}

// Enum to identify task update types
enum TaskUpdateType {
  initial,
  columnMove,
  tagUpdate,
  otherUpdate,
}

extension TasksControllerExtension on TasksController {
  static Stream<TaskUpdateEvent> subscribeToTasks(
    String boardId, {
    String? tag,
    String? searchQuery,
    String? category,
  }) {
    // Get initial data first
    final initialDataFuture = TasksController.getTasksByFilters(
      boardId: boardId,
      tag: tag,
      searchQuery: searchQuery,
      category: category,
    );
    
    // Setup the realtime subscription with channel for detailed event info
    final realtimeStream = SupabaseConfig.client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .eq('board_id', boardId)
      .order('position')
      .map((data) => data.map((task) => TaskModel.fromJson(task)).toList());
    
    // Store previous state to detect changes
    Map<String, TaskModel> previousTasksMap = {};
    
    // Transform the combined stream to detect specific change types
    return Stream.fromFuture(initialDataFuture)
      .asyncExpand((initialTasks) {
        // Initialize the previous state with initial data
        previousTasksMap = {for (var task in initialTasks) task.id: task};
        
        // Start with initial data event
        final initialEvent = TaskUpdateEvent(
          _applyFilters(
            initialTasks,
            tag: tag,
            searchQuery: searchQuery,
            category: category,
          ),
          TaskUpdateType.initial
        );
        
        // Then listen to realtime updates
        final updatesStream = realtimeStream.map((currentTasks) {
          final filteredTasks = _applyFilters(
            currentTasks,
            tag: tag,
            searchQuery: searchQuery,
            category: category,
          );
          
          // Determine the update type by comparing with previous state
          TaskUpdateType updateType = TaskUpdateType.otherUpdate;
          
          bool hasColumnMove = false;
          bool hasTagUpdate = false;
          
          // Create current state map for comparison
          final currentTasksMap = {for (var task in currentTasks) task.id: task};
          
          // Check for column/status moves or tag updates
          for (final taskId in currentTasksMap.keys) {
            if (previousTasksMap.containsKey(taskId)) {
              final previousTask = previousTasksMap[taskId]!;
              final currentTask = currentTasksMap[taskId]!;
              
              // Detect column/category changes
              if (previousTask.status != currentTask.status || 
                  previousTask.category != currentTask.category) {
                hasColumnMove = true;
              }
              
              // Detect tag changes
              if (!listEquals(previousTask.tags, currentTask.tags)) {
                hasTagUpdate = true;
              }
            }
          }
          
          // Determine the primary update type (prioritize column moves)
          if (hasColumnMove) {
            updateType = TaskUpdateType.columnMove;
          } else if (hasTagUpdate) {
            updateType = TaskUpdateType.tagUpdate;
          }
          
          // Update previous state for next comparison
          previousTasksMap = currentTasksMap;
          
          return TaskUpdateEvent(filteredTasks, updateType);
        });
        
        return Stream.value(initialEvent).asyncExpand((_) => updatesStream);
      });
  }

  static List<TaskModel> _applyFilters(
    List<TaskModel> tasks, {
    String? tag,
    String? searchQuery,
    String? category,
  }) {
    return tasks.where((task) {
      bool matches = true;
      
      if (tag != null) {
        matches = matches && task.tags.contains(tag);
      }
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        matches = matches && 
            task.title.toLowerCase().contains(searchQuery.toLowerCase());
      }
      
      if (category != null) {
        matches = matches && task.category == category;
      }
      
      return matches;
    }).toList();
  }
}