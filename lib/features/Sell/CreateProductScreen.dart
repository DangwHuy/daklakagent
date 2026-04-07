import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:daklakagent/features/Sell/mo_ta_screen.dart';
import 'package:daklakagent/features/Sell/ProductCategoryScreen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Thêm dòng này
import 'dart:io'; // Thêm dòng này
import 'package:image_picker/image_picker.dart'; // Thêm dòng này
import 'package:firebase_storage/firebase_storage.dart';
import 'package:daklakagent/features/Sell/AgriMarketApp.dart';

// Firebase
class ProductModel {
  final String? id;
  final String sku;
  final String name;
  final String imageUrl;
  final String description;
  final String sellerId;
  final String sellerType; // "user" hoặc "shop"
  final String sellerName;
  final String marketId;
  final String categoryId;
  final String unit;
  final double retailPrice;
  final double wholesaleBasePrice;
  final List<Map<String, dynamic>> wholesaleTiers;
  final Map<String, dynamic> dimensions;
  final int quantity;
  final bool isUnlimited;
  final bool isFeatured;
  final bool isSelling;

  ProductModel({
    this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerType,
    required this.sellerName, // 2. THÊM DÒNG NÀY
    required this.marketId,
    required this.categoryId,
    required this.unit,
    required this.retailPrice,
    required this.wholesaleBasePrice,
    required this.wholesaleTiers,
    required this.dimensions,
    required this.quantity,
    required this.isUnlimited,
    required this.isFeatured,
    required this.isSelling,
  });

  // Chuyển Object sang Map để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'name': name,
      'description': description,
      'imageUrl': imageUrl, // Thêm vào Map
      // Trong Map toMap() của ProductModel, Anh sửa lại phần seller:
      'seller': {
        'id': sellerId,
        'type': sellerType,
        'name': sellerName, // Thêm trường này vào Firestore
      },
      'classification': {
        'marketId': marketId,
        'categoryId': categoryId,
        'unit': unit,
      },
      'pricing': {
        'retailPrice': retailPrice,
        'wholesaleBasePrice': wholesaleBasePrice,
        'wholesaleTiers': wholesaleTiers,
      },
      'inventory': {
        'dimensions': dimensions,
        'quantity': quantity,
        'isUnlimited': isUnlimited,
      },
      'status': {
        'isFeatured': isFeatured,
        'isSelling': isSelling,
        'createdAt': DateTime.now().toIso8601String(),
      },
    };
  }
}

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Future<String> uploadProductImage(File imageFile, String userId, String productId) async {
    try {
      // Cấu trúc: Products / {user_id} / {product_id}.jpg
      String fileName = 'Products/$userId/$productId.jpg';
      Reference ref = _storage.ref().child(fileName);

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Lỗi upload ảnh: $e");
      rethrow;
    }
  }

  // Giữ nguyên hoặc tối ưu hàm addProduct
  Future<void> addProductWithId(String productId, ProductModel product) async {
    await _db.collection('products').doc(productId).set(product.toMap());
  }
  Future<void> addProduct(ProductModel product) async {
    try {
      // 1. Tạo một document reference mới (để lấy ID tự động)
      DocumentReference docRef = _db.collection('products').doc();

      // 2. Lưu dữ liệu
      await docRef.set(product.toMap());

      print("Lưu sản phẩm thành công với ID: ${docRef.id}");
    } catch (e) {
      print("Lỗi khi lưu sản phẩm: $e");
      rethrow;
    }
  }
}

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isUnlimited = false; // Khai báo biến trạng thái
  String _selectedMarket = "Chọn...";
  String _selectedProduct = "Chọn...";
  bool _isFeatured = false; // Sản phẩm nổi bật
  bool _isSelling = true;   // Đang bán
  // Danh sách chứa các bộ Controller cho mỗi dòng giá sỉ
  List<Map<String, TextEditingController>> _wholesaleList = [];
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _retailPriceController = TextEditingController();
  final TextEditingController _wholesalePriceController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _selectedUnit = "Cái"; // Mặc định đơn vị
  // Trong class _CreateProductScreenState
  File? _image;
  final ImagePicker _picker = ImagePicker();

