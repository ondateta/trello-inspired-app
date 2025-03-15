import 'package:flutter/material.dart';

class TaskModel {
  final String id;
  final String boardId;
  final String title;
  final String? description;
  final String status;
  final String category;
  final bool completed;
  final int position;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.boardId,
    required this.title,
    this.description,
    required this.status,
    required this.category,
    this.completed = false,
    required this.position,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      boardId: json['board_id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      category: json['category'] ?? 'default',
      completed: json['completed'] ?? false,
      position: json['position'] ?? 0,
      tags: json['tags'] != null 
          ? (json['tags'] is List 
              ? List<String>.from(json['tags'])
              : [])
          : [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_id': boardId,
      'title': title,
      'description': description,
      'status': status,
      'category': category,
      'completed': completed,
      'position': position,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? boardId,
    String? title,
    String? description,
    String? status,
    String? category,
    bool? completed,
    int? position,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      category: category ?? this.category,
      completed: completed ?? this.completed,
      position: position ?? this.position,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TaskStatus {
  static const String todo = "todo";
  static const String inProgress = "in_progress";
  static const String done = "done";
  
  static List<String> get allStatuses => [todo, inProgress, done];
  
  static String getDisplayName(String status) {
    switch (status) {
      case todo:
        return "To Do";
      case inProgress:
        return "In Progress";
      case done:
        return "Done";
      default:
        return status;
    }
  }
  
  static Color getColor(String status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (status) {
      case todo:
        return colorScheme.primary;
      case inProgress:
        return Colors.orange;
      case done:
        return Colors.green;
      default:
        return colorScheme.secondary;
    }
  }
}