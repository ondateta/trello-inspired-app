import 'package:flutter/material.dart';
import 'package:template/src/controllers/boards_controller.dart';
import 'package:template/src/extensions/index.dart';
import 'package:template/src/models/board_model.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<BoardModel>> _boardsFuture;

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  void _loadBoards() async {
    setState(() {
      _boardsFuture = _fetchBoardsWithTasks();
    });
  }

  Future<List<BoardModel>> _fetchBoardsWithTasks() async {
    final boards = await BoardsController.getBoards();
    
    List<BoardModel> updatedBoards = [];
    for (var board in boards) {
      final boardWithTasks = await BoardsController.getBoardWithTasks(board.id);
      updatedBoards.add(boardWithTasks);
    }
    
    return updatedBoards;
  }

  void _createNewBoard() async {
    final TextEditingController nameController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Board'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Board Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await BoardsController.createBoard(nameController.text.trim());
                Navigator.pop(context);
                _loadBoards(); // Refresh the boards list
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<BoardModel>>(
        future: _boardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading boards: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBoards,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No boards found. Create your first board!'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createNewBoard,
                    child: const Text('Create Board'),
                  ),
                ],
              ),
            );
          } else {
            return _buildBoardsList(snapshot.data!);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewBoard,
        tooltip: 'Create Board',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBoardsList(List<BoardModel> boards) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        final board = boards[index];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              board.name,
              style: context.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pushNamed(
                context, 
                '/board/${board.id}',
              ).then((_) => _loadBoards());
            },
          ),
        );
      },
    );
  }
}