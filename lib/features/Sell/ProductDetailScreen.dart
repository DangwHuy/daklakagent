import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// ─── Màu chủ đề nông nghiệp ────────────────────────────────────────────────
const kGreen = Color(0xFF2E7D32);
const kGreenLight = Color(0xFF4CAF50);
const kBgGreen = Color(0xFFE8F5E9);
const kYellowEarth = Color(0xFFFF8F00);

// ─── Widget Fade+Slide khi xuất hiện ────────────────────────────────────────
class _AnimatedSection extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _AnimatedSection({required this.child, this.delay = Duration.zero});

  @override
  State<_AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── Widget floating (lên xuống liên tục) ───────────────────────────────────
class _FloatingWidget extends StatefulWidget {
  final Widget child;
  const _FloatingWidget({required this.child});

  @override
  State<_FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<_FloatingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _anim = Tween<double>(begin: -6, end: 6).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);

  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _anim.value), child: child),
      child: widget.child,
    );
  }
}

// ─── Màn hình chính ─────────────────────────────────────────────────────────
class ProductDetailScreen extends StatefulWidget {

  final String productId;
  const ProductDetailScreen({super.key,required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  int _selectedTypeIndex = 0;
  int _selectedImageIndex = 0;
  bool _isFavorite = false;

  // ── Animation controllers ──
  late final AnimationController _favoriteCtrl;
  late final Animation<double> _favoriteScale;

  late final AnimationController _buyBtnCtrl;
  late final Animation<double> _buyBtnScale;

  // ── Countdown timer ──
  Timer? _countdownTimer;
  int _remainSeconds = 2 * 3600 + 45 * 60 + 18; // 02:45:18

  final List<String> _typeNames = ['Cán gỗ', 'Cán inox', 'Cán nhựa'];
  final List<Color> _typeColors = [
    const Color(0xFF795548),
    Colors.grey,
    const Color(0xFF1565C0),
  ];

  final List<Map<String, dynamic>> _features = [
    {'text': 'Thép không gỉ, bền bỉ lâu dài'},
    {'text': 'Chống gỉ sét - dùng ngoài trời'},
    {'text': 'Cán dài 1.2m, tiết kiệm sức'},
    {'text': 'Thích hợp đất ruộng & vườn'},
    {'text': 'Bảo hành 12 tháng'},
  ];
  // ── [AI Pipeline] Per-user, per-session view tracking ───────────────────
  // Scoped to session to prevent metric inflation from a single user.
  // Cleared on logout to prevent cross-user leakage on shared devices.
  static final Set<String> _viewedProductIds = {};
  static StreamSubscription<User?>? _authListener;

  late Stream<DocumentSnapshot> _productStream;
  @override
  void initState() {
    super.initState();
    _productStream = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .snapshots();

    // Clear session cache when the user logs out
    _authListener ??= FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) _viewedProductIds.clear();
    });

    // Record view: only once per session, only if user stays ≥2 seconds
    if (!_viewedProductIds.contains(widget.productId)) {
      Future.delayed(const Duration(seconds: 2), () async {
        if (!mounted) return; // User left quickly — do not count
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;
        try {
          // Write to dedicated sub-collection, NOT the products document.
          // Using userId as the doc ID guarantees at-most-one log per user.
          // Firestore rules restrict this collection to create-only.
          await FirebaseFirestore.instance
              .collection('product_views')
              .doc(widget.productId)
              .collection('logs')
              .doc(currentUser.uid)
              .set(
                {'viewedAt': FieldValue.serverTimestamp()},
                SetOptions(merge: false), // Fails if already exists → silent dedup
              );
          _viewedProductIds.add(widget.productId);
        } catch (_) {
          // Log doc already exists (user has viewed before) — ignore silently
        }
      });
    }
    // ─────────────────────────────────────────────────────────────────────

