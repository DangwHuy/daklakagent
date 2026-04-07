// agricultural_market_screen.dart
// A beautifully designed Agricultural Market screen for Flutter
// Inspired by a modern e-commerce UI with nature greens and earthy tones.

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Để hết lỗi NumberFormat
import 'package:daklakagent/features/Sell/CreateProductScreen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // THÊM DÒNG NÀY để hết lỗi
import 'package:daklakagent/features/Sell/ProductDetailScreen.dart';
import 'package:daklakagent/features/Sell/CartScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ---------------------------------------------------------------------------
// ENTRY POINT (for standalone testing — remove when integrating)
// ---------------------------------------------------------------------------
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(),
      home: const AgriculturalMarketScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// THEME
// ---------------------------------------------------------------------------
ThemeData _buildAppTheme() {
  const seedColor = Color(0xFF2E7D32); // deep forest green
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: const Color(0xFF2E7D32),
      secondary: const Color(0xFF8D6E63), // earthy brown
      tertiary: const Color(0xFFFFA000), // harvest amber
      surface: const Color(0xFFF9F6F2),
      onSurface: const Color(0xFF1C1B1F),
    ),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: const Color(0xFFF4F1EC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}

// ---------------------------------------------------------------------------
// DATA MODEL
// ---------------------------------------------------------------------------

/// Represents a product category shown in the horizontal scroll list.
class ProductCategory {
  final String name;
  final IconData icon;

  const ProductCategory({required this.name, required this.icon});
}

/// Represents a single product card in the grid.
class Product {
  final String id;
  final String name;
  final double price;
  final String unit; // e.g. "/ kg", "/ bunch"
  final Color tagColor;
  final IconData imageIcon; // placeholder icon instead of a real image
  final int stockLeft;
  final double rating;
  final int reviewCount;
  bool isFavourite;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.tagColor,
    required this.imageIcon,
    required this.stockLeft,
    required this.rating,
    required this.reviewCount,
    this.isFavourite = false,
  });
}

// ---------------------------------------------------------------------------
// MOCK DATA
// ---------------------------------------------------------------------------

/// Static list of categories for the horizontal filter row.

/// Static list of mock products.
final List<Product> _products = [
  Product(
    id: '1',
    name: 'Organic Tomatoes',
    price: 3.50,
    unit: '/ kg',
    tagColor: const Color(0xFFE53935),
    imageIcon: Icons.spa,
    stockLeft: 20,
    rating: 4.8,
    reviewCount: 312,
  ),
  Product(
    id: '2',
    name: 'Fresh Corn Cobs',
    price: 2.00,
    unit: '/ bunch',
    tagColor: const Color(0xFFFFA000),
    imageIcon: Icons.grass,
    stockLeft: 8,
    rating: 4.5,
    reviewCount: 184,
  ),
  Product(
    id: '3',
    name: 'Baby Spinach',
    price: 1.80,
    unit: '/ bag',
    tagColor: const Color(0xFF388E3C),
    imageIcon: Icons.eco,
    stockLeft: 15,
    rating: 4.7,
    reviewCount: 229,
  ),
  Product(
    id: '4',
    name: 'Purple Eggplant',
    price: 4.20,
    unit: '/ kg',
    tagColor: const Color(0xFF7B1FA2),
    imageIcon: Icons.local_florist,
    stockLeft: 6,
    rating: 4.3,
    reviewCount: 97,
  ),
  Product(
    id: '5',
    name: 'Heirloom Carrot',
    price: 2.75,
    unit: '/ kg',
    tagColor: const Color(0xFFE64A19),
    imageIcon: Icons.spa,
    stockLeft: 18,
    rating: 4.6,
    reviewCount: 143,
  ),
  Product(
    id: '6',
    name: 'Sweet Potatoes',
    price: 3.10,
    unit: '/ kg',
    tagColor: const Color(0xFF8D6E63),
    imageIcon: Icons.grain,
    stockLeft: 4,
    rating: 4.9,
    reviewCount: 401,
  ),
];

// ---------------------------------------------------------------------------
// MAIN SCREEN
// ---------------------------------------------------------------------------

/// The top-level screen widget for the Agricultural Market feature.
class AgriculturalMarketScreen extends StatefulWidget {
  const AgriculturalMarketScreen({super.key});

  @override
  State<AgriculturalMarketScreen> createState() =>
      _AgriculturalMarketScreenState();
}

class _AgriculturalMarketScreenState extends State<AgriculturalMarketScreen> {
  int _selectedCategoryIndex = 0;
  int _cartCount = 0;
  // Thêm biến này để lưu tổng tiền thực tế
  double _currentTotalValue = 0.0;
  final List<Product> _productList = _products; // mutable local copy

  // ── Cart logic ────────────────────────────────────────────────────────────

  // Thêm một danh sách để lưu các ID sản phẩm đã chọn
  List<String> _selectedProductIds = [];

