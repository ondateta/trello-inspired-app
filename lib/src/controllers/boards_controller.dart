import 'package:template/config/supabase_config.dart';
import 'package:template/src/models/board_model.dart';
import 'package:template/src/models/board_category_model.dart';
import 'package:template/src/models/task_model.dart';
import 'package:flutter/material.dart';

class BoardsController {
  static final _client = SupabaseConfig.client;

  static Future<List<BoardModel>> getBoards() async {
    final response = await _client
        .from('boards')
        .select('''
          *,
          total_tasks:tasks(count),
          completed_tasks:tasks(count).eq('completed', true)
        ''')
        .order('created_at', ascending: false);

    return response.map((board) => BoardModel.fromJson(board)).toList();
  }

  static Future<BoardModel> getBoardById(String id) async {
    final response = await _client
        .from('boards')
        .select('''
          *,
          total_tasks:tasks(count),
          completed_tasks:tasks(count).eq('completed', true)
        ''')
        .eq('id', id)
        .single();

    return BoardModel.fromJson(response);
  }

  static Future<BoardModel> getBoardWithTasks(String id) async {
    final boardResponse = await getBoardById(id);
    final tasksResponse = await _client
        .from('tasks')
        .select('*')
        .eq('board_id', id)
        .order('position');
    
    final customCategories = await fetchCustomCategories(id);
    
    return boardResponse.copyWith(
      tasks: tasksResponse.map((task) => TaskModel.fromJson(task)).toList(),
      customCategories: customCategories,
    );
  }

  static Future<BoardModel> createBoard(String name) async {
    final userId = _client.auth.currentUser!.id;
    
    final response = await _client
        .from('boards')
        .insert({
          'name': name,
          'user_id': userId,
        })
        .select()
        .single();

    return BoardModel.fromJson(response);
  }

  static Future<void> updateBoard(String id, String name) async {
    await _client
        .from('boards')
        .update({
          'name': name,
        })
        .eq('id', id);
  }

  static Future<void> deleteBoard(String id) async {
    await _client
        .from('boards')
        .delete()
        .eq('id', id);
  }

  static Future<void> addCustomCategory(String boardId, String name, {int? position}) async {
    try {
      await _client
          .from('board_categories')
          .insert({
            'board_id': boardId,
            'name': name,
            'position': position ?? 0,
          });
    } catch (e) {
      throw Exception('Failed to add category: ${e.toString()}');
    }
  }

  static Future<List<BoardCategoryModel>> fetchCustomCategories(String boardId) async {
    try {
      final response = await _client
          .from('board_categories')
          .select('*')
          .eq('board_id', boardId)
          .order('position');
      
      if (response == null || response.isEmpty) {
        return [];
      }
      
      return response.map((category) => BoardCategoryModel.fromJson(category)).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: ${e.toString()}');
    }
  }
  
  static Stream<List<BoardModel>> subscribeToBoards() {
    return _client
        .from('boards')
        .stream(primaryKey: ['id'])
        .eq('user_id', _client.auth.currentUser!.id)
        .map((data) => data.map((board) => BoardModel.fromJson(board)).toList());
  }
}