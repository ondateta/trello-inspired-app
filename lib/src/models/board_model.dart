import 'package:template/src/models/task_model.dart';
import 'package:template/src/models/board_category_model.dart';

class BoardModel {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalTasks;
  final int completedTasks;
  final List<TaskModel>? tasks;
  final List<BoardCategoryModel>? customCategories;

  BoardModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.tasks,
    this.customCategories,
  });

  factory BoardModel.fromJson(Map<String, dynamic> json) {
    return BoardModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      totalTasks: json['tasks'] != null ? (json['tasks'] as List).length :
                  json['total_tasks'] != null && json['total_tasks'] is int ? json['total_tasks'] : 0,
      completedTasks: json['tasks'] != null ? 
                      (json['tasks'] as List).where((task) => task['completed'] == true).length : 
                      json['completed_tasks'] != null && json['completed_tasks'] is int ? json['completed_tasks'] : 0,
      tasks: json['tasks'] != null ? (json['tasks'] as List).map<TaskModel>((task) => TaskModel.fromJson(task)).toList() : null,
      customCategories: json['custom_categories'] != null ? (json['custom_categories'] as List).map<BoardCategoryModel>((category) => BoardCategoryModel.fromJson(category)).toList() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
      'tasks': tasks?.map((task) => task.toJson()).toList(),
      'custom_categories': customCategories?.map((category) => category.toJson()).toList(),
    };
  }

  BoardModel copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalTasks,
    int? completedTasks,
    List<TaskModel>? tasks,
    List<BoardCategoryModel>? customCategories,
  }) {
    return BoardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      tasks: tasks ?? this.tasks,
      customCategories: customCategories ?? this.customCategories,
    );
  }
}