  // Sửa: Thêm tham số double price vào đây
  void _addToCart(String productId, double price) {
    setState(() {
      _cartCount++;
      // Bây giờ biến price đã tồn tại nhờ tham số truyền vào
      _currentTotalValue += price;
      _selectedProductIds.add(productId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã thêm vào giỏ hàng!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleFavourite(Product product) {
    setState(() => product.isFavourite = !product.isFavourite);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // ── Green header accent + search bar ──
          Container(
            color: const Color(0xFF2E7D32),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: _buildSearchBar(),
          ),
          _buildPostProductSection(context),
          // const SizedBox(height: 20),
          _buildFilterRow(),
          // ── Product grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text('Đã xảy ra lỗi');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Chuyển đổi dữ liệu từ Firebase thành danh sách ProductModel
                final data = snapshot.requireData;

                return MasonryGridView.count(
                  // 1. Dùng trực tiếp crossAxisCount thay cho gridDelegate
                  crossAxisCount: 2,

                  // 2. Khoảng cách giữa các item
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,

                  // 3. Các thông số layout
                  padding: const EdgeInsets.all(12),
                  itemCount: data.size,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    // Lấy từng document từ Firebase
                    var doc = data.docs[index];
                    var item = doc.data() as Map<String, dynamic>;

                    // Tạo ProductModel từ dữ liệu Firebase
                    final product = ProductModel(
                      id: doc.id,
                      name: item['name'] ?? '',
                      imageUrl: item['imageUrl'] ?? '',
                      unit: item['classification']?['unit'] ?? 'Cái',
                      retailPrice: (item['pricing']?['retailPrice'] ?? 0).toDouble(),
                      quantity: item['inventory']?['quantity'] ?? 0,
                      isUnlimited: item['inventory']?['isUnlimited'] ?? false,
                      // Các trường khác bạn điền tương tự...
                      sku: item['sku'] ?? '',
                      description: item['description'] ?? '',
                      sellerId: item['seller']?['id'] ?? '',
                      sellerName: item['seller']?['name'] ?? '',
                      sellerType: item['seller']?['type'] ?? 'user',
                      marketId: item['classification']?['marketId'] ?? '',
                      categoryId: item['classification']?['categoryId'] ?? '',
                      wholesaleBasePrice: (item['pricing']?['wholesaleBasePrice'] ?? 0).toDouble(),
                      wholesaleTiers: List<Map<String, dynamic>>.from(item['pricing']?['wholesaleTiers'] ?? []),
                      dimensions: Map<String, dynamic>.from(item['inventory']?['dimensions'] ?? {}),
                      isFeatured: item['status']?['isFeatured'] ?? false,
                      isSelling: item['status']?['isSelling'] ?? true,
                    );

                    // Truyền model vào ProductCard
                    return ProductCard(
                      product: product,
                      bgColor: const Color(0xFFFDE8E8),
                      themeColor: const Color(0xFF2E7D32),
                      // Sửa: Truyền cả 2 giá trị vào hàm _addToCart
                      onAddToCart: (id, price) => _addToCart(id, price),
                    );
                  },
                );
              },
            )
          ),
        ],
      ),
      // ── View Cart FAB ──
      bottomNavigationBar: _cartCount > 0 ? _buildCartBar() : null,
    );
  }

  // ---------------------------------------------------------------------------
  // PRIVATE WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  /// Custom AppBar with back button, title and cart/notification actions.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2E7D32), // Màu xanh lá đậm đẹp rồi, giữ nguyên nhé
      elevation: 0,
      centerTitle: false, // Để tiêu đề sát lề trái giống trong ảnh của bạn
      leading: IconButton(
        // Chỉnh icon về màu trắng
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: const Text(
        'Agricultural Market',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 0.3,
          color: Colors.white, // Chỉnh chữ sang màu trắng
        ),
      ),
      actions: [
        // Notification bell
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70), // Trắng mờ nhẹ
          onPressed: () {},
        ),
        // Cart icon with badge
        Stack(
          alignment: Alignment.center,
          children: [
            // Tại AppBar -> actions
            // Tại AppBar -> actions: Thay thế đoạn Stack cũ bằng đoạn này
            StreamBuilder<QuerySnapshot>(
              // Lắng nghe trực tiếp từ giỏ hàng của User trên Firestore
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('cart')
                  .snapshots(),
              builder: (context, snapshot) {
                // Mặc định là 0 nếu chưa có dữ liệu
                int totalItems = 0;

                if (snapshot.hasData) {
                  // Đếm số lượng loại sản phẩm có trong giỏ
                  totalItems = snapshot.data!.docs.length;
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CartScreen(selectedIds: _selectedProductIds),
                          ),
                        );
                      },
                    ),
                    // Chỉ hiển thị Badge khi có sản phẩm
                    if (totalItems > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252), // Màu đỏ nổi bật
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '$totalItems',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (_cartCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252), // Đổi sang màu đỏ cam cho nổi bật
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF2E7D32), width: 1.5), // Viền trùng màu nền sẽ đẹp hơn
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '$_cartCount',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
  /// Đăng sản phẩm
  Widget _buildPostProductSection(BuildContext context) { // Thêm context vào đây
    return GestureDetector(
      onTap: () {
        // Lệnh chuyển trang
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateProductScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.person, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Bạn muốn đăng bán sản phẩm gì?',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
            Icon(Icons.image_outlined, color: Colors.green.shade700),
          ],
        ),
      ),
    );
  }
  /// Rounded search bar with prefix icon and a filter button.
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search produce, seeds…',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Filter button
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFFFA000),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA000).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  /// Horizontal scrolling categories list.


  /// Quick filter chips row (Rating / Sort / Organic toggle).
  Widget _buildFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _filterChip(Icons.star_rounded, 'Rating', const Color(0xFFFFA000)),
          const SizedBox(width: 8),
          _filterChip(Icons.sort_rounded, 'Sort', const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          _filterChip(Icons.eco_rounded, 'Organic', const Color(0xFF8D6E63)),
          const Spacer(),
          Text(
            '${_productList.length} items',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// A single reusable filter chip widget.
  Widget _filterChip(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.expand_more_rounded, size: 13, color: color),
          ],
        ),
      ),
    );
  }

  /// 2-column product grid.


  /// A single product card widget.


  /// Persistent bottom bar showing cart item count and total.
  Widget _buildCartBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          // --- CẬP NHẬT Ở ĐÂY ---
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartScreen(selectedIds: _selectedProductIds),
              ),
            );
          },
          // ----------------------
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Badge số lượng (ví dụ: 5x)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_cartCount}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Xem giỏ hàng',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_currentTotalValue)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  // Nhận trực tiếp model để lấy dữ liệu cho tiện
  final ProductModel product;
  final Color bgColor;
  final Color themeColor;
  final Function(String, double) onAddToCart;
  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart, // Thêm vào constructor
    this.bgColor = const Color(0xFFFDE8E8), // Màu nền mặc định như ảnh (hồng nhạt)
    this.themeColor = const Color(0xFFE57373), // Màu badge giá mặc định (đỏ nhạt)
  });
  Future<void> addToCart(ProductModel product) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("Người dùng chưa đăng nhập!");
        return;
      }

      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      final docSnapshot = await cartRef.doc(product.id).get();

      if (docSnapshot.exists) {
        // Already in cart — only increment quantity; seller data already stamped
        await cartRef.doc(product.id).update({
          'quantity': FieldValue.increment(1),
        });
      } else {
        // New cart item — stamp full schema including seller attribution
        await cartRef.doc(product.id).set({
          'productId': product.id,
          'name': product.name,
          'imageUrl': product.imageUrl,
          'price': product.retailPrice,   // cached for UI display, untrusted at checkout
          'quantity': 1,
          // Seller fields: root-level for efficient grouping in CartScreen.
          // sellerName is denormalized for UI only — authoritative name is
          // fetched fresh from the users collection during checkout.
          'sellerId': product.sellerId,
          'sellerName': product.sellerName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      print("Đã thêm ${product.name} vào giỏ hàng thành công!");
    } catch (e) {
      print("Lỗi khi thêm vào giỏ hàng: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Sử dụng InkWell để bắt sự kiện nhấn vào toàn bộ vùng trên của Card
            InkWell(
              // Trong ListView của ProductCategoryScreen
              onTap: () {
                final String docId = product.id!; // Sửa lỗi gán null ở đây

                if (docId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(productId: docId),
                    ),
                  );
                } else {
                  print("Lỗi: Không tìm thấy ID của sản phẩm này!");
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. PHẦN ẢNH
                  Stack(
                    children: [
                      Container(
                        height: 140,
                        width: double.infinity,
                        color: bgColor,
                        child: product.imageUrl.isNotEmpty
                            ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        )
                            : const Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          radius: 15,
                          child: Icon(Icons.favorite_border, size: 18, color: Colors.grey[400]),
                        ),
                      ),
                      // BADGE GIÁ
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            "${currencyFormatter.format(product.retailPrice)} / ${product.unit}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 2. THÔNG TIN CHỮ
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0), // Bỏ padding bottom để sát nút bấm
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: product.quantity < 5 ? Colors.red : Colors.green),
                            const SizedBox(width: 5),
                            Text(
                              "${product.quantity} sản phẩm sẵn có",
                              style: TextStyle(fontSize: 11, color: product.quantity < 5 ? Colors.red : Colors.green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        const Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.orange),
                            SizedBox(width: 4),
                            Text("4.8", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. NÚT "THÊM VÀO GIỎ" (Nằm ngoài InkWell để bắt sự kiện riêng)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  // Tìm đến nút bấm và sửa phần onPressed
                  onPressed: () {
                    addToCart(product);
                    // Sửa: Truyền cả ID và giá bán lẻ
                    onAddToCart(product.id!, product.retailPrice);
                    print("Đã thêm ${product.name} vào danh sách ID");
                  },
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18, color: Colors.white),
                  label: const Text("Thêm vào giỏ", style: TextStyle(color: Colors.white, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}