    // Favorite bounce
    _favoriteCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _favoriteScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _favoriteCtrl, curve: Curves.easeOut));

    // Buy button press
    _buyBtnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _buyBtnScale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _buyBtnCtrl, curve: Curves.easeIn));

    // Countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainSeconds > 0) _remainSeconds--;
      });
    });
  }



  @override
  void dispose() {
    _favoriteCtrl.dispose();
    _buyBtnCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _countdownText {
    final h = (_remainSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_remainSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_remainSeconds % 60).toString().padLeft(2, '0');
    return '$h : $m : $s';
  }

  void _onFavoriteTap() {
    HapticFeedback.lightImpact();
    setState(() => _isFavorite = !_isFavorite);
    _favoriteCtrl.forward(from: 0);
  }

  void _onBuyTap() async {
    HapticFeedback.mediumImpact();
    await _buyBtnCtrl.forward();
    await _buyBtnCtrl.reverse();
  }

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _productStream,
      builder: (context, snapshot) {
        // 1. Kiểm tra trạng thái tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: kGreen)));
        }

        // 2. Kiểm tra lỗi hoặc dữ liệu trống
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
            body: const Center(child: Text("Sản phẩm không tồn tại hoặc đã bị xóa.")),
          );
        }

        // 3. Ép kiểu dữ liệu từ Firebase
        // Giả sử đoạn này nằm trong StreamBuilder
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String name = data['name'] ?? '';
        final String imageUrl = data['imageUrl'] ?? '';
        final String description = data['description'] ?? '';
        final String unit = data['unit'] ?? 'cái';
        final Map<String, dynamic> pricing = data['pricing'] ?? {};
        final dynamic rawPrice = pricing['retailPrice'] ?? 0;

// 3. Lấy thông số (Các trường này nằm ở cấp ngoài cùng, không phải trong dimensions)
        // Sử dụng num để chấp nhận cả int và double từ Firestore, sau đó mới convert
        // 1. Lấy Map 'inventory' (lớp ngoài)
        final Map<String, dynamic> inventory = data['inventory'] ?? {};

// 2. Lấy Map 'dimensions' (nằm trong inventory)
        final Map<String, dynamic> dimensions = inventory['dimensions'] ?? {};

// 3. Bây giờ mới lấy các con số thực sự
        final double length = (dimensions['length'] as num? ?? 0).toDouble();
        final double width  = (dimensions['width'] as num? ?? 0).toDouble();
        final double weight = (dimensions['weight'] as num? ?? 0).toDouble();

// 4. Tạo chuỗi hiển thị
        final String specs = "Dài: $length - Rộng: $width - Nặng: ${weight}kg";

// 4. Định dạng giá để hiển thị
        final String formattedPrice = NumberFormat('#,###').format(rawPrice);

