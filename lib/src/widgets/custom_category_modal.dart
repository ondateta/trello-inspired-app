import 'package:flutter/material.dart';

class CustomCategoryModal extends StatefulWidget {
  final Function(String) onAddCategory;

  const CustomCategoryModal({
    Key? key,
    required this.onAddCategory,
  }) : super(key: key);

  @override
  State<CustomCategoryModal> createState() => _CustomCategoryModalState();
}

class _CustomCategoryModalState extends State<CustomCategoryModal> {
  final TextEditingController _categoryController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Category'),
      content: TextField(
        controller: _categoryController,
        decoration: const InputDecoration(
          labelText: 'Category Name',
          hintText: 'Enter category name',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_categoryController.text.trim().isEmpty) return;
                  
                  setState(() {
                    _isLoading = true;
                  });
                  
                  try {
                    await widget.onAddCategory(_categoryController.text.trim());
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Category'),
        ),
      ],
    );
  }
}