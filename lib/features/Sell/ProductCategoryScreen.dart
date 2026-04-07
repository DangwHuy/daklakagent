import 'package:flutter/material.dart';

class ProductCategoryScreen extends StatelessWidget {
  const ProductCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Danh sách sản phẩm mẫu
    final List<String> categories = [
      'HẠT & CÂY GIỐNG',
      'HOA - CÂY CẢNH',
      'PHÂN BÓN',
      'NÔNG SẢN NHÀ NÔNG',
      'THUỐC BẢO VỆ THỰC VẬT',
      'VẬT TƯ - THIẾT BỊ'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn danh mục sản phẩm'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: ListView.separated(
        itemCount: categories.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(categories[index]),
            onTap: () {
              // Trả giá trị đã chọn về màn hình trước
              Navigator.pop(context, categories[index]);
            },
          );
        },
      ),
    );
  }
}