// Lấy thông tin seller từ Map 'seller' trong Firestore
        final Map<String, dynamic> sellerData = data['seller'] ?? {};
        final String sName = sellerData['name'] ?? 'Chưa rõ';
        final String sId = sellerData['id'] ?? '';
        return Scaffold(
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildSliverAppBar(name, imageUrl), // Truyền 2 tham số (Sửa lỗi 244)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildPriceSection(name, formattedPrice, unit), // Truyền 3 tham số (Sửa lỗi 248)
                        ShopeeShopHeader(sellerName: sName, sellerId: sId),
                        _buildSpecifications(description, specs), // Truyền 2 tham số (Sửa lỗi 252)
                      ],
                    ),
                  )
                ],
              ),
              _buildBottomBar(formattedPrice), // Truyền 1 tham số (Sửa lỗi 259)
            ],
          ),
        );
      },
    );
  }

  // ── SliverAppBar ────────────────────────────────────────────────────────────
  // Truyền thêm 2 tham số này vào hàm
  Widget _buildSliverAppBar(String name, String imageUrl) {
    return SliverAppBar(
      expandedHeight: 370,
      pinned: true,
      backgroundColor: Colors.white,
      leading: _circleButton(
        Icons.arrow_back,
        onTap: () => Navigator.maybePop(context),
      ),
      title: Text(
        name, // Dùng biến name ở đây (Hết lỗi 273)
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: imageUrl.isNotEmpty // Dùng imageUrl ở đây (Hết lỗi 279, 281)
            ? Image.network(imageUrl, fit: BoxFit.cover)
            : Container(color: kBgGreen, child: _buildToolIllustration()),
      ),
      actions: [
        _circleButton(Icons.shopping_cart_outlined, badge: '12', onTap: () {}),
        _circleButton(Icons.more_vert, onTap: () {}),
      ],
    );
  }

  Widget _circleButton(IconData icon,
      {String? badge, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: Colors.black87, size: 22),
            ),
            if (badge != null)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration:
                  const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                  child: Text(badge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Product image hero section ──────────────────────────────────────────────


  // ── Tool illustration (giữ nguyên) ─────────────────────────────────────────
  Widget _buildToolIllustration() {
    return SizedBox(
      width: 155, height: 195,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 100, height: 14,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
          Positioned(
            right: 72, top: 0,
            child: Transform.rotate(
              angle: 0.25,
              child: Container(
                width: 13, height: 158,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.brown.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(3, 3))
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 15, bottom: 25,
            child: Transform.rotate(
              angle: 0.25,
              child: Container(
                width: 95, height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [
                        Color(0xFFB0BEC5),
                        Color(0xFF607D8B),
                        Color(0xFF455A64)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(4, 5))
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        5,
                            (_) => Container(
                          width: 11, height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFF37474F),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                          ),
                        ),
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

  Widget _buildFeatureTag(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kGreen.withOpacity(0.82),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildBadgeItem(String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
      ],
    );
  }

  // ── Badge bar (thumbnail images) ────────────────────────────────────────────


  // ── Type selector với AnimatedContainer ─────────────────────────────────────


  // ── Price section với countdown thực ────────────────────────────────────────
  // Định nghĩa hàm nhận 3 tham số
  // Sửa lại tham số rawPrice thành kiểu dynamic hoặc num
  Widget _buildPriceSection(String name, dynamic rawPrice, String unit) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Sửa tại đây: Thêm .toString() hoặc dùng biến formattedPrice đã convert
              Text(
                  rawPrice.toString(),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kGreen)
              ),
              const Text(' đ', style: TextStyle(fontSize: 16, color: kGreen, fontWeight: FontWeight.bold)),
              Text(' / $unit', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w500)),
    );
  }


  Widget _buildSpecifications(String description, String specs) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.straighten, size: 18, color: kGreen), // Icon thước đo
              SizedBox(width: 6),
              Text('Thông số kỹ thuật', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(specs, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
          const Divider(height: 30),
          const Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: kGreen),
              SizedBox(width: 6),
              Text('Mô tả chi tiết', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border:
        Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }



  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar với nút Mua ngay có animation press ──────────────────────────
  Widget _buildBottomBar(String formattedPrice) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2))
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              _buildBottomAction(
                  Icons.chat_bubble_outline, 'Hỏi shop', Colors.black87),
              Container(
                  width: 1, height: 52, color: Colors.grey.shade200),
              _buildBottomAction(
                  Icons.add_shopping_cart, 'Thêm vào\ngiỏ', kGreen),
              // Nút Mua ngay với ScaleTransition
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _onBuyTap,
                  child: ScaleTransition(
                    scale: _buyBtnScale,
                    child: Container(
                      height: 52,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF66BB6A), kGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Mua ngay',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 12)),
                          Text('89.000đ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => HapticFeedback.lightImpact(),
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 9.5, color: color, height: 1.2),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

//Thông  tin shop

class ShopeeShopHeader extends StatelessWidget {
  final String sellerName;
  final String sellerId;

  const ShopeeShopHeader({
    super.key,
    required this.sellerName,
    required this.sellerId
  });

  // Hàm đếm số sản phẩm của seller này
  Future<int> _getProductCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('seller.id', isEqualTo: sellerId)
        .get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo mặc định (vì trong db chưa thấy có link ảnh shop)
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: const Icon(Icons.store, color: kGreen, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerName, // Lấy từ Firebase (ví dụ: "giang")
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _buildOnlineStatus(sellerId),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Xem Shop', style: TextStyle(color: kGreen, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('4.9', 'Đánh giá'),

              // Dùng FutureBuilder để hiển thị số lượng sản phẩm
              FutureBuilder<int>(
                future: _getProductCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.toString() ?? '...';
                  return _buildStatColumn(count, 'Sản phẩm');
                },
              ),

              _buildStatColumn('100%', 'Phản hồi Chat'),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildOnlineStatus(String sId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(sId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(); // Đang tải thì để trống cho đẹp
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("Ngoại tuyến", style: TextStyle(fontSize: 12, color: Colors.grey));
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;

        // LẤY DỮ LIỆU ĐÚNG THEO ẢNH: expertInfo -> isOnline
        Map<String, dynamic>? expertInfo = data['expertInfo'] as Map<String, dynamic>?;
        bool isOnline = expertInfo?['isOnline'] ?? false; // Mặc định false nếu không thấy

        if (isOnline == true) {
          return Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              const Text('Đang hoạt động',
                  style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          );
        } else {
          return const Text("Ngoại tuyến",
              style: TextStyle(fontSize: 12, color: Colors.grey));
        }
      },
    );
  }
  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}