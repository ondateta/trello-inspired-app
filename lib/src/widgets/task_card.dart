import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gap/gap.dart';
import 'package:template/src/controllers/tasks_controller.dart';
import 'package:template/src/models/task_model.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final VoidCallback onUpdated;
  final Function(TaskModel)? onTaskMoved;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onUpdated,
    this.onTaskMoved,
  }) : super(key: key);

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  List<String> _taskTags = [];
  final TextEditingController _tagController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _categoryController = TextEditingController(text: widget.task.category);
    _taskTags = List.from(widget.task.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _updateTask() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await TasksController.updateTask(
        id: widget.task.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? 'default' : _categoryController.text.trim(),
        tags: _taskTags,
        status: widget.task.status,
        position: widget.task.position,
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
      }
      widget.onUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleCompleted() async {
    try {
      final originalCompletedState = widget.task.completed;
      
      await TasksController.updateTask(
        id: widget.task.id,
        completed: !widget.task.completed,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    widget.onUpdated();
  }

  Future<void> _deleteTask() async {
    try {
      await TasksController.deleteTask(widget.task.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isEditing) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  isDense: true,
                ),
                style: theme.textTheme.bodyLarge,
              ),
              const Gap(8),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  isDense: true,
                ),
                style: theme.textTheme.bodyMedium,
                minLines: 2,
                maxLines: 4,
              ),
              const Gap(8),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  isDense: true,
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const Gap(8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Add tags',
                        hintText: 'Enter tag',
                        isDense: true,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _taskTags.add(value);
                            _tagController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_tagController.text.isNotEmpty) {
                        setState(() {
                          _taskTags.add(_tagController.text);
                          _tagController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              if (_taskTags.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _taskTags.map((tag) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Chip(
                        label: Text(tag),
                        onDeleted: () {
                          setState(() {
                            _taskTags.remove(tag);
                          });
                        },
                      ),
                    )).toList(),
                  ),
                ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _titleController.text = widget.task.title;
                        _descriptionController.text = widget.task.description ?? '';
                        _categoryController.text = widget.task.category;
                        _taskTags = List.from(widget.task.tags);
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  const Gap(8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateTask,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return LongPressDraggable<TaskModel>(
      data: widget.task,
      feedback: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child: Opacity(
          opacity: 0.8,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.task.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.task.description != null && widget.task.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.task.description!,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTaskCard(theme),
      ),
      child: _buildTaskCard(theme),
    );
  }

  Widget _buildTaskCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _isEditing = true;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: widget.task.completed,
                    onChanged: (_) => _toggleCompleted(),
                  ),
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: widget.task.completed ? TextDecoration.lineThrough : null,
                        color: widget.task.completed ? theme.colorScheme.outline : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Chip(
                        label: Text(widget.task.category),
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        labelStyle: TextStyle(fontSize: 12),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const Gap(4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Task'),
                          content: Text('Are you sure you want to delete "${widget.task.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _deleteTask();
                      }
                    },
                  ),
                ],
              ),
              if (widget.task.description != null && widget.task.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 42),
                  child: Text(
                    widget.task.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: widget.task.completed ? theme.colorScheme.outline : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Gap(4),
              if (widget.task.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 42),
                  child: Wrap(
                    spacing: 4,
                    children: widget.task.tags.map((tag) => Chip(
                      label: Text(tag),
                      labelStyle: TextStyle(fontSize: 10),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}