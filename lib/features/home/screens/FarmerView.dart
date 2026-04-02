import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
        title: const Text("Tìm Chuyên Gia Tư Vấn", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // NEW: THÊM NÚT XEM TIN NHẮN CHO NÔNG DÂN
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FarmerChatListScreen()),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: "Tin nhắn",
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FarmerAppointmentsScreen()),
              );
            },
            icon: const Icon(Icons.calendar_month),
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
                          'validSlots': validSlots,
                        };
                      }).toList();

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
                              onPressed: () {
                                final currentUser = FirebaseAuth.instance.currentUser;
                                if (currentUser == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng nhập!")));
                                  return;
                                }
                                final String chatRoomId = "${currentUser.uid}_$expertId";
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

                      await FirebaseFirestore.instance.collection('appointments').add({
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
                        'isRated': false, // NEW: Thêm cờ đánh giá
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
  // NEW: Hàm tính toán và submit rating
  Future<void> _submitRatingHandler(String expertId, int stars, String appointmentId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final expertRef = firestore.collection('users').doc(expertId);

      // 1. Lấy thông tin hiện tại của chuyên gia
      final docSnap = await expertRef.get();
      final data = docSnap.data() as Map<String, dynamic>? ?? {};
      final expertInfo = data['expertInfo'] as Map<String, dynamic>? ?? {};

      double currentRating = expertInfo['rating']?.toDouble() ?? 5.0;
      int currentCount = expertInfo['ratingCount'] ?? 0;

      // 2. Tính trung bình cộng mới (Rolling average)
      final int newCount = currentCount + 1;
      final double newAvg = ((currentRating * currentCount) + stars) / newCount;

      // 3. Dùng batch để cập nhật cả 2 nơi cùng lúc (atomic)
      final batch = firestore.batch();

      // Cập nhật rating vào hồ sơ chuyên gia
      batch.update(expertRef, {
        'expertInfo.rating': double.parse(newAvg.toStringAsFixed(1)),
        'expertInfo.ratingCount': newCount,
      });

      // Cập nhật cờ vào lịch hẹn để không đánh giá lại
      final appRef = firestore.collection('appointments').doc(appointmentId);
      batch.update(appRef, {
        'isRated': true,
        'ratingValue': stars,
      });

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đánh giá thành công! Cảm ơn bạn."), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi đánh giá: $e")));
    }
  }

  // NEW: Hàm hiển thị Popup Đánh giá sao
  void _showRatingDialog(BuildContext context, String expertId, String expertName, String appointmentId) {
    int selectedStars = 5;

    showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  title: const Text("Đánh giá tư vấn", textAlign: TextAlign.center),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Chất lượng tư vấn của chuyên gia\n$expertName?", textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            iconSize: 36,
                            icon: Icon(
                              index < selectedStars ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                selectedStars = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                      Text("$selectedStars Sao", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(dialogContext); // Đóng popup
                        _submitRatingHandler(expertId, selectedStars, appointmentId);
                      },
                      child: const Text("Gửi đánh giá"),
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

              Color statusColor = Colors.orange;
              String statusText = "Chờ xác nhận";

              // UPDATED: 'accepted' cũng được coi như 'confirmed'
              if (status == 'confirmed' || status == 'accepted') {
                statusColor = Colors.green;
                statusText = "Đã xác nhận";
              } else if (status == 'cancelled') {
                statusColor = Colors.red;
                statusText = "Đã huỷ";
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () => _showAppointmentDetails(context, data),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(
                        (status == 'confirmed' || status == 'accepted') ? Icons.check_circle : (status == 'cancelled' ? Icons.cancel : Icons.access_time),
                        color: statusColor
                    ),
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
                ] else if (status == 'confirmed' || status == 'accepted') ...[
                  // KHI LỊCH ĐÃ ĐƯỢC XÁC NHẬN / ACCEPTED
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

                          // NEW: PHẦN HIỂN THỊ RATING
                          const Divider(),
                          if (isRated)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text("Bạn đã đánh giá: ", style: TextStyle(fontWeight: FontWeight.w500)),
                                    Row(
                                      children: List.generate(5, (index) => Icon(
                                        index < (ratingValue ?? 5) ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 18,
                                      )),
                                    )
                                  ],
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context); // Tắt popup chi tiết
                                  _showRatingDialog(context, expertId, expertName, appointmentId); // Mở popup đánh giá
                                },
                                icon: const Icon(Icons.star_outline, color: Colors.amber),
                                label: const Text("Đánh giá chuyên gia này", style: TextStyle(color: Colors.black87)),
                                style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.amber),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                ),
                              ),
                            )
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

// NEW: MÀN HÌNH DANH SÁCH TIN NHẮN CỦA NÔNG DÂN
class FarmerChatListScreen extends StatelessWidget {
  const FarmerChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Tin nhắn của tôi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('users', arrayContains: currentUserId) // Dùng Firebase lọc cho chuẩn và nhanh
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

          var docs = snapshot.data!.docs.toList();

          // Sắp xếp tin nhắn mới nhất lên đầu ngay tại Dart
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final Timestamp? timeA = dataA['lastMessageTime'];
            final Timestamp? timeB = dataB['lastMessageTime'];

            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;

            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final roomId = docs[index].id;

              String peerId = "";
              List<dynamic> users = data.containsKey('users') ? data['users'] : [];

              if (users.isNotEmpty) {
                peerId = users.firstWhere((id) => id != currentUserId, orElse: () => "");
              }

              // Fallback cho phòng chat cũ nếu lỗi
              if (peerId.isEmpty && roomId.contains("_")) {
                final parts = roomId.split("_");
                peerId = parts.firstWhere((id) => id != currentUserId, orElse: () => "");
              }

              if (peerId.isEmpty) return const SizedBox.shrink();

              return FutureBuilder<DocumentSnapshot>(
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

                  return Card(
                    elevation: 2,
                    shadowColor: Colors.black12,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.green[50],
                        backgroundImage: peerAvatar.isNotEmpty ? NetworkImage(peerAvatar) : null,
                        child: peerAvatar.isEmpty
                            ? Text(peerName[0], style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 20))
                            : null,
                      ),
                      title: Text(peerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          data['lastMessage'] ?? "Nhấn vào để xem tin nhắn...",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      trailing: time != null
                          ? Text(DateFormat('HH:mm').format(time), style: TextStyle(color: Colors.grey[500], fontSize: 12))
                          : null,
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
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
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