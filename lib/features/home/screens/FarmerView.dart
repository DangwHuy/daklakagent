import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;

// Import màn hình Chat (Hãy sửa lại đường dẫn nếu thư mục của bạn khác)
import 'package:daklakagent/features/home/screens/chat_screen.dart';

class FindExpertScreen extends StatefulWidget {
  const FindExpertScreen({super.key});

  @override
  State<FindExpertScreen> createState() => _FindExpertScreenState();
}

class _FindExpertScreenState extends State<FindExpertScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  bool _isBooking = false;

  // --- FEATURE: Định vị tìm chuyên gia gần nhất ---
  double? _currentLat;
  double? _currentLng;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
        if (mounted) {
          setState(() {
            _currentLat = position.latitude;
            _currentLng = position.longitude;
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi định vị nông dân: $e");
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // Trả về số km
  }

  final List<String> _categories = [
    'Tất cả',
    'Giám sát hệ thống',
    'Lúa, cây có múi, cây ăn trái',
    'Cà phê, hồ tiêu, sầu riêng, Cây công nghiệp',
    'Sầu riêng',
    'Hỗ trợ hệ thống',
    'Kỹ thuật hệ thống'
  ];
  String _selectedCategory = "Tất cả";

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        centerTitle: false,
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/ai_logo.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Đặt Lịch Chuyên Gia",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FarmerChatListScreen()),
              );
            },
            icon: Icon(Icons.chat_bubble_outline, color: Colors.grey[700]),
            tooltip: "Tin nhắn",
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FarmerAppointmentsScreen()),
              );
            },
            icon: Icon(Icons.calendar_month, color: Colors.grey[700]),
            tooltip: "Lịch đã đặt",
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchText = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Tìm theo tên hoặc chuyên môn...",
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('farmerId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, appointmentSnapshot) {
                  Set<String> bookedSlots = {};

                  if (appointmentSnapshot.hasData) {
                    for (var doc in appointmentSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String expertId = data['expertId'];
                      final Timestamp time = data['time'];
                      bookedSlots.add("${expertId}_${time.seconds}");
                    }
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'expert')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.green));
                      }

                      final now = DateTime.now();

                      var experts = snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final expertInfo = data['expertInfo'] as Map<String, dynamic>? ?? {};

                        List<dynamic> rawSlots = expertInfo['availableSlots'] ?? [];

                        List<DateTime> validSlots = rawSlots
                            .map((e) => (e as Timestamp).toDate())
                            .where((date) {
                          final String key = "${doc.id}_${(date.millisecondsSinceEpoch / 1000).floor()}";
                          bool isBooked = bookedSlots.contains(key);
                          return date.isAfter(now) && !isBooked;
                        }).toList();

                        validSlots.sort();

                        return {
                          'id': doc.id,
                          'name': data['displayName'] ?? "Chuyên gia",
                          'photoUrl': data['photoUrl'] ?? "",
                          'specialty': expertInfo['specialty'] ?? "Nông nghiệp",
                          'bio': expertInfo['bio'] ?? "",
                          'isOnline': expertInfo['isOnline'] ?? false,
                          'rating': expertInfo['rating']?.toDouble() ?? 5.0,
                          'bookingCount': expertInfo['bookingCount'] ?? 0,
                          'latitude': expertInfo['latitude'],
                          'longitude': expertInfo['longitude'],
                          'validSlots': validSlots,
                        };
                      }).toList();

                      // --- LOGIC TÍNH KHOẢNG CÁCH ---
                      if (_currentLat != null && _currentLng != null) {
                        for (var e in experts) {
                          if (e['latitude'] != null && e['longitude'] != null) {
                            e['distance'] = _calculateDistance(
                              _currentLat!, _currentLng!, 
                              e['latitude'], e['longitude']
                            );
                          } else {
                            e['distance'] = 9999.0; // Nếu chuyên gia không có tọa độ, đẩy về sau
                          }
                        }
                      }

                      experts = experts.where((e) {
                        final bool isOnline = e['isOnline'] as bool;
                        final List slots = e['validSlots'] as List;
                        final String name = (e['name'] as String).toLowerCase();
                        final String specialty = (e['specialty'] as String).toLowerCase();

                        bool passStatus = isOnline && slots.isNotEmpty;
                        bool passSearch = _searchText.isEmpty || name.contains(_searchText) || specialty.contains(_searchText);
                        bool passCategory = _selectedCategory == 'Tất cả' || specialty.contains(_selectedCategory.toLowerCase());

                        return passStatus && passSearch && passCategory;
                      }).toList();

                      experts.sort((a, b) {
                        // 1. Ưu tiên theo khoảng cách nếu có tọa độ
                        if (_currentLat != null && _currentLng != null) {
                          double distA = a['distance'] ?? 9999.0;
                          double distB = b['distance'] ?? 9999.0;
                          if (distA != distB) return distA.compareTo(distB);
                        }

                        // 2. Nếu khoảng cách bằng nhau hoặc không có tọa độ, sắp xếp theo lịch gần nhất
                        DateTime firstSlotA = (a['validSlots'] as List<DateTime>).first;
                        DateTime firstSlotB = (b['validSlots'] as List<DateTime>).first;
                        return firstSlotA.compareTo(firstSlotB);
                      });

                      if (experts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 10),
                              Text(
                                bookedSlots.isNotEmpty
                                    ? "Bạn đã đặt hết lịch rảnh hiện có!"
                                    : "Hiện không có chuyên gia nào rảnh.",
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: experts.length,
                        itemBuilder: (context, index) {
                          final expert = experts[index];
                          return _buildExpertCard(context, expert);
                        },
                      );
                    },
                  );
                }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
              selectedColor: Colors.green[100],
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.green[800] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.green : Colors.grey[300]!),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpertCard(BuildContext context, Map<String, dynamic> expert) {
    final List<DateTime> slots = expert['validSlots'] as List<DateTime>;
    final displaySlots = slots.take(4).toList();
    final int remainingSlots = slots.length - 4;
    final String expertId = expert['id'];

    return Card(
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.blue[50],
                      backgroundImage: expert['photoUrl'] != "" ? NetworkImage(expert['photoUrl']) : null,
                      child: expert['photoUrl'] == ""
                          ? Text((expert['name'] as String)[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expert['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text("${expert['rating']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 12),
                          const Icon(Icons.people_alt_outlined, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text("${expert['bookingCount']} lượt đặt", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          expert['specialty'],
                          style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // --- HIỂN THỊ KHOẢNG CÁCH (NẾU CÓ) ---
                      if (expert['distance'] != null && expert['distance'] < 9999.0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red[700], size: 14),
                              const SizedBox(width: 4),
                              Text(
                                "Cách bạn ${expert['distance'].toStringAsFixed(1)} km",
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        expert['bio'].toString().isNotEmpty ? expert['bio'] : "Sẵn sàng tư vấn hỗ trợ bà con.",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final currentUser = FirebaseAuth.instance.currentUser;
                                if (currentUser == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập!")));
                                  return;
                                }
                                final String chatRoomId = "${currentUser.uid}_$expertId";

                                final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatRoomId);
                                final docSnap = await chatRef.get();
                                if (!docSnap.exists) {
                                  await chatRef.set({
                                    'users': [currentUser.uid, expertId],
                                    'farmerId': currentUser.uid,
                                    'expertId': expertId,
                                    'lastMessage': '',
                                    'lastMessageTime': FieldValue.serverTimestamp(),
                                    'unreadCountExpert': 0,
                                    'unreadCountFarmer': 0,
                                  });
                                }

                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      chatRoomId: chatRoomId,
                                      peerId: expertId,
                                      peerName: expert['name'],
                                      peerAvatar: expert['photoUrl'],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline, size: 16),
                              label: const Text("Đặt câu hỏi", style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green[700],
                                  side: BorderSide(color: Colors.green[700]!),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 8)
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showContactBottomSheet(context, expert),
                              icon: const Icon(Icons.phone_in_talk, size: 16),
                              label: const Text("Liên hệ", style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 8)
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_filled, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text("Lịch rảnh sắp tới:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...displaySlots.map((time) => _buildTimeChip(context, time, expert['name'], expertId)),
                    if (remainingSlots > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("+$remainingSlots", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimeChip(BuildContext context, DateTime time, String expertName, String expertId) {
    final timeStr = DateFormat('HH:mm').format(time);
    String dateStr;
    final now = DateTime.now();
    if (time.day == now.day && time.month == now.month && time.year == now.year) {
      dateStr = "Hôm nay";
    } else {
      dateStr = DateFormat('dd/MM').format(time);
    }

    return InkWell(
      onTap: () => _showBookingDialog(context, expertName, time, expertId),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
            Text(dateStr, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, String expertName, DateTime time, String expertId) {
    final TextEditingController noteController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController addressController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text("Xác nhận đặt lịch"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Chuyên gia: $expertName", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Thời gian: ${DateFormat('HH:mm - dd/MM/yyyy').format(time)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const Divider(height: 20),
                    const Text("Thông tin liên hệ của bạn:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Số điện thoại (*)",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: "Địa chỉ / Khu vực",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          try {
                            Position position = await Geolocator.getCurrentPosition(
                              desiredAccuracy: LocationAccuracy.high
                            );
                            setDialogState(() {
                              addressController.text = 
                                "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Đã lấy tọa độ GPS của bạn!"))
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Không thể lấy vị trí: $e"))
                            );
                          }
                        },
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text("Lấy vị trí hiện tại", style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text("Mô tả vấn đề:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: "VD: Cây bị vàng lá...",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    if (_isBooking)
                      const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: CircularProgressIndicator())),
                  ],
                ),
              ),
              actions: _isBooking ? [] : [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Huỷ")),
                ElevatedButton(
                  onPressed: () async {
                    if (phoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập số điện thoại!"), backgroundColor: Colors.red));
                      return;
                    }
                    setDialogState(() => _isBooking = true);
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) throw Exception("Bạn chưa đăng nhập!");

                      final appRef = await FirebaseFirestore.instance.collection('appointments').add({
                        'farmerId': user.uid,
                        'farmerName': user.displayName ?? "Nông dân",
                        'expertId': expertId,
                        'expertName': expertName,
                        'time': Timestamp.fromDate(time),
                        'status': 'pending',
                        'note': noteController.text.trim(),
                        'farmerPhone': phoneController.text.trim(),
                        'farmerAddress': addressController.text.trim(),
                        'createdAt': FieldValue.serverTimestamp(),
                        'isRated': false,
                      });

                      // TẠO THÔNG BÁO GỬI ĐẾN CHUYÊN GIA
                      await FirebaseFirestore.instance.collection('notifications').add({
                        'receiverId': expertId,
                        'title': 'Lịch hẹn mới',
                        'body': '${user.displayName ?? "Một nông dân"} vừa đặt lịch hẹn với bạn.',
                        'appointmentId': appRef.id,
                        'createdAt': FieldValue.serverTimestamp(),
                        'isRead': false,
                      });

                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi yêu cầu thành công!"), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      setDialogState(() => _isBooking = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text("Gửi Yêu Cầu"),
                ),
              ],
            );
          }
      ),
    );
  }

  void _showContactBottomSheet(BuildContext context, Map<String, dynamic> expert) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(expert['id']).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.green)));
            }
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final phone = data?['phoneNumber'] ?? data?['phone'] ?? "Chưa cập nhật SĐT";
            final email = data?['email'] ?? "Chưa cập nhật Email";

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Text("Liên hệ: ${expert['name']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Bạn có thể liên hệ trực tiếp với chuyên gia qua các kênh sau:", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.phone, color: Colors.white)),
                      title: const Text("Số điện thoại"),
                      subtitle: Text(phone, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đang gọi $phone...")));
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.email, color: Colors.white)),
                      title: const Text("Email hỗ trợ"),
                      subtitle: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class FarmerAppointmentsScreen extends StatefulWidget {
  const FarmerAppointmentsScreen({super.key});

  @override
  State<FarmerAppointmentsScreen> createState() => _FarmerAppointmentsScreenState();
}

