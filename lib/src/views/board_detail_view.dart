import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:gap/gap.dart';
import 'package:template/config/supabase_config.dart';
import 'package:template/src/controllers/boards_controller.dart';
import 'package:template/src/controllers/tasks_controller.dart';
import 'package:template/src/design_system/responsive_values.dart';
import 'package:template/src/models/board_model.dart';
import 'package:template/src/models/task_model.dart';
import 'package:template/src/models/board_category_model.dart';
import 'package:template/src/widgets/task_card.dart';
import 'package:template/src/widgets/custom_category_modal.dart';

class BoardDetailView extends StatefulWidget {
  final String boardId;

  const BoardDetailView({
    Key? key,
    required this.boardId,
  }) : super(key: key);

  @override
  State<BoardDetailView> createState() => _BoardDetailViewState();
}

class _BoardDetailViewState extends State<BoardDetailView> {
  late Future<BoardModel> _boardFuture;
  late Future<List<TaskModel>> _tasksFuture;
  late Future<List<dynamic>> _categoriesFuture;
  final Map<String, List<TaskModel>> _tasksByStatus = {};
  bool _isAddingTask = false;
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDescriptionController = TextEditingController();
  final TextEditingController _taskCategoryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTagFilter;
  List<String> _allTags = [];
  List<String> _taskTagsList = [];
  final TextEditingController _tagController = TextEditingController();
  String _newTaskStatus = TaskStatus.todo;
  bool _isLoading = false;
  List<String> _customCategories = [];
  StreamSubscription<TaskUpdateEvent>? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    _loadBoard();
    _loadCategories();
    _setupRealTimeSubscription();
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    _taskCategoryController.dispose();
    _searchController.dispose();
    _tasksSubscription?.cancel();
    super.dispose();
  }

  void _loadBoard() {
    _boardFuture = BoardsController.getBoardById(widget.boardId);
  }

  void _loadCategories() {
    _categoriesFuture = BoardsController.fetchCustomCategories(widget.boardId);
    _categoriesFuture.then((categories) {
      if (mounted) {
        setState(() {
          if (categories.isEmpty) {
            _customCategories = [];
          } else {
            _customCategories = categories.map((c) => c.name as String).toList();
          }
        });
      }
    });
  }

  void _updateFilters() {
    _tasksSubscription?.cancel();
    _setupRealTimeSubscription();
  }

  void _updateAllTags(List<TaskModel> tasks) {
    final Set<String> tags = {};
    for (final task in tasks) {
      tags.addAll(task.tags);
    }
    _allTags = tags.toList();
  }

  void _organizeTasksByStatus(List<TaskModel> tasks) {
    _tasksByStatus.clear();
    
    for (final status in TaskStatus.allStatuses) {
      _tasksByStatus[status] = [];
    }
    
    for (final category in _customCategories) {
      if (!_tasksByStatus.containsKey(category)) {
        _tasksByStatus[category] = [];
      }
    }
    
    final Set<String> allStatuses = tasks.map((task) => task.status).toSet();
    
    for (final status in allStatuses) {
      if (!_tasksByStatus.containsKey(status)) {
        _tasksByStatus[status] = [];
      }
    }

    for (final task in tasks) {
      if (_customCategories.contains(task.category)) {
        _tasksByStatus[task.category]!.add(task);
      } else {
        _tasksByStatus[task.status]!.add(task);
      }
    }
  }

  Future<void> _createTask() async {
    if (_taskTitleController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await TasksController.createTask(
        boardId: widget.boardId,
        title: _taskTitleController.text.trim(),
        description: _taskDescriptionController.text.trim().isNotEmpty
            ? _taskDescriptionController.text.trim()
            : null,
        status: _newTaskStatus,
        position: _tasksByStatus[_newTaskStatus]?.length ?? 0,
        category: _taskCategoryController.text.trim().isNotEmpty
            ? _taskCategoryController.text.trim()
            : 'default',
        tags: _taskTagsList,
      );

      if (mounted) {
        setState(() {
          _isAddingTask = false;
          _taskTitleController.clear();
          _taskDescriptionController.clear();
          _taskCategoryController.clear();
          _taskTagsList = [];
          _newTaskStatus = TaskStatus.todo;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create task: ${e.toString()}'),
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

  void _handleTaskMoved(TaskModel task, String newStatus) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await TasksController.updateTask(
        id: task.id,
        status: newStatus,
        position: _tasksByStatus[newStatus]?.length ?? 0,
        category: task.category,
        tags: task.tags,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task moved to ${TaskStatus.getDisplayName(newStatus)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupRealTimeSubscription() {
    _tasksSubscription = TasksControllerExtension.subscribeToTasks(
      widget.boardId,
      tag: _selectedTagFilter,
      searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
      category: null,
    ).listen((updateEvent) {
      if (mounted) {
        setState(() {
          _organizeTasksByStatus(updateEvent.tasks);
          _updateAllTags(updateEvent.tasks);
          
          // Handle specific update types
          switch (updateEvent.updateType) {
            case TaskUpdateType.columnMove:
              // Show a temporary indicator for column movement
              if (updateEvent.tasks.isNotEmpty) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task moved to a new column'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              break;
            case TaskUpdateType.tagUpdate:
              // Update tags list when tags change
              break;
            default:
              // Handle other updates
              break;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<BoardModel>(
          future: _boardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            }

            if (snapshot.hasError) {
              return const Text('Board not found');
            }

            return Text(snapshot.data?.name ?? 'Board');
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/boards');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Add Custom Category',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => CustomCategoryModal(
                  onAddCategory: (categoryName) async {
                    try {
                      await BoardsController.addCustomCategory(
                        widget.boardId,
                        categoryName,
                      );
                      setState(() {
                        if (!_customCategories.contains(categoryName)) {
                          _customCategories.add(categoryName);
                        }
                      });
                    } catch (e) {}
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final board = await _boardFuture;
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) {
                    final nameController = TextEditingController(text: board.name);
                    return AlertDialog(
                      title: const Text('Edit Board'),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Board Name',
                        ),
                        autofocus: true,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (nameController.text.trim().isNotEmpty) {
                              await BoardsController.updateBoard(
                                board.id,
                                nameController.text.trim()
                              );
                              if (mounted) {
                                setState(() {
                                  _loadBoard();
                                });
                                Navigator.of(context).pop();
                              }
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tasks',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    onChanged: (_) => _updateFilters(),
                  ),
                ),
                if (_allTags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  DropdownButton<String?>(
                    hint: const Text('Filter by tag'),
                    value: _selectedTagFilter,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All tags'),
                      ),
                      ..._allTags.map((tag) => DropdownMenuItem<String?>(
                        value: tag,
                        child: Text(tag),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTagFilter = value;
                        _updateFilters();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<TaskUpdateEvent>(
              stream: TasksControllerExtension.subscribeToTasks(
                widget.boardId,
                tag: _selectedTagFilter,
                searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error loading tasks',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Gap(8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _updateFilters();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasData && snapshot.data != null) {
                  _organizeTasksByStatus(snapshot.data!.tasks);
                  _updateAllTags(snapshot.data!.tasks);
                }

                return responsiveValue<Widget>(
                  context,
                  mobile: () => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: _tasksByStatus.length * MediaQuery.of(context).size.width * 0.85,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _tasksByStatus.keys.map((status) {
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            child: _buildStatusColumn(status, theme),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  orElse: () => Row(
                    children: _tasksByStatus.keys.map((status) {
                      return Expanded(
                        child: _buildStatusColumn(status, theme),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isAddingTask
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isAddingTask = true;
                  _taskTagsList = [];
                });
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildStatusColumn(String status, ThemeData theme) {
    final tasks = _tasksByStatus[status] ?? [];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TaskStatus.getColor(status, context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TaskStatus.getDisplayName(status),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: TaskStatus.getColor(status, context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: TaskStatus.getColor(status, context).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: TaskStatus.getColor(status, context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: DragTarget<TaskModel>(
            onAccept: (task) {
              _handleTaskMoved(task, status);
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty
                      ? TaskStatus.getColor(status, context).withOpacity(0.1)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    ...tasks.map((task) => TaskCard(
                      task: task,
                      onUpdated: () => _updateFilters(),
                    )),
                    if (_isAddingTask && status == _newTaskStatus)
                      _buildNewTaskCard(theme),
                    if (tasks.isEmpty && !(_isAddingTask && status == _newTaskStatus))
                      Container(
                        height: 100,
                        alignment: Alignment.center,
                        child: Text(
                          'Drop tasks here',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewTaskCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _taskTitleController,
              decoration: const InputDecoration(
                labelText: 'Task title',
                hintText: 'Enter task title',
                isDense: true,
              ),
              autofocus: true,
            ),
            const Gap(8),
            TextField(
              controller: _taskDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter task description',
                isDense: true,
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const Gap(8),
            TextField(
              controller: _taskCategoryController,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                hintText: 'Enter task category',
                isDense: true,
              ),
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
                          _taskTagsList.add(value);
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
                        _taskTagsList.add(_tagController.text);
                        _tagController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            if (_taskTagsList.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _taskTagsList.map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      label: Text(tag),
                      onDeleted: () {
                        setState(() {
                          _taskTagsList.remove(tag);
                        });
                      },
                    ),
                  )).toList(),
                ),
              ),
            const Gap(8),
            DropdownButtonFormField<String>(
              value: _newTaskStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                isDense: true,
              ),
              items: TaskStatus.allStatuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(TaskStatus.getDisplayName(status)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _newTaskStatus = value;
                  });
                }
              },
            ),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isAddingTask = false;
                      _taskTitleController.clear();
                      _taskDescriptionController.clear();
                      _taskCategoryController.clear();
                      _taskTagsList = [];
                      _newTaskStatus = TaskStatus.todo;
                    });
                  },
                  child: const Text('Cancel'),
                ),
                const Gap(8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createTask,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Task'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}