// Hàm xử lý chọn ảnh
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }
  String formatNumber(String s) {
    if (s.isEmpty) return "";
    // Xóa tất cả ký tự không phải số trước khi định dạng
    final number = int.tryParse(s.replaceAll('.', ''));
    if (number == null) return "";
    return NumberFormat.decimalPattern('vi').format(number);
  }
  // Code ví dụ logic tính giá
  double calculateCurrentPrice(int quantity, Map pricing) {
    List tiers = pricing['wholesaleTiers'];
    // Sắp xếp giảm dần theo số lượng
    tiers.sort((a, b) => b['minQuantity'].compareTo(a['minQuantity']));

    for (var tier in tiers) {
      if (quantity >= tier['minQuantity']) {
        return tier['price'].toDouble();
      }
    }
    return pricing['retailPrice'].toDouble();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo sản phẩm', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
      ),
      // Phần nội dung nhập liệu có thể cuộn
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage, // Nhấn vào để chọn ảnh
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: _image != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                        : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 50, color: Colors.green),
                        Text("Thêm ảnh", style: TextStyle(color: Colors.green, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel("Mã sản phẩm"),
              _buildTextField("Mã sản phẩm"),
              _buildLabel("Tên sản phẩm *"),
              TextFormField(
                controller: _nameController, // Gán controller ở đây
                decoration: InputDecoration(
                  hintText: "Tên sản phẩm",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),

              Row(
                children: [
                  Expanded(child: _buildMarketPicker()), // Gọi hàm chợ
                  const SizedBox(width: 10),
                  Expanded(child: _buildProductPicker()), // Gọi hàm sản phẩm
                ],
              ),
              const SizedBox(height: 10),

              // Dòng Checkbox: Sản phẩm nổi bật & Đang bán
              Row(
                children: [
                  // Sản phẩm nổi bật
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("SẢN PHẨM NỔI BẬT", style: TextStyle(fontSize: 13, color: Colors.black)),
                      value: _isFeatured,
                      activeColor: const Color(0xFF2E7D32),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) => setState(() => _isFeatured = value!),
                    ),
                  ),
                  // Đang bán
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Đang bán", style: TextStyle(fontSize: 13, color: Colors.black)),
                      value: _isSelling,
                      activeColor: const Color(0xFF2E7D32),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) => setState(() => _isSelling = value!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Phần nhập Giảng Nguyễn (TextField giả lập theo ảnh)
              _buildTextField("Giảng Nguyễn"),

              const SizedBox(height: 20),

              // Phần Mô tả có Icon cây bút
              InkWell(
                onTap: () async {
                  // Chờ kết quả trả về từ MoTaScreen
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (context) => const MoTaScreen()),
                  );

                  // Nếu có dữ liệu trả về, cập nhật vào Controller và giao diện
                  if (result != null) {
                    setState(() {
                      _descriptionController.text = result;
                    });
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("Mô tả ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Icon(Icons.edit_note, color: Colors.grey[600], size: 22),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 1,
                      enabled: false, // Vô hiệu hóa để người dùng không gõ trực tiếp ở đây
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Nhập mô tả ...",
                        hintStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                            fontSize: 16
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.all(12),
                        // Dùng border mặc định để khi 'enabled: false' nó vẫn hiện khung xám
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Thêm khoảng trống cuối để nội dung không bị nút che mất khi cuộn xuống hết cỡ
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildTextFieldWithLabel("Dài *", "cm", isNumber: true, controller: _lengthController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextFieldWithLabel("Rộng *", "cm", isNumber: true, controller: _widthController)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildTextFieldWithLabel("Cao *", "cm", isNumber: true, controller: _heightController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextFieldWithLabel("Trọng lượng *", "gam", isNumber: true, controller: _weightController)),
                ],
              ),

              const SizedBox(height: 10),

              // 2. Số lượng & Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Số lượng"),
                        TextFormField(
                          controller: _quantityController,
                          enabled: !_isUnlimited,
                          // --- THÊM PHẦN NÀY ĐỂ CHỈ NHẬP SỐ ---
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          // ------------------------------------
                          decoration: InputDecoration(
                            hintText: "Số lượng",
                            fillColor: _isUnlimited ? Colors.grey[200] : Colors.transparent,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 48,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _isUnlimited,
                            activeColor: const Color(0xFF2E7D32),
                            onChanged: (value) {
                              setState(() {
                                _isUnlimited = value!;
                              });
                            },
                          ),
                          const Text("Không giới hạn"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 3. Đơn vị tính
              _buildLabel("Đơn vị tính *"),
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                hint: const Text("Đơn vị tính"),
                items: ['Cái', 'Hộp', 'Kg'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) {},
              ),

              const SizedBox(height: 10),

              // 4. Giá lẻ & Giá sỉ
              Row(
                children: [
                  Expanded(
                    child: _buildTextFieldWithLabel(
                      "Giá lẻ *",
                      "Giá lẻ",
                      suffix: "đ",
                      isNumber: true,
                      controller: _retailPriceController, // Gán controller vào đây
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextFieldWithLabel(
                      "Giá sỉ",
                      "Giá sỉ",
                      suffix: "đ",
                      isNumber: true,
                      controller: _wholesalePriceController, // Gán controller vào đây
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 5. Danh sách giá sỉ
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Danh sách giá sỉ", style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () {
                          // Khi nhấn thêm, tạo mới 2 controller cho 1 dòng
                          setState(() {
                            _wholesaleList.add({
                              "quantity": TextEditingController(),
                              "price": TextEditingController(),
                            });
                          });
                        },
                        icon: const Icon(Icons.add, color: Colors.green),
                        label: const Text("Thêm mức giá", style: TextStyle(color: Colors.green)),
                      ),
                    ],
                  ),

                  // Nếu danh sách trống thì hiện thông báo, ngược lại hiện danh sách các dòng
                  _wholesaleList.isEmpty
                      ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: const Text('Chưa có mức giá sỉ. Nhấn "Thêm mức giá" để thêm.'),
                  )
                      : Column(
                    children: List.generate(_wholesaleList.length, (index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Cột Số lượng từ
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Số lượng từ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 5),
                                  TextFormField(
                                    controller: _wholesaleList[index]["quantity"],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: InputDecoration(
                                      hintText: "Nhập số lượng...",
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Cột Giá bán sỉ
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Giá bán sỉ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 5),
                                  // Tìm đến ô nhập "Giá bán sỉ" trong danh sách sỉ và sửa như sau:
                                  TextFormField(
                                    controller: _wholesaleList[index]["price"],
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      if (value.isNotEmpty) {
                                        String formatted = formatNumber(value);
                                        _wholesaleList[index]["price"]!.value = TextEditingValue(
                                          text: formatted,
                                          selection: TextSelection.collapsed(offset: formatted.length),
                                        );
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Nhập giá",
                                      suffixText: "đ",
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Nút xóa
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  // Giải phóng bộ nhớ của controller trước khi xóa dòng
                                  _wholesaleList[index]["quantity"]!.dispose();
                                  _wholesaleList[index]["price"]!.dispose();
                                  _wholesaleList.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // Nút "Đăng" luôn hiển thị ở cuối màn hình
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea( // Đảm bảo không bị dính vào vạch home của iPhone/Android đời mới
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // 1. Hiển thị Loading (tùy chọn nhưng nên có)
                  User? currentUser = FirebaseAuth.instance.currentUser;

                  if (currentUser == null) {
                    // Thông báo nếu người dùng chưa đăng nhập
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vui lòng đăng nhập để đăng bài!")),
                    );
                    return;
                  }
                  if (_image == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Vui lòng chọn ảnh sản phẩm!")),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );


                  String uid = currentUser.uid;
// Lấy tên hiển thị (nếu có), nếu không có thì lấy phần đầu của email làm tên
                  String displayName = currentUser.displayName ?? currentUser.email?.split('@')[0] ?? "Người dùng";
                  try {
                    // 2. Thu thập và làm sạch dữ liệu số (loại bỏ dấu '.')
                    double parsePrice(String text) => double.tryParse(text.replaceAll('.', '')) ?? 0;
                    String productId = FirebaseFirestore.instance.collection('products').doc().id;
                    String imageUrl = await ProductService().uploadProductImage(_image!, uid, productId);

                    // Gom danh sách giá sỉ từ UI
                    List<Map<String, dynamic>> tiers = _wholesaleList.map((item) {
                      return {
                        'minQuantity': int.tryParse(item['quantity']!.text) ?? 0,
                        'price': parsePrice(item['price']!.text),
                      };
                    }).toList();

                    // 3. Tạo Model dựa trên các biến bạn đã khai báo trong State
                    final newProduct = ProductModel(
                      imageUrl: imageUrl, // Gán URL vừa lấy được ở đây
                      sku: "SP-${DateTime.now().millisecondsSinceEpoch}",
                      name: _nameController.text, // Thay bằng controller tên sp của bạn
                      description: _descriptionController.text,
                      sellerId: uid,
                      sellerName: displayName,
                      sellerType: "user",
                      marketId: _selectedMarket,
                      categoryId: _selectedProduct,
                      unit: _selectedUnit, // Đơn vị từ Dropdown
                      retailPrice: parsePrice(_retailPriceController.text),
                      wholesaleBasePrice: parsePrice(_wholesalePriceController.text),
                      wholesaleTiers: tiers,
                      dimensions: {
                        'length': parsePrice(_lengthController.text), // LẤY TỪ CONTROLLER
                        'width': parsePrice(_widthController.text),
                        'height': parsePrice(_heightController.text),
                        'weight': parsePrice(_weightController.text),
                      },
                      quantity: _isUnlimited ? 0 : _parseInt(_quantityController.text), // Logics số lượng
                      isUnlimited: _isUnlimited,
                      isFeatured: _isFeatured,
                      isSelling: _isSelling,
                    );
                    // 4. Gọi Service để đẩy lên Firestore
                    await ProductService().addProductWithId(productId, newProduct);

                    // Đóng Loading và quay lại hoặc reset form
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("🚀 Đăng sản phẩm thành công!")),
                    );
                    await FirebaseFirestore.instance.collection('products').doc(productId).set(newProduct.toMap());
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const AgriculturalMarketScreen()),
                          (route) => false, // Xóa sạch lịch sử các màn hình trước đó
                    );

                  } catch (e) {
                    Navigator.pop(context); // Đóng loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("❌ Lỗi: ${e.toString()}")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              child: const Text(
                  "Đăng",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Các hàm phụ hỗ trợ giao diện
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 15),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(String hint) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
  // Widget phụ trợ để tạo từng dòng lựa chọn
  Widget _buildMarketItem(
      BuildContext context,
      String title, {
        bool isSelected = false,
        bool isLast = false, // Thêm biến này
      }) {
    return InkWell(
      onTap: () {
        setState(() => _selectedMarket = title);
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.transparent,
          // Chỉ bo góc nếu là mục cuối cùng CỦA CẢ DANH SÁCH
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(15))
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.green[700],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
  // Hàm hiển thị ô chọn cho Chợ (Hiện Dialog chính giữa)
  Widget _buildMarketPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Danh mục chợ"),
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => Center( // Đảm bảo vào chính giữa
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40), // Cách 2 bên lề
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Material( // Thêm Material để tránh lỗi text bị gạch chân
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tiêu đề
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "Danh mục chợ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black
                            ),
                          ),
                        ),
                        const Divider(height: 1, thickness: 0.5),

                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMarketItem(context, "Chợ Vật Tư",
                                isSelected: _selectedMarket == "Chợ Vật Tư"),
                            const Divider(height: 1), // Đường kẻ giữa các mục
                            _buildMarketItem(context, "Chợ Nông Nghiệp Đô Thị",
                                isSelected: _selectedMarket == "Chợ Nông Nghiệp Đô Thị"),
                            const Divider(height: 1),
                            _buildMarketItem(context, "Chợ Nông Sản",
                                isSelected: _selectedMarket == "Chợ Nông Sản",
                                isLast: true), // Mục này sẽ giữ nhiệm vụ bo góc dưới
                          ],
                        ),
                        const Divider(height: 1, thickness: 0.5),

                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          child: _buildBoxDesign(_selectedMarket),
        ),
      ],
    );
  }

  Widget _buildTextFieldWithLabel(String label, String hint, {String? suffix, bool isNumber = false, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          onChanged: (value) {
            if (isNumber && controller != null && value.isNotEmpty) {
              String formatted = formatNumber(value);
              controller.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    );
  }

  // Hàm hiển thị ô chọn cho Sản phẩm (Mở màn hình danh sách tại chỗ)
  Widget _buildProductPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Danh mục sản phẩm"),
        InkWell(
          onTap: () async {
            // CHỖ THAY ĐỔI: Gọi đến file/class mới của bạn
            final result = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductCategoryScreen(), // Gọi Class từ file mới
              ),
            );

            // Nhận kết quả trả về và cập nhật giao diện
            if (result != null) {
              setState(() => _selectedProduct = result);
            }
          },
          child: _buildBoxDesign(_selectedProduct),
        ),
      ],
    );
  }

  // Hàm phụ vẽ cái khung ô chọn cho đẹp
  Widget _buildBoxDesign(String value) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ],
      ),
    );
  }
  // Tìm đến cuối class _CreateProductScreenState, trước dấu đóng } cuối cùng
  double _parsePrice(String text) => double.tryParse(text.replaceAll('.', '')) ?? 0;
  int _parseInt(String text) => int.tryParse(text.replaceAll('.', '')) ?? 0;
}