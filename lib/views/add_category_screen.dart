import 'package:flutter/material.dart';

import '../domain/entities/category.dart';

class AddCategoryScreen extends StatefulWidget {
  final ShoppingCategory? existingCategory;

  const AddCategoryScreen({super.key, this.existingCategory});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String _iconStr = '🏮';

  final List<String> _tetIcons = const [
    '🎁',
    '🍬',
    '🏮',
    '🧧',
    '🌸',
    '🍗',
    '🍺',
    '🚗',
    '👗',
    '✨',
    '🏠',
    '🛒',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      _titleController.text = widget.existingCategory!.title;
      _iconStr = widget.existingCategory!.iconStr;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.existingCategory != null;

    return Scaffold(
      appBar: AppBar(title: Text(isUpdate ? 'Sửa hạng mục' : 'Thêm hạng mục')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tên hạng mục',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: Quà biếu, Bánh kẹo, Trang trí',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nhập tên hạng mục';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Icon đại diện',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _tetIcons
                          .map((icon) => _buildIconOption(icon))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submit,
                        child: Text(isUpdate ? 'Lưu thay đổi' : 'Tạo hạng mục'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconOption(String icon) {
    final selected = icon == _iconStr;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _iconStr = icon),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? const Color(0xFFFFEDD6) : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFFC62828) : const Color(0xFFD9CEC4),
            width: selected ? 1.8 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(icon, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'title': _titleController.text.trim(),
        'iconStr': _iconStr,
      });
    }
  }
}