class _FarmerAppointmentsScreenState extends State<FarmerAppointmentsScreen> {

  // ─── UPLOAD NHIỀU ẢNH LÊN FIREBASE STORAGE ─────────────────────────────────
  Future<List<String>> _uploadReviewImages(List<File> images, String appointmentId) async {
    List<String> urls = [];
    for (int i = 0; i < images.length; i++) {
      final ref = FirebaseStorage.instance.ref().child(
        'reviews/$appointmentId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
      );
      await ref.putFile(images[i]);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _submitRatingHandler(String expertId, int stars, String appointmentId, {String comment = '', List<File> images = const []}) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final expertRef = firestore.collection('users').doc(expertId);

      final docSnap = await expertRef.get();
      final data = docSnap.data() as Map<String, dynamic>? ?? {};
      final expertInfo = data['expertInfo'] as Map<String, dynamic>? ?? {};

      double currentRating = expertInfo['rating']?.toDouble() ?? 5.0;
      int currentCount = expertInfo['ratingCount'] ?? 0;

      final int newCount = currentCount + 1;
      final double newAvg = ((currentRating * currentCount) + stars) / newCount;

      // Upload ảnh nếu có
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await _uploadReviewImages(images, appointmentId);
      }

      final batch = firestore.batch();

      batch.update(expertRef, {
        'expertInfo.rating': double.parse(newAvg.toStringAsFixed(1)),
        'expertInfo.ratingCount': newCount,
      });

      final appRef = firestore.collection('appointments').doc(appointmentId);
      batch.update(appRef, {
        'isRated': true,
        'ratingValue': stars,
        'reviewComment': comment,
        'reviewImages': imageUrls,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đánh giá thành công! Cảm ơn bạn."), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi đánh giá: $e")));
    }
  }

  void _showRatingDialog(BuildContext context, String expertId, String expertName, String appointmentId) {
    int selectedStars = 5;
    final commentController = TextEditingController();
    List<File> pickedImages = [];
    bool isSubmitting = false;
    final ImagePicker picker = ImagePicker();

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rate_review_rounded, color: Colors.amber, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text("Đánh giá tư vấn", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Chất lượng tư vấn của\n$expertName?", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 16),

                        // ★ Chọn sao
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () => setDialogState(() => selectedStars = index + 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  index < selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: Colors.amber,
                                  size: 40,
                                ),
                              ),
                            );
                          }),
                        ),
                        Text("$selectedStars Sao", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16)),

                        const SizedBox(height: 20),

                        // ✏️ Bình luận
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Bình luận:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: commentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Chia sẻ trải nghiệm của bạn...",
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 📸 Ảnh minh chứng
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Ảnh minh chứng (tuỳ chọn):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                        ),
                        const SizedBox(height: 8),

                        // Hiển thị ảnh đã chọn
                        if (pickedImages.isNotEmpty)
                          SizedBox(
                            height: 80,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: pickedImages.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.file(pickedImages[i], width: 80, height: 80, fit: BoxFit.cover),
                                        ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () => setDialogState(() => pickedImages.removeAt(i)),
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024, imageQuality: 80);
                                  if (picked != null) {
                                    setDialogState(() => pickedImages.add(File(picked.path)));
                                  }
                                },
                                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                                label: const Text("Chụp", style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green[700],
                                  side: BorderSide(color: Colors.green[300]!),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final results = await picker.pickMultiImage(maxWidth: 1024, imageQuality: 80);
                                  if (results.isNotEmpty) {
                                    setDialogState(() {
                                      pickedImages.addAll(results.map((f) => File(f.path)));
                                    });
                                  }
                                },
                                icon: const Icon(Icons.photo_library_rounded, size: 18),
                                label: const Text("Thư viện", style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue[700],
                                  side: BorderSide(color: Colors.blue[300]!),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (isSubmitting)
                          const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: Colors.green),
                                SizedBox(height: 8),
                                Text("Đang gửi đánh giá...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: isSubmitting ? [] : [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text("Gửi đánh giá", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        setDialogState(() => isSubmitting = true);
                        await _submitRatingHandler(
                          expertId, selectedStars, appointmentId,
                          comment: commentController.text.trim(),
                          images: pickedImages,
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      },
                    ),
                  ],
                );
              }
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Lịch Đã Đặt"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('farmerId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Bạn chưa đặt lịch hẹn nào.", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String appointmentId = docs[index].id;
              data['id'] = appointmentId;

              final DateTime time = (data['time'] as Timestamp).toDate();
              final String expertName = data['expertName'] ?? "Chuyên gia";
              final String status = data['status'] ?? "pending";

              // ĐÃ FIX LỖI "LỆCH PHA": Thêm xử lý cho trường hợp 'completed'
              Color statusColor = Colors.orange;
              String statusText = "Chờ xác nhận";
              IconData statusIcon = Icons.access_time;

              if (status == 'confirmed' || status == 'accepted') {
                statusColor = Colors.green;
                statusText = "Đã xác nhận";
                statusIcon = Icons.check_circle;
              } else if (status == 'completed') {
                statusColor = Colors.blue[600]!;
                statusText = "Đã hoàn thành";
                statusIcon = Icons.verified;
              } else if (status == 'cancelled') {
                statusColor = Colors.red;
                statusText = "Đã huỷ";
                statusIcon = Icons.cancel;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () => _showAppointmentDetails(context, data),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  title: Text(expertName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Thời gian: ${DateFormat('HH:mm - dd/MM/yyyy').format(time)}"),
                      if (status == 'cancelled')
                        Text("Đã bị hủy", style: TextStyle(color: Colors.red[300], fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAppointmentDetails(BuildContext context, Map<String, dynamic> data) {
    final String status = data['status'] ?? 'pending';
    final String expertName = data['expertName'] ?? 'Chuyên gia';
    final String expertId = data['expertId'];
    final String appointmentId = data['id'];
    final DateTime time = (data['time'] as Timestamp).toDate();
    final String? cancelReason = data['cancelReason'];
    final bool isRated = data['isRated'] ?? false;
    final int? ratingValue = data['ratingValue'];
    final String reviewComment = data['reviewComment'] ?? '';
    final List<dynamic> reviewImages = data['reviewImages'] ?? [];
    final List<dynamic> confirmImages = data['confirmImages'] ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 10),
              const Text("Chi tiết lịch hẹn"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow("Chuyên gia:", expertName),
                const SizedBox(height: 8),
                _buildDetailRow("Thời gian:", DateFormat('HH:mm - dd/MM/yyyy').format(time)),
                const SizedBox(height: 8),
                _buildDetailRow("Ghi chú của bạn:", data['note'] ?? "Không có"),
                const Divider(height: 20),

                if (status == 'cancelled') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Lịch hẹn đã bị hủy!",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Lý do: ${cancelReason ?? 'Không có lý do cụ thể'}",
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  )
                ]
                else if (status == 'confirmed' || status == 'accepted' || status == 'completed') ...[
                  const Text("Thông tin liên hệ chuyên gia:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 10),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(expertId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text("Không tải được thông tin chuyên gia.");
                      }

                      final expertData = snapshot.data!.data() as Map<String, dynamic>;
                      final phone = expertData['phoneNumber'] ?? expertData['phone'] ?? "Chưa cập nhật";
                      final email = expertData['email'] ?? "Chưa cập nhật";
                      final address = expertData['address'] ?? expertData['location'] ?? "Chưa cập nhật";

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildContactRow(Icons.phone, phone),
                          const SizedBox(height: 8),
                          _buildContactRow(Icons.email, email),
                          const SizedBox(height: 8),
                          _buildContactRow(Icons.location_on, address),
                          const SizedBox(height: 12),

                          // ==========================================
                          // NÂNG CẤP: LOGIC ĐÁNH GIÁ & ẢNH XÁC NHẬN
                          // ==========================================
                          if (status == 'completed') ...[
                            // 1. Chỉ hiện ảnh xác nhận khi đã hoàn thành
                            if (confirmImages.isNotEmpty) ...[
                              const Divider(),
                              Row(
                                children: [
                                  Icon(Icons.verified_rounded, size: 16, color: Colors.blue[700]),
                                  const SizedBox(width: 6),
                                  Text("Ảnh xác nhận từ chuyên gia (${confirmImages.length})", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue[700])),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: confirmImages.map<Widget>((url) {
                                      return GestureDetector(
                                        onTap: () => _showFullImageDialog(context, url),
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.network(
                                              url,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 100, height: 100,
                                                color: Colors.grey[200],
                                                child: Icon(Icons.broken_image, color: Colors.grey[400]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],

                            const Divider(),

                            // 2. Chỉ cho phép đánh giá khi ĐÃ HOÀN THÀNH
                            if (isRated) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text("Đánh giá của bạn: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ...List.generate(5, (index) => Icon(
                                          index < (ratingValue ?? 5) ? Icons.star_rounded : Icons.star_outline_rounded,
                                          color: Colors.amber,
                                          size: 18,
                                        )),
                                      ],
                                    ),
                                    if (reviewComment.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text("\"$reviewComment\"", style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black87, height: 1.4)),
                                    ],
                                    if (reviewImages.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 70,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: reviewImages.map<Widget>((url) {
                                              return GestureDetector(
                                                onTap: () => _showFullImageDialog(context, url),
                                                child: Container(
                                                  margin: const EdgeInsets.only(right: 6),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.network(url, width: 70, height: 70, fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey[200], child: Icon(Icons.broken_image, size: 20, color: Colors.grey[400])),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ] else
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showRatingDialog(context, expertId, expertName, appointmentId);
                                  },
                                  icon: const Icon(Icons.star_outline, color: Colors.amber),
                                  label: const Text("Đánh giá chuyên gia này", style: TextStyle(color: Colors.black87)),
                                  style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.amber),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                  ),
                                ),
                              )
                          ] else ...[
                            // 3. Trạng thái Đã xác nhận / Chấp nhận: Báo chờ hoàn thành
                            const Divider(),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Bạn có thể đánh giá sau khi ca tư vấn được chuyên gia xác nhận hoàn thành.",
                                      style: TextStyle(color: Colors.blue[800], fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ]
                          // ==========================================
                        ],
                      );
                    },
                  )
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_empty, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(child: Text("Đang chờ chuyên gia xác nhận. Vui lòng quay lại sau.")),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"),
            ),
          ],
        );
      },
    );
  }

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 200, color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.broken_image, size: 48)),
                ),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class FarmerChatListScreen extends StatelessWidget {
  const FarmerChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        centerTitle: false,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
            ),
          ),
        ),
        title: const Text(
          "Tin nhắn của tôi",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Lọc bản ghi bị ẩn
          var allDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final List<dynamic> hiddenBy = data['hiddenBy'] ?? [];
            return !hiddenBy.contains(currentUserId);
          }).toList();

          if (allDocs.isEmpty) return _buildEmptyState();

          // Sắp xếp: Ghim lên đầu, sau đó theo thời gian
          allDocs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;

            final List<dynamic> pinnedByA = dataA['pinnedBy'] ?? [];
            final List<dynamic> pinnedByB = dataB['pinnedBy'] ?? [];
            final bool isPinnedA = pinnedByA.contains(currentUserId);
            final bool isPinnedB = pinnedByB.contains(currentUserId);

            if (isPinnedA != isPinnedB) return isPinnedA ? -1 : 1;

            final Timestamp? timeA = dataA['lastMessageTime'];
            final Timestamp? timeB = dataB['lastMessageTime'];

            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;

            return timeB.compareTo(timeA);
          });

          return ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: allDocs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE), indent: 84),
            itemBuilder: (context, index) {
              final doc = allDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final roomId = doc.id;

              String peerId = "";
              List<dynamic> users = data['users'] ?? [];
              if (users.isNotEmpty) {
                peerId = users.firstWhere((id) => id != currentUserId, orElse: () => "");
              }

              if (peerId.isEmpty && roomId.contains("_")) {
                final parts = roomId.split("_");
                peerId = parts.firstWhere((id) => id != currentUserId, orElse: () => "");
              }

              if (peerId.isEmpty) return const SizedBox.shrink();

              final List<dynamic> pinnedBy = data['pinnedBy'] ?? [];
              final bool isPinned = pinnedBy.contains(currentUserId);

              return Dismissible(
                key: Key(roomId),
                background: Container(
                  color: Colors.blue[400],
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: Colors.white),
                      Text(isPinned ? "Bỏ ghim" : "Ghim", style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.red[400],
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, color: Colors.white),
                      Text("Xóa", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    if (isPinned) {
                      await doc.reference.update({'pinnedBy': FieldValue.arrayRemove([currentUserId])});
                    } else {
                      await doc.reference.update({'pinnedBy': FieldValue.arrayUnion([currentUserId])});
                    }
                    return false;
                  } else {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Xóa cuộc trò chuyện?"),
                        content: const Text("Nội dung sẽ bị ẩn khỏi danh sách của bạn."),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await doc.reference.update({'hiddenBy': FieldValue.arrayUnion([currentUserId])});
                      return true;
                    }
                    return false;
                  }
                },
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(peerId).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) return const SizedBox.shrink();
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData == null) return const SizedBox.shrink();

                    final peerName = userData['displayName'] ?? "Chuyên gia";
                    final peerAvatar = userData['photoUrl'] ?? "";

                    DateTime? time;
                    if (data['lastMessageTime'] != null) {
                      time = (data['lastMessageTime'] as Timestamp).toDate();
                    }

                    return Container(
                      color: isPinned ? Colors.blue.withOpacity(0.02) : Colors.transparent,
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatRoomId: roomId,
                                peerId: peerId,
                                peerName: peerName,
                                peerAvatar: peerAvatar,
                              ),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.green.withOpacity(0.1), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white,
                                backgroundImage: peerAvatar.isNotEmpty ? NetworkImage(peerAvatar) : null,
                                child: peerAvatar.isEmpty
                                    ? Text(peerName[0], style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 20))
                                    : null,
                              ),
                            ),
                            if (isPinned)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                  child: const Icon(Icons.push_pin, color: Colors.white, size: 10),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(peerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                            if (time != null)
                              Text(_formatTime(time), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            data['lastMessage'] ?? "Nhấn vào để xem tin nhắn...",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays == 0) return DateFormat('HH:mm').format(time);
    if (difference.inDays < 7) return DateFormat('E').format(time);
    return DateFormat('dd/MM').format(time);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text("Chưa có cuộc trò chuyện nào.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Hãy đặt câu hỏi cho chuyên gia để bắt đầu.", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }
}