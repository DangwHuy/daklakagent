import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


// ═══════════════════════ EXCEPTION ═══════════════════════

/// Thrown inside the checkout transaction when a price mismatch is detected.
/// Carries the fresh prices out of the rolled-back transaction so the external
/// handler can commit a cart-patch batch as a standalone write.
class _PriceMismatchException implements Exception {
  /// Maps cartDocumentId → freshPrice fetched from Firestore.
  final Map<String, double> freshPrices;
  _PriceMismatchException(this.freshPrices);
}
// ═══════════════════════ COLORS ═══════════════════════

class AgriColors {
  static const bg = Color(0xFFF4F1E8);
  static const cardBg = Color(0xFFFFFDF5);
  static const green1 = Color(0xFF2D5A1B);
  static const green2 = Color(0xFF4A7C3F);
  static const green3 = Color(0xFF7DB668);
  static const green4 = Color(0xFFBED8A8);
  static const brown1 = Color(0xFF6B4226);
  static const brown2 = Color(0xFF9B6B4A);
  static const soil = Color(0xFFD4A96A);
  static const straw = Color(0xFFE8C870);
  static const orange = Color(0xFFD97706);
  static const text1 = Color(0xFF1C2B0F);
  static const text2 = Color(0xFF4A5540);
  static const divider = Color(0xFFD4C89A);
}

// ═══════════════════════ DATA MODEL ═══════════════════════

class CartItem {
  final String id;          // Firestore cart document ID (= productId)
  final String sellerId;
  final String shopName;    // denormalized for UI, untrusted at checkout
  final String productName;
  final double price;       // cached for UI, untrusted at checkout
  final String imageUrl;
  bool selected;
  int quantity;

  CartItem({
    required this.id,
    required this.sellerId,
    required this.shopName,
    required this.productName,
    required this.price,
    required this.imageUrl,
    this.selected = true,
    this.quantity = 1,
  });

  /// Reads the new flat schema written by AgriMarketApp.dart.
  /// Backward-compatible with legacy nested `seller: {id, name}` maps and
  /// older flat `sellerId` / `shopName` fields.
  factory CartItem.fromCartDoc(Map<String, dynamic> data, String docId) {
    // Priority: new flat field → legacy nested map → older flat field → default
    final sellerMap = data['seller'] is Map
        ? data['seller'] as Map<String, dynamic>
        : <String, dynamic>{};

    return CartItem(
      id: docId,
      sellerId: data['sellerId'] as String?
          ?? sellerMap['id'] as String?
          ?? 'unknown',
      shopName: data['sellerName'] as String?
          ?? sellerMap['name'] as String?
          ?? data['shopName'] as String?
          ?? 'Cửa hàng nông sản',
      productName: data['name'] as String? ?? 'Sản phẩm',
      price: (data['price'] as num? ?? 0).toDouble(),
      imageUrl: data['imageUrl'] as String? ?? '',
      quantity: data['quantity'] as int? ?? 1,
    );
  }
}


// ═══════════════════════ CART SCREEN ═══════════════════════

class CartScreen extends StatefulWidget {
  // 1. Khai báo biến nhận dữ liệu
  final List<String> selectedIds;

