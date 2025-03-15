class BoardCategoryModel {
  final String id;
  final String boardId;
  final String name;
  final DateTime createdAt;

  BoardCategoryModel({
    required this.id,
    required this.boardId,
    required this.name,
    required this.createdAt,
  });

  factory BoardCategoryModel.fromJson(Map<String, dynamic> json) {
    return BoardCategoryModel(
      id: json['id'],
      boardId: json['board_id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'board_id': boardId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}