  // 2. Thêm vào constructor
  const CartScreen({super.key, required this.selectedIds});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _leafCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _leafAnim;
  @override
  void initState() {
    super.initState();
    _fetchCartData();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
        begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _headerCtrl, curve: Curves.easeOutCubic));

    _leafCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _leafAnim = Tween<double>(begin: -0.08, end: 0.08).animate(
        CurvedAnimation(parent: _leafCtrl, curve: Curves.easeInOut));

    _headerCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _leafCtrl.dispose();
    super.dispose();
  }

  bool get allSelected => _items.every((i) => i.selected);
  double get totalPrice =>
      _items.where((i) => i.selected).fold(0, (s, i) => s + i.price * i.quantity);
  int get selectedCount => _items.where((i) => i.selected).length;
  List<CartItem> _items = [];
  bool _isLoading = true;

  // CẤP ĐỘ 1: Getter để gộp dữ liệu theo Cửa hàng (shopName)
  Map<String, List<CartItem>> get groupedByShop {
    Map<String, List<CartItem>> groups = {};
    for (var item in _items) {
      if (!groups.containsKey(item.sellerId)) {
        groups[item.sellerId] = [];
      }
      groups[item.sellerId]!.add(item);
    }
    return groups;
  }
  Future<void> _syncCartToFirestore() async {
    // Giả sử bạn đã có userId của người dùng đang đăng nhập
    String? userId = "USER_ID_HIEN_TAI";
    if (userId == null) return;

    final cartData = {
      'items': _items.map((item) => {
        'productId': item.id,
        'quantity': item.quantity,
        'selected': item.selected,
      }).toList(),
      'lastUpdate': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('carts')
        .doc(userId)
        .set(cartData);
  }
  Future<void> _checkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt hàng!')),
      );
      return;
    }

    final selectedItems = _items.where((i) => i.selected).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 sản phẩm!')),
      );
      return;
    }

    // ── PRE-STEP: Aggregate by productId ──────────────────────────────────
    // Prevents multiple txn.update() calls on the same document, which is
    // invalid in a single Firestore transaction and causes incorrect increments.
    final Map<String, ({CartItem item, int totalQty})> aggregated = {};
    for (final item in selectedItems) {
      if (aggregated.containsKey(item.id)) {
        final existing = aggregated[item.id]!;
        aggregated[item.id] = (item: existing.item, totalQty: existing.totalQty + item.quantity);
      } else {
        aggregated[item.id] = (item: item, totalQty: item.quantity);
      }
    }
    final uniqueProductIds = aggregated.keys.toList();
    final uniqueSellerIds  = selectedItems.map((i) => i.sellerId).toSet().toList();

    final db          = FirebaseFirestore.instance;
    final ordersRef   = db.collection('orders');
    final productsRef = db.collection('products');
    final usersRef    = db.collection('users');
    final cartRef     = db.collection('users').doc(user.uid).collection('cart');

    // Show loading spinner
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AgriColors.green1),
        ),
      );
    }

    try {
      await db.runTransaction((txn) async {

        // ── PHASE 1: ALL READS (unique documents only) ───────────────────
        // All txn.get() calls must complete before the first txn.set/update/delete.
        final productSnaps = await Future.wait(
          uniqueProductIds.map((id) => txn.get(productsRef.doc(id))),
        );
        final sellerSnaps = await Future.wait(
          uniqueSellerIds.map((id) => txn.get(usersRef.doc(id))),
        );
        // ── NO MORE READS AFTER THIS LINE ────────────────────────────────

        // ── PHASE 2: VALIDATE ────────────────────────────────────────────
        final Map<String, double> stalePrices = {}; // productId → fresh price

        for (final snap in productSnaps) {
          if (!snap.exists) throw Exception('Sản phẩm không tồn tại.');
          final agg        = aggregated[snap.id]!;
          final freshPrice = (snap.get('pricing.retailPrice') as num).toDouble();
          final freshStock = snap.get('inventory.quantity') as int;

          // Stock check uses AGGREGATED total quantity — handles duplicate productIds
          if (freshStock < agg.totalQty) {
            throw Exception('Hết hàng: ${agg.item.productName} '
                '(yêu cầu ${agg.totalQty}, còn $freshStock)');
          }

          // Price check INSIDE transaction — guards against TOCTOU race condition
          if ((freshPrice - agg.item.price).abs() > 0.001) {
            stalePrices[snap.id] = freshPrice;
          }
        }

        if (stalePrices.isNotEmpty) {
          // Throw typed exception. Transaction rolls back cleanly here (no writes
          // have been executed yet). The external catch block handles cart patching.
          throw _PriceMismatchException(stalePrices);
        }

        // ── PHASE 3: ALL WRITES (unique documents only) ──────────────────
        // 3a. Decrement stock atomically — one update per unique productId
        for (final snap in productSnaps) {
          final agg = aggregated[snap.id]!;
          txn.update(productsRef.doc(snap.id), {
            'inventory.quantity': FieldValue.increment(-agg.totalQty),
          });
        }

        // 3b. One order document per seller with fresh, authoritative seller name
        for (final sellerId in uniqueSellerIds) {
          final sellerSnap = sellerSnaps.firstWhere(
            (s) => s.id == sellerId,
            orElse: () => throw Exception('Không tìm thấy người bán: $sellerId'),
          );
          final freshSellerName =
              sellerSnap.data()?['displayName'] as String? ?? 'Người bán';

          final shopItems = selectedItems
              .where((i) => i.sellerId == sellerId)
              .toList();
          final shopTotal = shopItems.fold(
            0.0,
            (sum, i) => sum + i.price * i.quantity,
          );

          txn.set(ordersRef.doc(), {
            'sellerId':    sellerId,           // root-level — required for AI pipeline
            'sellerName':  freshSellerName,    // authoritative: from users collection
            'customerId':  user.uid,
            'totalAmount': shopTotal,
            'status':      'Pending',
            'createdAt':   FieldValue.serverTimestamp(),
            'items': shopItems.map((i) => {
              'productId': i.id,
              'name':      i.productName,
              'price':     i.price,
              'quantity':  i.quantity,
              'imageUrl':  i.imageUrl,
              'sellerId':  i.sellerId,
            }).toList(),
          });
        }

        // 3c. Delete all purchased cart entries (one per cart document)
        for (final item in selectedItems) {
          txn.delete(cartRef.doc(item.id));
        }
      });

      // ── SUCCESS ──────────────────────────────────────────────────────────
      if (mounted) Navigator.pop(context); // Close spinner
      if (mounted) {
        setState(() => _items.removeWhere((i) => i.selected));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '🎉 Đặt hàng thành công! '
            '(${uniqueSellerIds.length} đơn từ ${uniqueSellerIds.length} người bán)',
          ),
          backgroundColor: AgriColors.green1,
        ));
      }

    } on _PriceMismatchException catch (e) {
      // ── PRICE MISMATCH: patch cart prices OUTSIDE the rolled-back txn ──
      if (mounted) Navigator.pop(context); // Close spinner

      // Commit price corrections as plain writes — guaranteed to persist
      final pricePatch = db.batch();
      for (final entry in e.freshPrices.entries) {
        final affectedItems = selectedItems.where((i) => i.id == entry.key);
        for (final item in affectedItems) {
          pricePatch.update(cartRef.doc(item.id), {'price': entry.value});
        }
      }
      await pricePatch.commit();
      await _fetchCartData(); // Reload cart with updated prices

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            '⚠️ Giá một số sản phẩm đã thay đổi. Vui lòng kiểm tra lại giỏ hàng.',
          ),
          duration: Duration(seconds: 4),
        ));
      }

    } catch (e) {
      if (mounted) Navigator.pop(context); // Close spinner
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchCartData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _isLoading = false);
        return;
      }

      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cart')
          .get();

      final tempItems = cartSnapshot.docs
          .map((doc) => CartItem.fromCartDoc(doc.data(), doc.id))
          .toList();

      setState(() {
        _items = tempItems;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi load giỏ hàng: $e');
      setState(() => _isLoading = false);
    }
  }

  void _toggleSelectAll(bool? val) =>
      setState(() { for (var i in _items) { i.selected = val ?? false; } });

  void _toggleItem(int idx, bool val) =>
      setState(() => _items[idx].selected = val);

  void _changeQty(int idx, int delta) => setState(() {
    final nq = _items[idx].quantity + delta;
    if (nq >= 1) _items[idx].quantity = nq;
  });
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AgriColors.green1));
    }
    if (_items.isEmpty) {
      return const Center(child: Text("Giỏ hàng trống"));
    }

    return // Trong widget build(BuildContext context) -> Expanded
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 8),
          itemCount: groupedByShop.keys.length, // Số lượng shop
          itemBuilder: (ctx, index) {
            String shopId = groupedByShop.keys.elementAt(index);
            List<CartItem> shopProducts = groupedByShop[shopId]!;

            return _ShopGroupCard(
              shopName: shopProducts.first.shopName,
              items: shopProducts,
              leafAnim: _leafAnim,
              // Chuyển các callback xử lý logic (toggle, changeQty) tương ứng với phần tử trong _items
              onToggle: (item) => setState(() => item.selected = !item.selected),
              onQtyChange: (item, delta) => setState(() {
                if (item.quantity + delta >= 1) item.quantity += delta;
              }),
            );
          },
        ),
      );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AgriColors.bg,
      body: Column(
        children: [
          SlideTransition(
            position: _headerSlide,
            child: FadeTransition(opacity: _headerFade, child: _buildAppBar()),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _items.length,
              itemBuilder: (ctx, i) => _AnimatedItemTile(
                key: ValueKey(_items[i].id),
                item: _items[i],
                index: i,
                leafAnim: _leafAnim,
                onToggle: (v) => _toggleItem(i, v),
                onQtyChange: (d) => _changeQty(i, d),
              ),
            ),
          ),
          _buildVoucherRow(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AgriColors.green1, AgriColors.green2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 14,
        left: 14,
        right: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context), // Quay lại màn hình trước đó
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.arrow_back, color: Color(0xFFEE4D2D), size: 22),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedBuilder(
            animation: _leafAnim,
            builder: (ctx, _) => Transform.rotate(
              angle: _leafAnim.value * 0.5,
              child: const Text('🧺', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Giỏ Nông Sản',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3)),
              Text('Tươi từ vườn đến bàn',
                  style: TextStyle(
                      fontSize: 10,
                      color: AgriColors.green4,
                      letterSpacing: 0.5)),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AgriColors.straw,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${_items.length}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AgriColors.brown1,
                    fontWeight: FontWeight.w800)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Text('Sửa',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AgriColors.straw,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.chat_bubble_outline,
                color: AgriColors.brown1, size: 17),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AgriColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AgriColors.divider),
        boxShadow: [
          BoxShadow(
              color: AgriColors.green2.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AgriColors.green4,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('🎟️', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          const Text('Voucher Nông Sản',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AgriColors.text1)),
          const Spacer(),
          Text('Chọn hoặc nhập mã',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AgriColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: AgriColors.green1.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleSelectAll(!allSelected),
            child: Row(
              children: [
                _AgriCheckbox(selected: allSelected),
                const SizedBox(width: 6),
                const Text('Tất cả',
                    style: TextStyle(fontSize: 13, color: AgriColors.text2)),
              ],
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tổng thanh toán',
                  style: TextStyle(fontSize: 10, color: AgriColors.text2)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _fmt(totalPrice),
                  key: ValueKey(totalPrice),
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AgriColors.green1),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: selectedCount > 0 ? _checkout : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: selectedCount > 0
                    ? const LinearGradient(
                  colors: [AgriColors.green1, AgriColors.green2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: selectedCount > 0 ? null : Colors.grey[300],
                borderRadius: BorderRadius.circular(24),
                boxShadow: selectedCount > 0
                    ? [
                  BoxShadow(
                      color: AgriColors.green2.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(selectedCount > 0 ? '🛒' : '🧺',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    'Mua ($selectedCount)',
                    style: TextStyle(
                      color: selectedCount > 0 ? Colors.white : Colors.grey[500],
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double p) {
    if (p == 0) return '0đ';
    return '${p.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
  }
}

// ═══════════════════════ ANIMATED ITEM TILE ═══════════════════════

class _AnimatedItemTile extends StatefulWidget {
  final CartItem item;
  final int index;
  final Animation<double> leafAnim;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onQtyChange;

  const _AnimatedItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.leafAnim,
    required this.onToggle,
    required this.onQtyChange,
  });

  @override
  State<_AnimatedItemTile> createState() => _AnimatedItemTileState();
}

class _AnimatedItemTileState extends State<_AnimatedItemTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500 + widget.index * 60));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
        begin: const Offset(0.06, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 80),
            () { if (mounted) _ctrl.forward(); });
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
      child: SlideTransition(
        position: _slide,
        child: _ItemCard(
          item: widget.item,
          leafAnim: widget.leafAnim,
          onToggle: widget.onToggle,
          onQtyChange: widget.onQtyChange,
        ),
      ),
    );
  }
}

// ═══════════════════════ ITEM CARD ═══════════════════════

class _ItemCard extends StatelessWidget {
  final CartItem item;
  final Animation<double> leafAnim;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onQtyChange;

  const _ItemCard({
    required this.item,
    required this.leafAnim,
    required this.onToggle,
    required this.onQtyChange,
  });

  String _fmt(double p) =>
      '${p.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
  int _disc(double s, double o) => (((o - s) / o) * 100).round();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      decoration: BoxDecoration(
        color: AgriColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.selected ? AgriColors.green3 : AgriColors.divider,
          width: item.selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: item.selected
                ? AgriColors.green2.withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Shop header - ĐÃ BỎ BADGE CHỨNG NHẬN
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => onToggle(!item.selected),
                  child: _AgriCheckbox(selected: item.selected),
                ),
                const SizedBox(width: 8),
                // _BadgeChip(badge: item.shopBadge), // <-- Dòng này đã được loại bỏ
                Expanded(
                  child: Text(item.shopName,
                      style: const TextStyle(
                          fontSize: 13, // Tăng size nhẹ vì không còn badge
                          fontWeight: FontWeight.w700,
                          color: AgriColors.text1),
                      overflow: TextOverflow.ellipsis),
                ),
                const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                const Text('Sửa',
                    style: TextStyle(fontSize: 11, color: AgriColors.text2)),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: AgriColors.divider, indent: 14),

          // Product row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => onToggle(!item.selected),
                  child: _AgriCheckbox(selected: item.selected),
                ),
                const SizedBox(width: 8),
                _ProductImage(
                    imageUrl: item.imageUrl,
                    selected: item.selected,
                    leafAnim: leafAnim),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AgriColors.text1,
                              fontWeight: FontWeight.w500,
                              height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),

                      // ĐÃ BỎ PHẦN CHỌN PHÂN LOẠI (VARIANT) Ở ĐÂY

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_fmt(item.price),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AgriColors.green1)),

                              ],
                            ),
                          ),
                          _QtyControl(
                            qty: item.quantity,
                            onMinus: () => onQtyChange(-1),
                            onPlus: () => onQtyChange(1),
                          ),
                        ],
                      ),

                      // ĐÃ BỎ PHẦN HIỂN THỊ % GIẢM GIÁ Ở ĐÂY
                    ],
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }







}

// ═══════════════════════ PRODUCT IMAGE ═══════════════════════

class _ProductImage extends StatelessWidget {
  final String imageUrl; // Đổi từ emoji sang imageUrl
  final bool selected;
  final Animation<double> leafAnim;

  const _ProductImage({
    required this.imageUrl,
    required this.selected,
    required this.leafAnim
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: leafAnim,
      builder: (ctx, _) => Transform.rotate(
        angle: selected ? leafAnim.value * 0.15 : 0,
        child: Container(
          width: 86,
          height: 86,
          clipBehavior: Clip.antiAlias, // Để ảnh bo góc theo container
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AgriColors.green3 : AgriColors.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : const Center(child: Icon(Icons.image_not_supported)),
        ),
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AgriColors.green2.withOpacity(0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      final y = size.height * (i + 1) / 6;
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width * 0.5, y + 3, size.width, y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════ BADGE CHIP ═══════════════════════

class _BadgeChip extends StatelessWidget {
  final String badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final data = _data(badge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: data.$2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(data.$1,
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  (String, List<Color>) _data(String badge) {
    switch (badge) {
      case 'organic':
        return ('🌿 HỮU CƠ', [const Color(0xFF2D5A1B), const Color(0xFF4A7C3F)]);
      case 'vietgap':
        return ('✅ VIETGAP', [const Color(0xFF1565C0), const Color(0xFF1976D2)]);
      default:
        return ('⭐ CHỨNG NHẬN', [const Color(0xFF6B4226), const Color(0xFF9B6B4A)]);
    }
  }
}

// ═══════════════════════ QTY CONTROL ═══════════════════════

class _QtyControl extends StatefulWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QtyControl(
      {required this.qty, required this.onMinus, required this.onPlus});

  @override
  State<_QtyControl> createState() => _QtyControlState();
}

class _QtyControlState extends State<_QtyControl>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.3)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 1.0)
              .chain(CurveTween(curve: Curves.bounceOut)),
          weight: 50),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_QtyControl old) {
    super.didUpdateWidget(old);
    if (old.qty != widget.qty) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AgriColors.green4.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AgriColors.green3.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QBtn(label: '−', onTap: widget.qty > 1 ? widget.onMinus : null),
          AnimatedBuilder(
            animation: _scale,
            builder: (ctx, _) => Transform.scale(
              scale: _scale.value,
              child: SizedBox(
                width: 28,
                child: Text('${widget.qty}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AgriColors.green1)),
              ),
            ),
          ),
          _QBtn(label: '+', onTap: widget.onPlus),
        ],
      ),
    );
  }
}

class _QBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _QBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? AgriColors.green2
              : AgriColors.green4.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: enabled ? Colors.white : Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1)),
        ),
      ),
    );
  }
}

// ═══════════════════════ AGRI CHECKBOX ═══════════════════════

class _AgriCheckbox extends StatelessWidget {
  final bool selected;
  const _AgriCheckbox({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 21,
      height: 21,
      decoration: BoxDecoration(
        color: selected ? AgriColors.green2 : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected
              ? AgriColors.green2
              : AgriColors.brown2.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: selected
            ? [
          BoxShadow(
              color: AgriColors.green2.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ]
            : null,
      ),
      child: selected
          ? const Icon(Icons.check, color: Colors.white, size: 13)
          : null,
    );
  }
}


class _ShopGroupCard extends StatelessWidget {
  final String shopName;
  final List<CartItem> items;
  final Animation<double> leafAnim;
  final Function(CartItem) onToggle;
  final Function(CartItem, int) onQtyChange;

  const _ShopGroupCard({
    required this.shopName,
    required this.items,
    required this.leafAnim,
    required this.onToggle,
    required this.onQtyChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      decoration: BoxDecoration(
        color: AgriColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AgriColors.divider),
      ),
      child: Column(
        children: [
          // Tiêu đề Shop (Chỉ hiện 1 lần)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.storefront, size: 18, color: AgriColors.green1),
                const SizedBox(width: 8),
                Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                const Text('Sửa', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Danh sách sản phẩm của shop này
          ...items.map((item) => _buildProductRow(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildProductRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onToggle(item),
            child: _AgriCheckbox(selected: item.selected),
          ),
          const SizedBox(width: 10),
          _ProductImage(imageUrl: item.imageUrl, selected: item.selected, leafAnim: leafAnim),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${item.price.toInt()}đ",
                        style: const TextStyle(color: AgriColors.green1, fontWeight: FontWeight.bold)),
                    _QtyControl(
                      qty: item.quantity,
                      onMinus: () => onQtyChange(item, -1),
                      onPlus: () => onQtyChange(item, 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}